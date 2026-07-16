# Containerized Microservices Platform (AWS ECS Fargate)

Two independently deployable microservices — **orders** and **users** — containerized with Docker, orchestrated on **AWS ECS Fargate**, and routed through a single **Application Load Balancer** using path-based routing. Provisioned entirely with **Terraform** and deployed through **per-service GitHub Actions CI/CD pipelines**.

---

## Problem Statement

An e-commerce-style backend needs to scale its **orders** and **users** functionality independently, with each service owned, deployed, and scaled on its own schedule—without one service's release cycle blocking or affecting the other.

This project simulates that split by decomposing a monolithic backend into two independently deployable services while sharing common networking and load balancing infrastructure.

---

# Architecture

## Architecture Diagram

```text
                               Internet
                                  │
                                  ▼
                        ┌──────────────────┐
                        │   ALB (public)   │
                        │  HTTP :80        │
                        └────────┬─────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
           /orders/* rule                  /users/* rule
                 │                               │
                 ▼                               ▼
        ┌───────────────────┐          ┌───────────────────┐
        │ Orders Target     │          │ Users Target      │
        │ Group (IP)        │          │ Group (IP)        │
        └─────────┬─────────┘          └─────────┬─────────┘
                  │                              │
                  ▼                              ▼
       ┌─────────────────────┐        ┌─────────────────────┐
       │ ECS Service         │        │ ECS Service         │
       │ orders              │        │ users               │
       │ desired_count = 2   │        │ desired_count = 2   │
       └─────────┬───────────┘        └─────────┬───────────┘
                 │                              │
                 ▼                              ▼
     Fargate Tasks (AZ-a, AZ-b)      Fargate Tasks (AZ-a, AZ-b)
      Public Subnets + ENI            Public Subnets + ENI
      SG: 3000 from ALB SG only       SG: 3000 from ALB SG only
```

Requests that do not match `/orders*` or `/users*` receive an explicit **404** from the ALB listener's default action.

---

## AWS Services & Tools Used

| Service | Purpose |
|---------|---------|
| Docker | Containerizes each service independently |
| Amazon ECR | Stores versioned container images |
| Amazon ECS Fargate | Serverless container orchestration |
| Application Load Balancer | Routes requests using path-based routing |
| Amazon VPC | Networking across two Availability Zones |
| Security Groups | Least-privilege traffic control (ALB → ECS Tasks) |
| CloudWatch Logs | Centralized container logging (7-day retention) |
| IAM Task Execution Role | Allows ECS to pull images and write logs |
| Amazon S3 | Remote Terraform state backend |
| Terraform | Infrastructure as Code |
| GitHub Actions | Independent CI/CD pipelines for each service |

---

## Repository Structure

```text
project-2-microservices/
│
├── services/
│   ├── orders/
│   └── users/
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── security_groups.tf
│   ├── alb.tf
│   ├── ecs-cluster.tf
│   ├── ecs-iam.tf
│   ├── ecs-task-definitions.tf
│   └── ecs-services.tf
│
└── .github/
    └── workflows/
        ├── orders-deploy.yml
        └── users-deploy.yml
```

---

## How to Deploy

### Prerequisites

- Terraform ≥ 1.9
- Docker
- AWS CLI configured
- AWS account with appropriate permissions

Clone the repository:

```bash
git clone https://github.com/Mus7ab/microservices-orders-users.git

cd microservices-orders-users/terraform
```

Initialize Terraform:

```bash
terraform init
terraform plan
terraform apply
```

---

### First Deployment Only

This repository provisions the infrastructure only.

Before ECS services can start successfully, the initial Docker images must exist inside Amazon ECR.

Login to ECR:

```bash
aws ecr get-login-password --region ap-south-2 \
| docker login \
--username AWS \
--password-stdin \
342677169816.dkr.ecr.ap-south-2.amazonaws.com
```

Build and push the Orders service:

```bash
docker build \
-t 342677169816.dkr.ecr.ap-south-2.amazonaws.com/orders-service:v1 \
services/orders

docker push \
342677169816.dkr.ecr.ap-south-2.amazonaws.com/orders-service:v1
```

Repeat the same process for the Users service.

