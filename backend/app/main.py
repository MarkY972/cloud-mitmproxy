from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
import boto3
import os
import time

from . import models, database

app = FastAPI()

@app.get("/")
def read_root():
    return {"status": "ok"}

ecs_client = boto3.client("ecs", region_name=os.environ.get("AWS_REGION", "us-east-1"))
ec2_client = boto3.client("ec2", region_name=os.environ.get("AWS_REGION", "us-east-1"))

CLUSTER_NAME = os.environ["CLUSTER_NAME"]
TASK_DEFINITION_ARN = os.environ["TASK_DEFINITION_ARN"]

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/api/instances")
def create_instance(db: Session = Depends(get_db)):
    response = ecs_client.run_task(
        cluster=CLUSTER_NAME,
        task_definition=TASK_DEFINITION_ARN,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": [os.environ["SUBNET_A"], os.environ["SUBNET_B"]],
                "securityGroups": [os.environ["MITMPROXY_SG_ID"]],
                "assignPublicIp": "ENABLED"
            }
        }
    )
    task_arn = response["tasks"][0]["taskArn"]

    # Wait for the task to be running and get the public IP
    waiter = ecs_client.get_waiter('tasks_running')
    waiter.wait(cluster=CLUSTER_NAME, tasks=[task_arn])

    task_details = ecs_client.describe_tasks(cluster=CLUSTER_NAME, tasks=[task_arn])
    eni_id = task_details['tasks'][0]['attachments'][0]['details'][1]['value']
    eni = ec2_client.describe_network_interfaces(NetworkInterfaceIds=[eni_id])
    public_ip = eni['NetworkInterfaces'][0]['Association']['PublicIp']

    new_instance = models.Instance(task_arn=task_arn, status="RUNNING", public_ip=public_ip)
    db.add(new_instance)
    db.commit()
    db.refresh(new_instance)
    return new_instance

@app.get("/api/instances")
def get_instances(db: Session = Depends(get_db)):
    return db.query(models.Instance).all()

@app.delete("/api/instances/{instance_id}")
def delete_instance(instance_id: int, db: Session = Depends(get_db)):
    instance = db.query(models.Instance).filter(models.Instance.id == instance_id).first()
    if instance:
        ecs_client.stop_task(
            cluster=CLUSTER_NAME,
            task=instance.task_arn
        )
        db.delete(instance)
        db.commit()
        return {"message": "Instance deleted"}
    return {"error": "Instance not found"}
