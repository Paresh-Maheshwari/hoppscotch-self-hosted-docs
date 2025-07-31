#!/bin/bash

echo "🚀 Hoppscotch ECS + RDS Deployment Script"
echo "=========================================="

# Configuration
STACK_NAME="hoppscotch-ecs-rds"
REGION="us-east-1"
ENVIRONMENT="production"
DOMAIN_NAME=""
CERTIFICATE_ARN=""
DB_PASSWORD=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

get_user_input() {
    log_info "Gathering deployment configuration..."
    
    # Stack name
    read -p "Enter stack name (default: hoppscotch-ecs-rds): " input_stack_name
    STACK_NAME=${input_stack_name:-$STACK_NAME}
    
    # Region
    read -p "Enter AWS region (default: us-east-1): " input_region
    REGION=${input_region:-$REGION}
    
    # Environment
    echo "Select environment:"
    echo "1) development"
    echo "2) staging"
    echo "3) production"
    read -p "Enter choice (1-3, default: 3): " env_choice
    case $env_choice in
        1) ENVIRONMENT="development" ;;
        2) ENVIRONMENT="staging" ;;
        *) ENVIRONMENT="production" ;;
    esac
    
    # Domain name
    read -p "Enter domain name (e.g., hoppscotch.example.com): " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        log_error "Domain name is required"
        exit 1
    fi
    
    # SSL Certificate
    read -p "Enter SSL certificate ARN: " CERTIFICATE_ARN
    if [ -z "$CERTIFICATE_ARN" ]; then
        log_error "SSL certificate ARN is required"
        exit 1
    fi
    
    # Database password
    while true; do
        read -s -p "Enter database master password (min 8 characters): " DB_PASSWORD
        echo
        if [ ${#DB_PASSWORD} -ge 8 ]; then
            break
        else
            log_error "Password must be at least 8 characters long"
        fi
    done
    
    log_info "Configuration complete"
}

validate_certificate() {
    log_info "Validating SSL certificate..."
    
    if ! aws acm describe-certificate --certificate-arn "$CERTIFICATE_ARN" --region "$REGION" &> /dev/null; then
        log_error "SSL certificate not found or not accessible"
        exit 1
    fi
    
    log_info "SSL certificate validated"
}

deploy_stack() {
    log_info "Deploying CloudFormation stack..."
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        log_info "Stack exists, updating..."
        OPERATION="update-stack"
    else
        log_info "Creating new stack..."
        OPERATION="create-stack"
    fi
    
    # Deploy stack
    aws cloudformation $OPERATION \
        --stack-name "$STACK_NAME" \
        --template-body file://cloudformation-ecs-rds.yaml \
        --parameters \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            ParameterKey=DomainName,ParameterValue="$DOMAIN_NAME" \
            ParameterKey=CertificateArn,ParameterValue="$CERTIFICATE_ARN" \
            ParameterKey=DBMasterPassword,ParameterValue="$DB_PASSWORD" \
        --capabilities CAPABILITY_IAM \
        --region "$REGION" \
        --tags \
            Key=Environment,Value="$ENVIRONMENT" \
            Key=Application,Value=Hoppscotch \
            Key=ManagedBy,Value=CloudFormation
    
    if [ $? -eq 0 ]; then
        log_info "Stack deployment initiated successfully"
    else
        log_error "Stack deployment failed"
        exit 1
    fi
}

wait_for_stack() {
    log_info "Waiting for stack deployment to complete..."
    
    if [[ "$OPERATION" == "create-stack" ]]; then
        WAIT_CONDITION="stack-create-complete"
    else
        WAIT_CONDITION="stack-update-complete"
    fi
    
    aws cloudformation wait $WAIT_CONDITION \
        --stack-name "$STACK_NAME" \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        log_info "Stack deployment completed successfully"
    else
        log_error "Stack deployment failed or timed out"
        
        # Get stack events for debugging
        log_info "Recent stack events:"
        aws cloudformation describe-stack-events \
            --stack-name "$STACK_NAME" \
            --region "$REGION" \
            --query 'StackEvents[0:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
            --output table
        
        exit 1
    fi
}

run_migrations() {
    log_info "Running database migrations..."
    
    # Get cluster name and task definition
    CLUSTER_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' \
        --output text)
    
    # Get subnet and security group for migration task
    VPC_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
        --output text)
    
    SUBNET_ID=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" \
        --query 'Subnets[0].SubnetId' \
        --output text \
        --region "$REGION")
    
    SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*ecs*" \
        --query 'SecurityGroups[0].GroupId' \
        --output text \
        --region "$REGION")
    
    # Run migration task
    TASK_ARN=$(aws ecs run-task \
        --cluster "$CLUSTER_NAME" \
        --task-definition "${STACK_NAME}-backend" \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
        --overrides '{
            "containerOverrides": [
                {
                    "name": "backend",
                    "command": ["pnpm", "dlx", "prisma", "migrate", "deploy"]
                }
            ]
        }' \
        --region "$REGION" \
        --query 'tasks[0].taskArn' \
        --output text)
    
    if [ "$TASK_ARN" != "None" ]; then
        log_info "Migration task started: $TASK_ARN"
        
        # Wait for task to complete
        aws ecs wait tasks-stopped \
            --cluster "$CLUSTER_NAME" \
            --tasks "$TASK_ARN" \
            --region "$REGION"
        
        # Check task exit code
        EXIT_CODE=$(aws ecs describe-tasks \
            --cluster "$CLUSTER_NAME" \
            --tasks "$TASK_ARN" \
            --region "$REGION" \
            --query 'tasks[0].containers[0].exitCode' \
            --output text)
        
        if [ "$EXIT_CODE" == "0" ]; then
            log_info "Database migrations completed successfully"
        else
            log_error "Database migrations failed with exit code: $EXIT_CODE"
            
            # Get task logs
            log_info "Checking migration logs..."
            LOG_GROUP="/ecs/${STACK_NAME}-backend"
            LOG_STREAM=$(aws logs describe-log-streams \
                --log-group-name "$LOG_GROUP" \
                --order-by LastEventTime \
                --descending \
                --limit 1 \
                --region "$REGION" \
                --query 'logStreams[0].logStreamName' \
                --output text)
            
            if [ "$LOG_STREAM" != "None" ]; then
                aws logs get-log-events \
                    --log-group-name "$LOG_GROUP" \
                    --log-stream-name "$LOG_STREAM" \
                    --region "$REGION" \
                    --query 'events[*].message' \
                    --output text
            fi
        fi
    else
        log_error "Failed to start migration task"
    fi
}

