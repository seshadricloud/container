#!/bin/bash

# ============================================================================
# Project Initialization Script
# ============================================================================

set -e

echo "========================================"
echo "AWS DevOps Infrastructure Setup"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
echo "${YELLOW}Checking for required tools...${NC}"

check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

check_tool "terraform" || exit 1
check_tool "aws" || exit 1
check_tool "kubectl" || exit 1
check_tool "docker" || exit 1
check_tool "git" || exit 1

echo ""
echo "${GREEN}All required tools are installed!${NC}"
echo ""

# Configure AWS credentials
echo "${YELLOW}Configuring AWS credentials...${NC}"
echo "Please enter your AWS credentials:"
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
read -p "AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION

echo "${GREEN}✓ AWS credentials configured${NC}"
echo ""

# Initialize Terraform
echo "${YELLOW}Initializing Terraform...${NC}"
cd terraform
terraform init -backend=false
echo "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Create S3 backend bucket
echo "${YELLOW}Creating S3 backend bucket for Terraform state...${NC}"
BUCKET_NAME="terraform-state-$(aws sts get-caller-identity --query Account --output text)"
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://${BUCKET_NAME}" --region ${AWS_REGION}
    echo "${GREEN}✓ S3 bucket created: ${BUCKET_NAME}${NC}"
else
    echo "${GREEN}✓ S3 bucket already exists: ${BUCKET_NAME}${NC}"
fi
echo ""

# Create DynamoDB table for Terraform locking
echo "${YELLOW}Creating DynamoDB table for Terraform locking...${NC}"
TABLE_NAME="terraform-locks"
if ! aws dynamodb describe-table --table-name ${TABLE_NAME} --region ${AWS_REGION} 2>&1 | grep -q 'Table not found'; then
    echo "${GREEN}✓ DynamoDB table already exists: ${TABLE_NAME}${NC}"
else
    aws dynamodb create-table \
        --table-name ${TABLE_NAME} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ${AWS_REGION}
    echo "${GREEN}✓ DynamoDB table created: ${TABLE_NAME}${NC}"
fi
echo ""

# Select environment
echo "${YELLOW}Select environment for initial setup:${NC}"
echo "1) dev"
echo "2) staging"
echo "3) prod"
read -p "Enter choice [1-3]: " ENV_CHOICE

case $ENV_CHOICE in
    1) ENVIRONMENT="dev" ;;
    2) ENVIRONMENT="staging" ;;
    3) ENVIRONMENT="prod" ;;
    *) ENVIRONMENT="dev" ;;
esac

echo ""
echo "${YELLOW}Planning Terraform for ${ENVIRONMENT} environment...${NC}"
terraform plan -var-file="environments/${ENVIRONMENT}.tfvars" -out=tfplan
echo ""

echo "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the Terraform plan above"
echo "2. Run: terraform apply tfplan"
echo "3. Once infrastructure is created, configure kubectl"
echo "4. Run: aws eks update-kubeconfig --name myapp-${ENVIRONMENT}-eks --region ${AWS_REGION}"
echo "5. Deploy applications: kubectl apply -f kubernetes/"
echo ""
