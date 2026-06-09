#!/bin/bash

# ============================================================================
# Install Required Tools
# ============================================================================

set -e

echo "Installing required tools for AWS DevOps Infrastructure..."
echo ""

OS=$(uname -s)

# Terraform
echo "Installing Terraform..."
if command -v terraform &> /dev/null; then
    echo "Terraform is already installed: $(terraform version -json | jq -r '.terraform_version')"
else
    if [ "$OS" == "Darwin" ]; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    elif [ "$OS" == "Linux" ]; then
        curl https://apt.releases.hashicorp.com/gpg | apt-key add -
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        apt-get update && apt-get install terraform
    fi
fi

# AWS CLI
echo "Installing AWS CLI..."
if command -v aws &> /dev/null; then
    echo "AWS CLI is already installed: $(aws --version)"
else
    pip install awscli --upgrade
fi

# kubectl
echo "Installing kubectl..."
if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed: $(kubectl version --client --short)"
else
    if [ "$OS" == "Darwin" ]; then
        brew install kubectl
    elif [ "$OS" == "Linux" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi
fi

# Docker
echo "Installing Docker..."
if command -v docker &> /dev/null; then
    echo "Docker is already installed: $(docker --version)"
else
    if [ "$OS" == "Darwin" ]; then
        brew install --cask docker
    elif [ "$OS" == "Linux" ]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
    fi
fi

# Helm
echo "Installing Helm..."
if command -v helm &> /dev/null; then
    echo "Helm is already installed: $(helm version --short)"
else
    if [ "$OS" == "Darwin" ]; then
        brew install helm
    elif [ "$OS" == "Linux" ]; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
fi

# JQ
echo "Installing jq..."
if command -v jq &> /dev/null; then
    echo "jq is already installed: $(jq --version)"
else
    if [ "$OS" == "Darwin" ]; then
        brew install jq
    elif [ "$OS" == "Linux" ]; then
        apt-get install -y jq
    fi
fi

echo ""
echo "All tools installed successfully!"
