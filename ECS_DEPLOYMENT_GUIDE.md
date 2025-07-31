# Hoppscotch ECS Deployment Guide

This guide covers deploying Hoppscotch on AWS ECS (Elastic Container Service) with RDS for production-grade scalability and management.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [RDS Setup](#rds-setup)
4. [ECS Cluster Setup](#ecs-cluster-setup)
5. [Task Definitions](#task-definitions)
6. [Service Configuration](#service-configuration)
7. [Load Balancer Setup](#load-balancer-setup)
8. [Auto Scaling](#auto-scaling)
9. [Monitoring and Logging](#monitoring-and-logging)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
Internet Gateway
       |
Application Load Balancer (ALB)
       |
ECS Services (Multiple AZs)
├── Frontend Service
├── Backend Service  
├── Admin Service
└── MailHog Service (Optional)
       |
RDS PostgreSQL (Multi-AZ)
```

### Benefits of ECS + RDS
- **Scalability**: Auto-scaling based on demand
- **High Availability**: Multi-AZ deployment
- **Managed Services**: AWS handles infrastructure
- **Cost Optimization**: Pay for what you use
- **Security**: VPC isolation, IAM roles
- **Monitoring**: CloudWatch integration

---

## Prerequisites

### AWS CLI and Tools
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install ECS CLI
sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

# Configure AWS CLI
aws configure
```

### Required IAM Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:*",
                "rds:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "iam:*",
                "logs:*",
                "application-autoscaling:*"
            ],
            "Resource": "*"
        }
    ]
}
```

---

## RDS Setup

### 1. Create RDS Subnet Group
```bash
aws rds create-db-subnet-group \
    --db-subnet-group-name hoppscotch-db-subnet-group \
    --db-subnet-group-description "Subnet group for Hoppscotch RDS" \
    --subnet-ids subnet-12345678 subnet-87654321 \
    --tags Key=Name,Value=hoppscotch-db-subnet-group
```

### 2. Create RDS Security Group
```bash
aws ec2 create-security-group \
    --group-name hoppscotch-rds-sg \
    --description "Security group for Hoppscotch RDS" \
    --vpc-id vpc-12345678

# Allow PostgreSQL access from ECS
aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-rds-sg \
    --protocol tcp \
    --port 5432 \
    --source-group hoppscotch-ecs-sg
```

### 3. Create RDS Instance
```bash
aws rds create-db-instance \
    --db-instance-identifier hoppscotch-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.4 \
    --master-username hoppscotch \
    --master-user-password YourSecurePassword123! \
    --allocated-storage 20 \
    --storage-type gp2 \
    --db-name hoppscotchdb \
    --vpc-security-group-ids sg-12345678 \
    --db-subnet-group-name hoppscotch-db-subnet-group \
    --backup-retention-period 7 \
    --multi-az \
    --storage-encrypted \
    --tags Key=Name,Value=hoppscotch-db
```

### 4. Get RDS Endpoint
```bash
aws rds describe-db-instances \
    --db-instance-identifier hoppscotch-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text
```

---

## ECS Cluster Setup

### 1. Create ECS Cluster
```bash
aws ecs create-cluster \
    --cluster-name hoppscotch-cluster \
    --capacity-providers EC2 FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --tags key=Name,value=hoppscotch-cluster
```

### 2. Create VPC and Subnets (if needed)
```bash
# Create VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=hoppscotch-vpc}]'

# Create public subnets
aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hoppscotch-public-1}]'

aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hoppscotch-public-2}]'

# Create private subnets
aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 10.0.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hoppscotch-private-1}]'

aws ec2 create-subnet \
    --vpc-id vpc-12345678 \
    --cidr-block 10.0.4.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hoppscotch-private-2}]'
```

### 3. Create Security Groups
```bash
# ECS Security Group
aws ec2 create-security-group \
    --group-name hoppscotch-ecs-sg \
    --description "Security group for Hoppscotch ECS tasks" \
    --vpc-id vpc-12345678

# Allow HTTP/HTTPS from ALB
aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-ecs-sg \
    --protocol tcp \
    --port 3000 \
    --source-group hoppscotch-alb-sg

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-ecs-sg \
    --protocol tcp \
    --port 3100 \
    --source-group hoppscotch-alb-sg

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-ecs-sg \
    --protocol tcp \
    --port 3170 \
    --source-group hoppscotch-alb-sg

# ALB Security Group
aws ec2 create-security-group \
    --group-name hoppscotch-alb-sg \
    --description "Security group for Hoppscotch ALB" \
    --vpc-id vpc-12345678

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-alb-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-alb-sg \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

---

## Task Definitions

