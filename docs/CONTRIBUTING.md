# Contributing Guidelines

## How to Contribute

## Getting Started

1. Fork the repository
2. Create feature branch: `git checkout -b feature/feature-name`
3. Make changes and test
4. Commit with clear messages
5. Push and open pull request

## Development Setup

```bash
# Clone and setup
git clone https://github.com/seshadricloud/container.git
cd container

# Install dependencies
bash scripts/install-tools.sh

# Configure AWS
aws configure

# Setup Terraform
cd terraform
terraform init
```

## Code Standards

### Terraform
- Use `terraform fmt` for formatting
- Add descriptions to all variables
- Use meaningful resource names
- Tag all resources appropriately

### Kubernetes
- Use `kubectl apply --dry-run=client -o yaml` to validate
- Include resource requests/limits
- Use namespaces appropriately
- Add health checks to deployments

### Shell Scripts
- Use `shellcheck` for linting
- Add error handling
- Include logging
- Document complex logic

## Testing

```bash
# Terraform validation
terraform validate
terraform fmt -check

# Kubernetes validation
kubectl apply --dry-run=client -f kubernetes/

# Application tests
docker build -t app:test .
docker run app:test pytest tests/
```

## Pull Request Process

1. Update README.md if needed
2. Add tests for new features
3. Ensure all tests pass
4. Request review from maintainers
5. Address feedback
6. Squash commits if requested

## Commit Message Format

```
<type>: <subject>

<body>

<footer>

type: feat|fix|docs|style|refactor|test|chore
```

Example:
```
feat: add autoscaling policy

Implements horizontal pod autoscaling based on CPU and memory metrics.
Configurable thresholds and scaling limits.

Fixes #123
```

---

**Document Version**: 1.0  
**Last Updated**: June 2026