After the initial deployment, **GitHub Actions automatically handles future builds and deployments.**

---

## CI/CD

Each microservice has its own independent deployment pipeline.

| Workflow | Trigger |
|-----------|---------|
| orders-deploy.yml | Changes under `services/orders/**` |
| users-deploy.yml | Changes under `services/users/**` |

Each workflow:

1. Builds a Docker image
2. Tags it using the Git commit SHA
3. Pushes it to Amazon ECR
4. Registers a new ECS Task Definition revision
5. Deploys the new revision to ECS

A change to one service **never redeploys the other**, demonstrating true independent deployment.

---

# Design Decisions

## 1. Public Subnets for Fargate Tasks

**Decision**

Run ECS Fargate tasks inside public subnets using:

```terraform
assign_public_ip = true
```

**Tradeoff**

Amazon ECR is reached through public AWS endpoints.

Keeping tasks inside private subnets would require either:

- a NAT Gateway (additional monthly cost), or
- VPC Endpoints (more advanced architecture)

For a learning project focused on AWS Free Plan costs, public subnets with tightly scoped security groups provided the best cost-to-complexity tradeoff.

---

## 2. Target Groups use `target_type = "ip"`

Unlike EC2-backed ECS, Fargate tasks do not have instance IDs.

Each task receives its own ENI and private IP address through `awsvpc` networking.

Therefore, ALB target groups must register IP addresses rather than EC2 instances.

---

## 3. Independent CI/CD Pipelines

Orders and Users each have their own GitHub Actions workflow.

Although maintaining two workflows requires slightly more configuration, it reflects the primary architectural benefit of microservices:

- independent deployments
- isolated releases
- no unnecessary rebuilds

This behavior was verified by confirming that changes to one service never triggered deployment of the other.

---

## 4. Explicit Task Definition Revisioning

Initially, deployments used:

```bash
aws ecs update-service --force-new-deployment
```

This only restarted tasks using the existing task definition.

It **did not** deploy newly pushed Docker images.

The issue was diagnosed by examining:

```bash
aws ecs describe-services
```

which showed both deployments referencing the same task definition revision.

The solution was to:

- render a new task definition
- register a new revision
- deploy that revision using the official AWS GitHub Actions

---

## 5. SHA-Based Image Tagging

Images are tagged using the Git commit SHA rather than a static tag like `v1`.

Benefits include:

- immutable deployments
- complete traceability
- reproducible releases
- easy rollback to previous versions

---

# Known Limitations & Future Improvements

- HTTPS is not yet configured (pending ACM certificate)
- ECR image scanning (`scanOnPush`) is currently disabled
- Lifecycle policies for automatic image cleanup are planned
- CI IAM permissions can be reduced further using a custom least-privilege policy
- Only one environment currently exists (no Dev / Staging / Production separation)
- ECS Service Auto Scaling has not yet been configured (`desired_count = 2`)

---

# Cost Estimate

Actual AWS cost incurred during development (approximately 16 days):

**≈ $7.83 USD**

This was covered using available AWS promotional Free Plan credits.

Unlike EC2, **AWS Fargate does not include a Free Tier allowance**, meaning compute charges begin immediately.

Approximate monthly on-demand costs if left running:

| Resource | Approximate Cost |
|-----------|-----------------:|
| Application Load Balancer | $16–20/month |
| Four Fargate Tasks | $25–30/month |
| Amazon ECR Storage | < $1/month |

---

# Teardown

Destroy all infrastructure:

```bash
cd terraform

terraform destroy
```

Terraform removes all managed infrastructure.

Amazon ECR repositories and their images are intentionally managed separately and should be deleted manually if no longer required.

---

# Lessons Learned

This project reinforced several production-oriented AWS concepts:

- Infrastructure should use remote Terraform state **before** introducing CI/CD.
- ECS Fargate requires IP-based target registration rather than instance registration.
- Passing CI pipelines do not necessarily mean successful deployments—always verify the deployed behavior.
- Microservices benefit from independently triggered deployment pipelines.
- Immutable image tagging combined with task definition revisioning provides reliable, traceable deployments.

---

## License

This project is licensed under the MIT License.