### 1. Create IAM Role for ECS Tasks
```bash
# Create execution role
aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ecs-tasks.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'

# Attach policy
aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### 2. Frontend Task Definition
Create `frontend-task-definition.json`:
```json
{
    "family": "hoppscotch-frontend",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "frontend",
            "image": "hoppscotch/hoppscotch-frontend:latest",
            "portMappings": [
                {
                    "containerPort": 3000,
                    "protocol": "tcp"
                },
                {
                    "containerPort": 3200,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "VITE_BASE_URL",
                    "value": "https://your-domain.com"
                },
                {
                    "name": "VITE_ADMIN_URL",
                    "value": "https://your-domain.com/admin"
                },
                {
                    "name": "VITE_BACKEND_GQL_URL",
                    "value": "https://your-domain.com/graphql"
                },
                {
                    "name": "VITE_BACKEND_WS_URL",
                    "value": "wss://your-domain.com/graphql"
                },
                {
                    "name": "VITE_BACKEND_API_URL",
                    "value": "https://your-domain.com/v1"
                },
                {
                    "name": "ENABLE_SUBPATH_BASED_ACCESS",
                    "value": "true"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/hoppscotch-frontend",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
```

### 3. Backend Task Definition
Create `backend-task-definition.json`:
```json
{
    "family": "hoppscotch-backend",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "512",
    "memory": "1024",
    "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "backend",
            "image": "hoppscotch/hoppscotch-backend:latest",
            "portMappings": [
                {
                    "containerPort": 3170,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "DATABASE_URL",
                    "value": "postgresql://hoppscotch:YourSecurePassword123!@your-rds-endpoint:5432/hoppscotchdb"
                },
                {
                    "name": "DATA_ENCRYPTION_KEY",
                    "value": "your-super-secure-32-char-key-here"
                },
                {
                    "name": "WHITELISTED_ORIGINS",
                    "value": "https://your-domain.com,app://localhost_3200,app://hoppscotch"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/hoppscotch-backend",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
```

### 4. Admin Task Definition
Create `admin-task-definition.json`:
```json
{
    "family": "hoppscotch-admin",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "admin",
            "image": "hoppscotch/hoppscotch-admin:latest",
            "portMappings": [
                {
                    "containerPort": 3100,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "VITE_BASE_URL",
                    "value": "https://your-domain.com"
                },
                {
                    "name": "VITE_ADMIN_URL",
                    "value": "https://your-domain.com/admin"
                },
                {
                    "name": "VITE_BACKEND_GQL_URL",
                    "value": "https://your-domain.com/graphql"
                },
                {
                    "name": "VITE_BACKEND_API_URL",
                    "value": "https://your-domain.com/v1"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/hoppscotch-admin",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
```

### 5. Register Task Definitions
```bash
aws ecs register-task-definition --cli-input-json file://frontend-task-definition.json
aws ecs register-task-definition --cli-input-json file://backend-task-definition.json
aws ecs register-task-definition --cli-input-json file://admin-task-definition.json
```

---

## Service Configuration

### 1. Create CloudWatch Log Groups
```bash
aws logs create-log-group --log-group-name /ecs/hoppscotch-frontend
aws logs create-log-group --log-group-name /ecs/hoppscotch-backend
aws logs create-log-group --log-group-name /ecs/hoppscotch-admin
```

### 2. Create ECS Services
```bash
# Frontend Service
aws ecs create-service \
    --cluster hoppscotch-cluster \
    --service-name hoppscotch-frontend \
    --task-definition hoppscotch-frontend:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678,subnet-87654321],securityGroups=[sg-12345678],assignPublicIp=ENABLED}" \
    --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-frontend-tg/1234567890123456,containerName=frontend,containerPort=3000

# Backend Service
aws ecs create-service \
    --cluster hoppscotch-cluster \
    --service-name hoppscotch-backend \
    --task-definition hoppscotch-backend:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678,subnet-87654321],securityGroups=[sg-12345678],assignPublicIp=ENABLED}" \
    --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-backend-tg/1234567890123456,containerName=backend,containerPort=3170

# Admin Service
aws ecs create-service \
    --cluster hoppscotch-cluster \
    --service-name hoppscotch-admin \
    --task-definition hoppscotch-admin:1 \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678,subnet-87654321],securityGroups=[sg-12345678],assignPublicIp=ENABLED}" \
    --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-admin-tg/1234567890123456,containerName=admin,containerPort=3100
```

---

## Load Balancer Setup

### 1. Create Application Load Balancer
```bash
aws elbv2 create-load-balancer \
    --name hoppscotch-alb \
    --subnets subnet-12345678 subnet-87654321 \
    --security-groups sg-12345678 \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --tags Key=Name,Value=hoppscotch-alb
```

### 2. Create Target Groups
```bash
# Frontend Target Group
aws elbv2 create-target-group \
    --name hoppscotch-frontend-tg \
    --protocol HTTP \
    --port 3000 \
    --vpc-id vpc-12345678 \
    --target-type ip \
    --health-check-path / \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3

# Backend Target Group
aws elbv2 create-target-group \
    --name hoppscotch-backend-tg \
    --protocol HTTP \
    --port 3170 \
    --vpc-id vpc-12345678 \
    --target-type ip \
    --health-check-path /health \
    --health-check-interval-seconds 30

# Admin Target Group
aws elbv2 create-target-group \
    --name hoppscotch-admin-tg \
    --protocol HTTP \
    --port 3100 \
    --vpc-id vpc-12345678 \
    --target-type ip \
    --health-check-path / \
    --health-check-interval-seconds 30
```

### 3. Create Listeners and Rules
```bash
# Create HTTP Listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/hoppscotch-alb/1234567890123456 \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-frontend-tg/1234567890123456

# Create rules for different paths
aws elbv2 create-rule \
    --listener-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/hoppscotch-alb/1234567890123456/1234567890123456 \
    --priority 100 \
    --conditions Field=path-pattern,Values="/admin*" \
    --actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-admin-tg/1234567890123456

aws elbv2 create-rule \
    --listener-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/hoppscotch-alb/1234567890123456/1234567890123456 \
    --priority 200 \
    --conditions Field=path-pattern,Values="/graphql*",Field=path-pattern,Values="/v1*" \
    --actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-backend-tg/1234567890123456
```

---

## Auto Scaling

### 1. Create Auto Scaling Targets
```bash
# Frontend Auto Scaling
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/hoppscotch-cluster/hoppscotch-frontend \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 1 \
    --max-capacity 10

# Backend Auto Scaling
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/hoppscotch-cluster/hoppscotch-backend \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 1 \
    --max-capacity 10
```

### 2. Create Scaling Policies
```bash
# CPU-based scaling policy
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/hoppscotch-cluster/hoppscotch-frontend \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name hoppscotch-frontend-cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
        "TargetValue": 70.0,
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
        },
        "ScaleOutCooldown": 300,
        "ScaleInCooldown": 300
    }'
```

---

## Monitoring and Logging

### 1. CloudWatch Dashboards
Create a custom dashboard for monitoring:
```bash
aws cloudwatch put-dashboard \
    --dashboard-name "Hoppscotch-ECS-Dashboard" \
    --dashboard-body '{
        "widgets": [
            {
                "type": "metric",
                "properties": {
                    "metrics": [
                        ["AWS/ECS", "CPUUtilization", "ServiceName", "hoppscotch-frontend", "ClusterName", "hoppscotch-cluster"],
                        [".", "MemoryUtilization", ".", ".", ".", "."],
                        ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/hoppscotch-alb/1234567890123456"]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "ECS Service Metrics"
                }
            }
        ]
    }'
```

### 2. CloudWatch Alarms
```bash
# High CPU Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "Hoppscotch-Frontend-High-CPU" \
    --alarm-description "Alarm when frontend CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=ServiceName,Value=hoppscotch-frontend Name=ClusterName,Value=hoppscotch-cluster \
    --evaluation-periods 2
```

---

## Troubleshooting

### Common ECS Issues

#### 1. Task Startup Failures
```bash
# Check task logs
aws logs get-log-events \
    --log-group-name /ecs/hoppscotch-frontend \
    --log-stream-name ecs/frontend/task-id

# Describe tasks
aws ecs describe-tasks \
    --cluster hoppscotch-cluster \
    --tasks task-arn
```

#### 2. Service Discovery Issues
```bash
# Check service status
aws ecs describe-services \
    --cluster hoppscotch-cluster \
    --services hoppscotch-frontend

# Check target group health
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hoppscotch-frontend-tg/1234567890123456
```

#### 3. Database Connection Issues
```bash
# Test RDS connectivity from ECS task
aws ecs run-task \
    --cluster hoppscotch-cluster \
    --task-definition hoppscotch-backend:1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678],securityGroups=[sg-12345678],assignPublicIp=ENABLED}" \
    --overrides '{
        "containerOverrides": [
            {
                "name": "backend",
                "command": ["sh", "-c", "pg_isready -h your-rds-endpoint -p 5432"]
            }
        ]
    }'
