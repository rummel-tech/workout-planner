#!/usr/bin/env python3
"""
Create RDS PostgreSQL instance and update Secrets Manager
"""
import os
import sys
import time
import secrets
import string
import boto3
from botocore.exceptions import ClientError

# AWS Configuration
AWS_ACCESS_KEY_ID = "AKIA5D5COMKUECIJF45Q"
AWS_SECRET_ACCESS_KEY = "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"
AWS_REGION = "us-east-1"

# RDS Configuration
DB_INSTANCE_ID = "fitness-agent-dev"
DB_INSTANCE_CLASS = "db.t3.micro"
DB_ENGINE = "postgres"
DB_ENGINE_VERSION = "15.4"
DB_USERNAME = "fitnessadmin"
DB_ALLOCATED_STORAGE = 20
SECURITY_GROUP_ID = "sg-0e8d3e975a74e878a"

# Secrets Manager
SECRET_ID = "fitness-agent/dev/database_url"

def generate_password(length=32):
    """Generate a secure random password"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ''.join(secrets.choice(alphabet) for i in range(length))
    return password

def create_rds_instance(rds_client, password):
    """Create RDS PostgreSQL instance"""
    print("Creating RDS PostgreSQL instance...")
    print(f"Instance ID: {DB_INSTANCE_ID}")
    print(f"Instance class: {DB_INSTANCE_CLASS}")
    print(f"Engine: {DB_ENGINE} {DB_ENGINE_VERSION}")
    print("")
    
    try:
        response = rds_client.create_db_instance(
            DBInstanceIdentifier=DB_INSTANCE_ID,
            DBInstanceClass=DB_INSTANCE_CLASS,
            Engine=DB_ENGINE,
            EngineVersion=DB_ENGINE_VERSION,
            MasterUsername=DB_USERNAME,
            MasterUserPassword=password,
            AllocatedStorage=DB_ALLOCATED_STORAGE,
            VpcSecurityGroupIds=[SECURITY_GROUP_ID],
            BackupRetentionPeriod=7,
            PreferredBackupWindow="03:00-04:00",
            PreferredMaintenanceWindow="sun:04:00-sun:05:00",
            StorageEncrypted=True,
            PubliclyAccessible=True
        )
        print("✅ RDS instance creation initiated successfully!")
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'DBInstanceAlreadyExists':
            print("⚠️  RDS instance already exists. Using existing instance.")
            return True
        else:
            print(f"❌ Error creating RDS instance: {e}")
            return False

def wait_for_instance(rds_client):
    """Wait for RDS instance to become available"""
    print("\nWaiting for instance to become available (this may take 10-15 minutes)...")
    print("Checking status every 30 seconds...")
    
    waiter = rds_client.get_waiter('db_instance_available')
    
    try:
        waiter.wait(
            DBInstanceIdentifier=DB_INSTANCE_ID,
            WaiterConfig={
                'Delay': 30,
                'MaxAttempts': 40  # 20 minutes max
            }
        )
        print("✅ Database is ready!")
        return True
    except Exception as e:
        print(f"❌ Error waiting for instance: {e}")
        return False

def get_endpoint(rds_client):
    """Get RDS endpoint"""
    try:
        response = rds_client.describe_db_instances(
            DBInstanceIdentifier=DB_INSTANCE_ID
        )
        endpoint = response['DBInstances'][0]['Endpoint']['Address']
        port = response['DBInstances'][0]['Endpoint']['Port']
        return endpoint, port
    except Exception as e:
        print(f"❌ Error getting endpoint: {e}")
        return None, None

def update_secrets_manager(sm_client, connection_string):
    """Update Secrets Manager with connection string"""
    print("\nUpdating AWS Secrets Manager...")
    
    try:
        sm_client.put_secret_value(
            SecretId=SECRET_ID,
            SecretString=connection_string
        )
        print("✅ Secrets Manager updated successfully!")
        return True
    except Exception as e:
        print(f"❌ Error updating Secrets Manager: {e}")
        return False

def main():
    # Initialize AWS clients
    rds_client = boto3.client(
        'rds',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )
    
    sm_client = boto3.client(
        'secretsmanager',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )
    
    # Generate password
    db_password = generate_password()
    print("=" * 60)
    print("Generated database password (save this!):")
    print(db_password)
    print("=" * 60)
    print("")
    
    # Create RDS instance
    if not create_rds_instance(rds_client, db_password):
        sys.exit(1)
    
    # Wait for instance to be ready
    if not wait_for_instance(rds_client):
        sys.exit(1)
    
    # Get endpoint
    endpoint, port = get_endpoint(rds_client)
    if not endpoint:
        sys.exit(1)
    
    print(f"\nEndpoint: {endpoint}:{port}")
    
    # Construct connection string
    connection_string = f"postgresql://{DB_USERNAME}:{db_password}@{endpoint}:{port}/postgres"
    print("\nConnection string:")
    print(connection_string)
    
    # Update Secrets Manager
    if not update_secrets_manager(sm_client, connection_string):
        sys.exit(1)
    
    print("\n" + "=" * 60)
    print("✅ Setup complete!")
    print("=" * 60)
    print("\nNext step: Run ./deploy.sh to deploy your app")
    print("")

if __name__ == "__main__":
    main()
