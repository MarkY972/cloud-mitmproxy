resource "aws_ecs_task_definition" "backend" {
  family                   = "mitmproxy-saas-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ],
      "environment": [
        {
          "name": "SUBNET_A",
          "value": "${aws_subnet.public_a.id}"
        },
        {
          "name": "SUBNET_B",
          "value": "${aws_subnet.public_b.id}"
        },
        {
          "name": "DATABASE_URL",
          "value": "postgresql://admin:${aws_secretsmanager_secret_version.db_password.secret_string}@${aws_db_instance.main.address}/mitmproxysaas"
        },
        {
          "name": "MITMPROXY_SG_ID",
          "value": "${aws_security_group.mitmproxy_sg.id}"
        },
        {
          "name": "CLUSTER_NAME",
          "value": "${aws_ecs_cluster.main.name}"
        },
        {
          "name": "TASK_DEFINITION_ARN",
          "value": "${aws_ecs_task_definition.mitmproxy.arn}"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "mitmproxy-saas-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "mitmproxy-saas-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "mitmproxy-saas-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }
}

resource "aws_ecs_task_definition" "mitmproxy" {
  family                   = "mitmproxy-saas-mitmproxy-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "mitmproxy"
      image     = "mitmproxy/mitmproxy"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}