```

### Performance Optimization

#### 1. Right-sizing Resources
- Monitor CPU and memory usage
- Adjust task definitions based on actual usage
- Use Fargate Spot for cost optimization

#### 2. Database Optimization
- Use RDS Performance Insights
- Enable query logging
- Consider read replicas for read-heavy workloads

#### 3. Caching
- Implement ElastiCache for Redis
- Use CloudFront for static assets
- Enable ALB caching

---

## Cost Optimization

### 1. Fargate Spot
```json
{
    "capacityProviders": ["FARGATE", "FARGATE_SPOT"],
    "defaultCapacityProviderStrategy": [
        {
            "capacityProvider": "FARGATE_SPOT",
            "weight": 4
        },
        {
            "capacityProvider": "FARGATE",
            "weight": 1
        }
    ]
}
```

### 2. Scheduled Scaling
```bash
# Scale down during off-hours
aws application-autoscaling put-scheduled-action \
    --service-namespace ecs \
    --resource-id service/hoppscotch-cluster/hoppscotch-frontend \
    --scalable-dimension ecs:service:DesiredCount \
    --scheduled-action-name scale-down-evening \
    --schedule "cron(0 22 * * ? *)" \
    --scalable-target-action MinCapacity=1,MaxCapacity=2
```

---

*For additional configuration and advanced setups, refer to the [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)*