get_outputs() {
    log_info "Getting deployment outputs..."
    
    # Get stack outputs
    LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
        --output text)
    
    DATABASE_ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
        --output text)
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "===================================="
    echo ""
    echo "📋 Deployment Information:"
    echo "   Stack Name: $STACK_NAME"
    echo "   Region: $REGION"
    echo "   Environment: $ENVIRONMENT"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Application: https://$DOMAIN_NAME"
    echo "   Admin Panel: https://$DOMAIN_NAME/admin"
    echo "   Load Balancer: $LOAD_BALANCER_DNS"
    echo ""
    echo "🗄️  Database:"
    echo "   Endpoint: $DATABASE_ENDPOINT"
    echo "   Database: hoppscotchdb"
    echo "   Username: hoppscotch"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Update your DNS to point $DOMAIN_NAME to $LOAD_BALANCER_DNS"
    echo "   2. Wait for DNS propagation (may take up to 48 hours)"
    echo "   3. Access your application at https://$DOMAIN_NAME"
    echo "   4. Create your first admin user at https://$DOMAIN_NAME/admin"
    echo ""
    echo "🔧 Management Commands:"
    echo "   View stack: aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION"
    echo "   View services: aws ecs list-services --cluster ${STACK_NAME}-cluster --region $REGION"
    echo "   View logs: aws logs describe-log-groups --log-group-name-prefix /ecs/$STACK_NAME --region $REGION"
    echo ""
}

cleanup_on_error() {
    if [ $? -ne 0 ]; then
        log_error "Deployment failed. Check the CloudFormation console for details."
        log_info "Stack events:"
        aws cloudformation describe-stack-events \
            --stack-name "$STACK_NAME" \
            --region "$REGION" \
            --query 'StackEvents[0:5].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
            --output table 2>/dev/null || true
    fi
}

# Main execution
main() {
    trap cleanup_on_error ERR
    
    check_prerequisites
    get_user_input
    validate_certificate
    deploy_stack
    wait_for_stack
    run_migrations
    get_outputs
}

# Run main function
main "$@"
