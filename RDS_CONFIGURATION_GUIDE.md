# Hoppscotch RDS Configuration Guide

This guide covers setting up and configuring Amazon RDS PostgreSQL for Hoppscotch production deployments.

## Table of Contents
1. [RDS Instance Setup](#rds-instance-setup)
2. [Security Configuration](#security-configuration)
3. [Performance Optimization](#performance-optimization)
4. [Backup and Recovery](#backup-and-recovery)
5. [Monitoring and Alerts](#monitoring-and-alerts)
6. [Migration from Docker PostgreSQL](#migration-from-docker-postgresql)
7. [Troubleshooting](#troubleshooting)

---

## RDS Instance Setup

### 1. Basic RDS Instance Creation

#### Using AWS CLI
```bash
# Create DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name hoppscotch-db-subnet-group \
    --db-subnet-group-description "Subnet group for Hoppscotch RDS" \
    --subnet-ids subnet-12345678 subnet-87654321 subnet-abcdef12 \
    --tags Key=Name,Value=hoppscotch-db-subnet-group Key=Environment,Value=production

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier hoppscotch-prod-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.4 \
    --master-username hoppscotch \
    --master-user-password 'YourSecurePassword123!' \
    --allocated-storage 20 \
    --max-allocated-storage 100 \
    --storage-type gp3 \
    --storage-encrypted \
    --kms-key-id alias/aws/rds \
    --db-name hoppscotchdb \
    --vpc-security-group-ids sg-12345678 \
    --db-subnet-group-name hoppscotch-db-subnet-group \
    --backup-retention-period 7 \
    --backup-window "03:00-04:00" \
    --maintenance-window "sun:04:00-sun:05:00" \
    --multi-az \
    --publicly-accessible false \
    --auto-minor-version-upgrade true \
    --deletion-protection \
    --copy-tags-to-snapshot \
    --tags Key=Name,Value=hoppscotch-prod-db Key=Environment,Value=production
```

#### Using CloudFormation Template
Create `rds-template.yaml`:
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'RDS PostgreSQL instance for Hoppscotch'

Parameters:
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: VPC ID for RDS instance
  
  SubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
    Description: Subnet IDs for RDS subnet group
  
  MasterPassword:
    Type: String
    NoEcho: true
    MinLength: 8
    Description: Master password for RDS instance

Resources:
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupName: hoppscotch-db-subnet-group
      DBSubnetGroupDescription: Subnet group for Hoppscotch RDS
      SubnetIds: !Ref SubnetIds
      Tags:
        - Key: Name
          Value: hoppscotch-db-subnet-group

  DBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: hoppscotch-rds-sg
      GroupDescription: Security group for Hoppscotch RDS
      VpcId: !Ref VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref AppSecurityGroup
      Tags:
        - Key: Name
          Value: hoppscotch-rds-sg

  AppSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: hoppscotch-app-sg
      GroupDescription: Security group for Hoppscotch application
      VpcId: !Ref VpcId
      Tags:
        - Key: Name
          Value: hoppscotch-app-sg

  DBInstance:
    Type: AWS::RDS::DBInstance
    DeletionPolicy: Snapshot
    Properties:
      DBInstanceIdentifier: hoppscotch-prod-db
      DBInstanceClass: db.t3.micro
      Engine: postgres
      EngineVersion: '15.4'
      MasterUsername: hoppscotch
      MasterUserPassword: !Ref MasterPassword
      AllocatedStorage: 20
      MaxAllocatedStorage: 100
      StorageType: gp3
      StorageEncrypted: true
      DBName: hoppscotchdb
      VPCSecurityGroups:
        - !Ref DBSecurityGroup
      DBSubnetGroupName: !Ref DBSubnetGroup
      BackupRetentionPeriod: 7
      PreferredBackupWindow: "03:00-04:00"
      PreferredMaintenanceWindow: "sun:04:00-sun:05:00"
      MultiAZ: true
      PubliclyAccessible: false
      AutoMinorVersionUpgrade: true
      DeletionProtection: true
      CopyTagsToSnapshot: true
      Tags:
        - Key: Name
          Value: hoppscotch-prod-db
        - Key: Environment
          Value: production

Outputs:
  DBEndpoint:
    Description: RDS instance endpoint
    Value: !GetAtt DBInstance.Endpoint.Address
    Export:
      Name: !Sub "${AWS::StackName}-DBEndpoint"
  
  DBPort:
    Description: RDS instance port
    Value: !GetAtt DBInstance.Endpoint.Port
    Export:
      Name: !Sub "${AWS::StackName}-DBPort"
```

Deploy the template:
```bash
aws cloudformation create-stack \
    --stack-name hoppscotch-rds \
    --template-body file://rds-template.yaml \
    --parameters ParameterKey=VpcId,ParameterValue=vpc-12345678 \
                 ParameterKey=SubnetIds,ParameterValue="subnet-12345678,subnet-87654321" \
                 ParameterKey=MasterPassword,ParameterValue=YourSecurePassword123!
```

### 2. Instance Classes and Sizing

#### Development/Testing
```bash
# Small workloads
--db-instance-class db.t3.micro    # 1 vCPU, 1 GB RAM
--db-instance-class db.t3.small    # 1 vCPU, 2 GB RAM
```

#### Production
```bash
# Medium workloads
--db-instance-class db.t3.medium   # 2 vCPU, 4 GB RAM
--db-instance-class db.t3.large    # 2 vCPU, 8 GB RAM

# High-performance workloads
--db-instance-class db.r6g.large   # 2 vCPU, 16 GB RAM
--db-instance-class db.r6g.xlarge  # 4 vCPU, 32 GB RAM
```

### 3. Storage Configuration

#### Storage Types
```bash
# General Purpose SSD (gp3) - Recommended
--storage-type gp3
--allocated-storage 20
--max-allocated-storage 100
--iops 3000
--storage-throughput 125

# Provisioned IOPS SSD (io1) - High performance
--storage-type io1
--allocated-storage 100
--iops 1000
```

---

## Security Configuration

### 1. Security Groups
```bash
# Create RDS security group
aws ec2 create-security-group \
    --group-name hoppscotch-rds-sg \
    --description "Security group for Hoppscotch RDS" \
    --vpc-id vpc-12345678

# Allow PostgreSQL access only from application security group
aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-rds-sg \
    --protocol tcp \
    --port 5432 \
    --source-group hoppscotch-app-sg

# For debugging (remove in production)
aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-rds-sg \
    --protocol tcp \
    --port 5432 \
    --cidr 10.0.0.0/16
```

### 2. Parameter Groups
Create custom parameter group for optimization:
```bash
# Create parameter group
aws rds create-db-parameter-group \
    --db-parameter-group-name hoppscotch-postgres15 \
    --db-parameter-group-family postgres15 \
    --description "Custom parameter group for Hoppscotch PostgreSQL"

# Modify parameters
aws rds modify-db-parameter-group \
    --db-parameter-group-name hoppscotch-postgres15 \
    --parameters "ParameterName=shared_preload_libraries,ParameterValue=pg_stat_statements,ApplyMethod=pending-reboot" \
                 "ParameterName=log_statement,ParameterValue=all,ApplyMethod=immediate" \
                 "ParameterName=log_min_duration_statement,ParameterValue=1000,ApplyMethod=immediate" \
                 "ParameterName=max_connections,ParameterValue=200,ApplyMethod=pending-reboot"
```

### 3. Encryption
```bash
# Enable encryption at rest
--storage-encrypted \
--kms-key-id alias/aws/rds

# For encryption in transit, use SSL in connection string
DATABASE_URL=postgresql://username:password@endpoint:5432/dbname?sslmode=require
```

### 4. IAM Database Authentication (Optional)
```bash
# Enable IAM database authentication
aws rds modify-db-instance \
    --db-instance-identifier hoppscotch-prod-db \
    --enable-iam-database-authentication \
    --apply-immediately
```

---

## Performance Optimization

### 1. Connection Pooling
Use PgBouncer for connection pooling:

Create `pgbouncer-task-definition.json`:
```json
{
    "family": "pgbouncer",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "containerDefinitions": [
        {
            "name": "pgbouncer",
            "image": "pgbouncer/pgbouncer:latest",
            "portMappings": [
                {
                    "containerPort": 5432,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "DATABASES_HOST",
                    "value": "your-rds-endpoint"
                },
                {
                    "name": "DATABASES_PORT",
                    "value": "5432"
                },
                {
                    "name": "DATABASES_USER",
                    "value": "hoppscotch"
                },
                {
                    "name": "DATABASES_PASSWORD",
                    "value": "YourSecurePassword123!"
                },
                {
                    "name": "DATABASES_DBNAME",
                    "value": "hoppscotchdb"
                },
                {
                    "name": "POOL_MODE",
                    "value": "transaction"
                },
                {
                    "name": "MAX_CLIENT_CONN",
                    "value": "100"
                },
                {
                    "name": "DEFAULT_POOL_SIZE",
                    "value": "20"
                }
            ]
        }
    ]
}
```

### 2. Read Replicas
```bash
# Create read replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier hoppscotch-prod-db-replica \
    --source-db-instance-identifier hoppscotch-prod-db \
    --db-instance-class db.t3.micro \
    --publicly-accessible false \
    --tags Key=Name,Value=hoppscotch-prod-db-replica
```

### 3. Performance Insights
```bash
# Enable Performance Insights
aws rds modify-db-instance \
    --db-instance-identifier hoppscotch-prod-db \
    --enable-performance-insights \
    --performance-insights-retention-period 7 \
    --apply-immediately
```

---

## Backup and Recovery

### 1. Automated Backups
```bash
# Configure automated backups
aws rds modify-db-instance \
    --db-instance-identifier hoppscotch-prod-db \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --apply-immediately
```

### 2. Manual Snapshots
```bash
# Create manual snapshot
aws rds create-db-snapshot \
    --db-instance-identifier hoppscotch-prod-db \
    --db-snapshot-identifier hoppscotch-prod-db-snapshot-$(date +%Y%m%d%H%M%S)

# List snapshots
aws rds describe-db-snapshots \
    --db-instance-identifier hoppscotch-prod-db
```

### 3. Point-in-Time Recovery
```bash
# Restore to point in time
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier hoppscotch-prod-db \
    --target-db-instance-identifier hoppscotch-restored-db \
    --restore-time 2024-01-15T10:30:00.000Z
```

### 4. Cross-Region Backup
```bash
# Copy snapshot to another region
aws rds copy-db-snapshot \
    --source-db-snapshot-identifier arn:aws:rds:us-east-1:123456789012:snapshot:hoppscotch-prod-db-snapshot-20240115 \
    --target-db-snapshot-identifier hoppscotch-prod-db-snapshot-backup \
    --source-region us-east-1 \
    --region us-west-2
```

---

## Monitoring and Alerts

### 1. CloudWatch Metrics
```bash
# Create CPU utilization alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-HighCPU-hoppscotch-prod-db" \
    --alarm-description "Alarm when RDS CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=hoppscotch-prod-db \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:123456789012:rds-alerts

# Create connection count alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-HighConnections-hoppscotch-prod-db" \
    --alarm-description "Alarm when RDS connections exceed 80% of max" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 160 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=hoppscotch-prod-db \
    --evaluation-periods 2

# Create storage space alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-LowStorage-hoppscotch-prod-db" \
    --alarm-description "Alarm when RDS free storage is low" \
    --metric-name FreeStorageSpace \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 2000000000 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=hoppscotch-prod-db \
    --evaluation-periods 1
```

### 2. Enhanced Monitoring
```bash
# Enable enhanced monitoring
aws rds modify-db-instance \
    --db-instance-identifier hoppscotch-prod-db \
    --monitoring-interval 60 \
    --monitoring-role-arn arn:aws:iam::123456789012:role/rds-monitoring-role \
    --apply-immediately
```

### 3. Custom Dashboard
Create CloudWatch dashboard:
```json
{
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "hoppscotch-prod-db"],
                    [".", "DatabaseConnections", ".", "."],
                    [".", "FreeStorageSpace", ".", "."],
                    [".", "ReadLatency", ".", "."],
                    [".", "WriteLatency", ".", "."]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "RDS Performance Metrics"
            }
        }
    ]
}
```

---

## Migration from Docker PostgreSQL

### 1. Export Data from Docker
```bash
# Create backup from Docker PostgreSQL
docker exec hoppscotch-postgres pg_dump -U hoppscotch -d hoppscotchdb > hoppscotch_backup.sql

# Or with compression
docker exec hoppscotch-postgres pg_dump -U hoppscotch -d hoppscotchdb | gzip > hoppscotch_backup.sql.gz
```

### 2. Import to RDS
```bash
# Install PostgreSQL client
sudo apt-get install postgresql-client

# Import to RDS
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb < hoppscotch_backup.sql

# Or with compressed backup
gunzip -c hoppscotch_backup.sql.gz | psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb
```

### 3. Update Environment Variables
Update your application configuration:
```env
# Old Docker configuration
DATABASE_URL=postgresql://hoppscotch:password@postgres:5432/hoppscotchdb

# New RDS configuration
DATABASE_URL=postgresql://hoppscotch:password@your-rds-endpoint:5432/hoppscotchdb?sslmode=require
```

### 4. Migration Script
Create `migrate-to-rds.sh`:
```bash
#!/bin/bash

# Configuration
DOCKER_CONTAINER="hoppscotch-postgres"
RDS_ENDPOINT="your-rds-endpoint"
DB_USER="hoppscotch"
DB_NAME="hoppscotchdb"
BACKUP_FILE="hoppscotch_migration_$(date +%Y%m%d_%H%M%S).sql"

echo "Starting migration from Docker PostgreSQL to RDS..."

# Step 1: Create backup
echo "Creating backup from Docker container..."
docker exec $DOCKER_CONTAINER pg_dump -U $DB_USER -d $DB_NAME > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "Backup created successfully: $BACKUP_FILE"
else
    echo "Failed to create backup"
    exit 1
fi

# Step 2: Test RDS connection
echo "Testing RDS connection..."
pg_isready -h $RDS_ENDPOINT -p 5432 -U $DB_USER

if [ $? -eq 0 ]; then
    echo "RDS connection successful"
else
    echo "Failed to connect to RDS"
    exit 1
fi

# Step 3: Import to RDS
echo "Importing data to RDS..."
psql -h $RDS_ENDPOINT -U $DB_USER -d $DB_NAME < $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "Migration completed successfully"
    echo "Backup file saved as: $BACKUP_FILE"
else
    echo "Migration failed"
    exit 1
fi

echo "Migration completed. Please update your application configuration."
```

---

## Troubleshooting

### 1. Connection Issues
```bash
# Test connectivity
pg_isready -h your-rds-endpoint -p 5432 -U hoppscotch

# Test with psql
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb

# Check security groups
aws ec2 describe-security-groups --group-ids sg-12345678

# Check route tables and NACLs
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345678"
```

### 2. Performance Issues
```bash
# Check current connections
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb -c "SELECT count(*) FROM pg_stat_activity;"

# Check slow queries
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Check locks
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb -c "SELECT * FROM pg_locks WHERE NOT granted;"
```

### 3. Storage Issues
```bash
# Check database size
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb -c "SELECT pg_size_pretty(pg_database_size('hoppscotchdb'));"

# Check table sizes
psql -h your-rds-endpoint -U hoppscotch -d hoppscotchdb -c "SELECT schemaname,tablename,pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

### 4. Backup and Recovery Issues
```bash
# List available backups
aws rds describe-db-snapshots --db-instance-identifier hoppscotch-prod-db

# Check backup status
aws rds describe-db-instances --db-instance-identifier hoppscotch-prod-db --query 'DBInstances[0].BackupRetentionPeriod'

# Test restore (to new instance)
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier hoppscotch-test-restore \
    --db-snapshot-identifier your-snapshot-id
```

---

## Cost Optimization

### 1. Instance Right-Sizing
```bash
# Monitor CPU and memory usage
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --dimensions Name=DBInstanceIdentifier,Value=hoppscotch-prod-db \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-31T23:59:59Z \
    --period 3600 \
    --statistics Average
```

### 2. Reserved Instances
```bash
# List available reserved instance offerings
aws rds describe-reserved-db-instances-offerings \
    --db-instance-class db.t3.micro \
    --engine postgres

# Purchase reserved instance
aws rds purchase-reserved-db-instances-offering \
    --reserved-db-instances-offering-id offering-id \
    --reserved-db-instance-id hoppscotch-reserved-instance
```

### 3. Storage Optimization
- Use gp3 instead of gp2 for better price/performance
- Enable storage autoscaling
- Monitor storage usage and optimize queries

---

## Environment-Specific Configurations

### Development
```bash
--db-instance-class db.t3.micro
--allocated-storage 20
--backup-retention-period 1
--multi-az false
--deletion-protection false
```

### Staging
```bash
--db-instance-class db.t3.small
--allocated-storage 20
--backup-retention-period 3
--multi-az false
--deletion-protection false
```

### Production
```bash
--db-instance-class db.t3.medium
--allocated-storage 100
--backup-retention-period 7
--multi-az true
--deletion-protection true
--enable-performance-insights
--monitoring-interval 60
```

---

*For additional RDS configuration options, refer to the [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)*
