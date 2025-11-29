# Mitmproxy SaaS Platform

This project provides a fully-featured, cloud-native SaaS platform for the popular `mitmproxy` tool. It allows users to create, manage, and connect to their own `mitmproxy` instances directly from a web interface, running on scalable and secure AWS infrastructure.

## Table of Contents

- [Architecture](#architecture)
  - [Blueprint](#blueprint)
  - [Components](#components)
- [Deployment and Usage](#deployment-and-usage)
  - [Prerequisites](#prerequisites)
  - [Deployment Steps](#deployment-steps)
  - [Accessing the GUI](#accessing-the-gui)
- [API Documentation](#api-documentation)
  - [Create Instance](#create-instance)
  - [Get All Instances](#get-all-instances)
  - [Delete Instance](#delete-instance)

## Architecture

The platform is built on a modern, decoupled architecture that leverages AWS managed services for scalability, security, and reliability.

### Blueprint

```
       +--------------------------------------------------------------------------+
       |                                  User                                    |
       +--------------------------------------------------------------------------+
                                           |
                                           | HTTPS (Port 443)
                                           |
+----------------------------------------------------------------------------------------+
|                                    AWS Cloud                                           |
|                                                                                        |
|    +------------------------------------------------------------------------------+    |
|    |                               VPC                                            |    |
|    |                                                                              |    |
|    |  +-------------------------+      +----------------------------------------+  |    |
|    |  |     Public Subnets      |      |           Private Subnets              |  |    |
|    |  |                         |      |                                        |  |    |
|    |  |  +-------------------+  |      |      +------------------------------+  |  |    |
|    |  |  |   Application     |  |      |      |       RDS PostgreSQL         |  |  |    |
|    |  |  |  Load Balancer    |  |      |      |          Database            |  |  |    |
|    |  |  +-------------------+  |      |      +------------------------------+  |  |    |
|    |  |           |             |      |                   ^                    |  |    |
|    |  |           |             |      |                   | (DB Connection)    |  |    |
|    |  | +---------+---------+   |      |                   |                    |  |    |
|    |  | | Path-based Routing|   |      |                   |                    |  |    |
|    |  | +-------------------+   |      |                   |                    |  |    |
|    |  |   |               |     |      +-------------------|--------------------+  |    |
|    |  |   | (`/api/*`)    | (`/*`) |                         |                      |    |
|    |  |   v               v     |                         |                      |    |
|    |  | +---------------+ +---------------+               |                      |    |
|    |  | | ECS Service   | | ECS Service   |               |                      |    |
|    |  | |   (Backend)   | |  (Frontend)   |               |                      |    |
|    |  | +---------------+ +---------------+               |                      |    |
|    |  |       |                 |                         |                      |    |
|    |  |       | (AWS SDK)       +-------------------------+                      |    |
|    |  |       v                                                                  |    |
|    |  | +----------------------------------------------------------------+       |    |
|    |  | |                    Dynamically Launched                      |       |    |
|    |  | |                    mitmproxy ECS Tasks                       |       |    |
|    |  | +----------------------------------------------------------------+       |    |
|    |  +--------------------------------------------------------------------------+    |
|    |                                                                              |    |
+----------------------------------------------------------------------------------------+
```

### Components

-   **Frontend**: A responsive web application built with **React**. It provides a user-friendly interface to create, view, and delete `mitmproxy` instances. It is served by a lightweight **Nginx** web server in production.
-   **Backend**: A robust API built with **Python** and **FastAPI**. It handles all the business logic, including launching, stopping, and managing the lifecycle of `mitmproxy` instances by interacting directly with the AWS API using `boto3`.
-   **Database**: A **PostgreSQL** database hosted on **Amazon RDS**. It is deployed in private subnets to ensure data security. The database stores the state of all active `mitmproxy` instances, including their task ARNs and public IP addresses. Database migrations are managed by `yoyo-migrations`.
-   **Container Orchestration**: The entire application is containerized with **Docker** and runs on **AWS Elastic Container Service (ECS)** with the **Fargate** launch type, providing a serverless and scalable compute engine.
-   **Networking**:
    -   An **Application Load Balancer (ALB)** serves as the single entry point for all traffic. It uses path-based routing to direct requests starting with `/api/` to the backend service and all other requests to the frontend service.
    -   A **Virtual Private Cloud (VPC)** provides a logically isolated section of the AWS Cloud. It is configured with both public and private subnets to enforce a secure network architecture.
-   **Infrastructure as Code (IaC)**: The entire cloud infrastructure is defined and managed using **Terraform**, enabling consistent, repeatable, and automated deployments.
-   **CI/CD**: A **GitHub Actions** workflow automates the entire process of building, testing, and deploying the application. When changes are pushed to the `main` branch, the workflow builds new Docker images, pushes them to Docker Hub, and applies the Terraform configuration to update the services on ECS.

## Deployment and Usage

### Prerequisites

Before you can deploy the platform, you will need the following:

-   An **AWS Account** with the necessary permissions to create the resources defined in the Terraform configuration.
-   The **AWS CLI** installed and configured with your credentials.
-   **Terraform** installed on your local machine.
-   A **GitHub Account** and a forked version of this repository.
-   A **Docker Hub Account** to store the frontend and backend Docker images.

### Deployment Steps

1.  **Fork the Repository**: Start by forking this repository to your own GitHub account.
2.  **Configure GitHub Secrets**: In your forked repository's settings, navigate to `Secrets and variables > Actions` and add the following secrets:
    -   `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
    -   `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.
    -   `DOCKER_HUB_USERNAME`: Your Docker Hub username.
    -   `DOCKER_HUB_ACCESS_TOKEN`: An access token for your Docker Hub account with read/write permissions.
3.  **Push to `main`**: The GitHub Actions workflow is configured to run on every push to the `main` branch. The first time the workflow runs, it will:
    -   Build and push the frontend and backend Docker images to your Docker Hub repository.
    -   Run `terraform apply` to provision all the necessary AWS resources.
    -   Deploy the latest versions of the frontend and backend services to the ECS cluster.

### Accessing the GUI

Once the deployment is complete, you can access the web interface:

1.  Navigate to the **Terraform** outputs in the logs of the `Terraform Apply` step in your GitHub Actions workflow.
2.  Find the output variable named `lb_dns_name`.
3.  Copy this DNS name and paste it into your web browser. You will see the application's main page, where you can start creating and managing `mitmproxy` instances.

## API Documentation

The backend provides a RESTful API for managing `mitmproxy` instances. The base URL for the API is the DNS name of the Application Load Balancer.

### Create Instance

-   **Endpoint**: `POST /api/instances`
-   **Description**: Creates and launches a new `mitmproxy` instance.
-   **Response**: A JSON object representing the newly created instance.
-   **Example `curl` command**:
    ```bash
    curl -X POST http://<your-alb-dns-name>/api/instances
    ```

### Get All Instances

-   **Endpoint**: `GET /api/instances`
-   **Description**: Retrieves a list of all active `mitmproxy` instances.
-   **Response**: A JSON array of instance objects.
-   **Example `curl` command**:
    ```bash
    curl http://<your-alb-dns-name>/api/instances
    ```

### Delete Instance

-   **Endpoint**: `DELETE /api/instances/{id}`
-   **Description**: Stops and removes a specific `mitmproxy` instance by its ID.
-   **Response**: A confirmation message.
-   **Example `curl` command**:
    ```bash
    curl -X DELETE http://<your-alb-dns-name>/api/instances/1
    ```
