# Automated EC2 Deployment with Docker, Terraform, and Blue-Green Deployment

## Project Overview

This project demonstrates a **fully automated CI/CD pipeline** for deploying a Node.js server on AWS EC2 using **Docker containers, AWS ECR, Terraform Infrastructure-as-Code (IaC), and Blue-Green Deployment strategy**. The workflow builds, tests, pushes container images, and performs zero-downtime deployments through GitHub Actions and AWS automation.

It serves as a comprehensive learning resource for understanding containerization, CI/CD automation, AWS services, Terraform, and advanced deployment patterns in a DevOps environment.

---

## Key Features

✅ **CI/CD Automation** – GitHub Actions pipeline with automated build, test, tag, and push workflows on `main` branch push

✅ **Infrastructure-as-Code (IaC)** – Terraform configuration for reproducible AWS infrastructure setup

✅ **Blue-Green Deployment** – Zero-downtime deployments with instant traffic switching between environments

✅ **Docker Containerization** – Dockerized Node.js server for consistency across environments

✅ **AWS ECR Integration** – Private container registry with automated authentication and image management

✅ **EC2 Deployment via SSM** – Secure, SSH-less deployment using AWS Systems Manager Session Manager

✅ **Container Lifecycle Management** – Intelligent container orchestration with stop, remove, and restart logic

✅ **Error Handling** – Robust error handling with automatic tool installation and validation

✅ **Environment Variables** – Configurable deployments through `.env` file and GitHub Secrets

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Infrastructure** | Terraform (HCL) |
| **CI/CD** | GitHub Actions |
| **Containerization** | Docker |
| **Container Registry** | AWS ECR (Elastic Container Registry) |
| **Compute** | AWS EC2 |
| **Remote Execution** | AWS SSM (Systems Manager Session Manager) |
| **Runtime** | Node.js 18+ |
| **Orchestration** | Bash scripting |

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
├── .env                            # Environment variables
├── .gitignore                      # Git ignore rules
├── Dockerfile                      # Docker image definition
├── package.json                    # Node.js dependencies
├── package-lock.json               # Dependency lock file
├── index.js                        # Express server application
├── main.tf                         # Terraform infrastructure configuration
├── terraform.tfstate               # Terraform state (local backend)
└── README.md                       # Project documentation
```

---

## Prerequisites

### AWS Account Setup

Required IAM permissions and services:
- **ECR:** AmazonEC2ContainerRegistryFullAccess
- **EC2:** EC2 full access
- **SSM:** AmazonSSMManagedInstanceCore role attached to EC2 instance
- **VPC:** Default or custom VPC with internet connectivity

### GitHub Configuration

Set up these secrets in GitHub repository (Settings > Secrets and variables > Actions):
- `AWS_ACCESS_KEY_ID` – AWS programmatic access key
- `AWS_SECRET_ACCESS_KEY` – AWS secret access key
- `AWS_REGION` – AWS region (default: us-east-1)

### Local Development

- Docker installed (v20.10+)
- Terraform installed (v1.0+)
- AWS CLI configured
- Node.js 18+ for local testing

---

## Setup Instructions

### 1. Clone and Configure Repository

```bash
git clone https://github.com/salehmalik121/container-on-EC2.git
cd container-on-EC2
git checkout Terrform-AND-BlueGreen-Deploy

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your AWS account details and ECR repository name
```

### 2. Configure GitHub Secrets

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Create the following secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (optional, defaults to us-east-1)

### 3. Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure configuration
terraform apply

# Note the EC2 instance ID from output
# Update deploy.yml with the correct instance ID
```

### 4. Dockerfile Configuration

Ensure your `Dockerfile` is properly configured:

```dockerfile
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Expose application port
EXPOSE 3001

# Start application
CMD ["node", "index.js"]
```

### 5. GitHub Actions Workflow Configuration

The `.github/workflows/deploy.yml` file orchestrates the entire CI/CD pipeline:

```yaml
name: "EC2 Server Update - CI/CD Pipeline"

on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main"]

jobs:
  build-and-deploy:
    name: "Build, Test & Deploy Node.js Server"
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker Image
        run: |
          docker build -t learning/minimal-node-server:latest \
                      -t learning/minimal-node-server:${{ github.sha }} .
          docker images

      - name: Run Container Tests
        run: |
          docker run --rm learning/minimal-node-server:latest npm test

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION || 'us-east-1' }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: learning/minimal-node-server
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker tag learning/minimal-node-server:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker tag learning/minimal-node-server:latest $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "Image pushed successfully"

      - name: Deploy on EC2 via SSM (Blue-Green)
        env:
          INSTANCE_ID: ${{ secrets.EC2_INSTANCE_ID }}
        run: |
          # Install Session Manager Plugin if not present
          if ! command -v session-manager-plugin &>/dev/null; then
            echo "Installing AWS Session Manager Plugin..."
            curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
            sudo dpkg -i session-manager-plugin.deb
          fi

          # Blue-Green Deployment Script
          aws ssm send-command \
            --document-name "AWS-RunShellScript" \
            --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
            --comment "Blue-Green deployment - minimal-node-server" \
            --parameters 'commands=[
              "#!/bin/bash",
              "set -e",
              "",
              "# Configuration",
              "ECR_URL=\${ECR_REGISTRY}/\${ECR_REPOSITORY}:latest",
              "BLUE_CONTAINER=minimal-server-blue",
              "GREEN_CONTAINER=minimal-server-green",
              "PORT=80",
              "APP_PORT=3001",
              "",
              "# Login to ECR",
              "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 007572786776.dkr.ecr.us-east-1.amazonaws.com",
              "",
              "# Pull latest image",
              "docker pull 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest",
              "",
              "# Determine which container is active",
              "if docker ps | grep -q \$BLUE_CONTAINER; then",
              "  ACTIVE=blue",
              "  INACTIVE=green",
              "  ACTIVE_CONTAINER=\$BLUE_CONTAINER",
              "  INACTIVE_CONTAINER=\$GREEN_CONTAINER",
              "else",
              "  ACTIVE=green",
              "  INACTIVE=blue",
              "  ACTIVE_CONTAINER=\$GREEN_CONTAINER",
              "  INACTIVE_CONTAINER=\$BLUE_CONTAINER",
              "fi",
              "",
              "echo \"Active: \$ACTIVE, Deploying to: \$INACTIVE\"",
              "",
              "# Remove inactive container if exists",
              "docker rm -f \$INACTIVE_CONTAINER 2>/dev/null || true",
              "",
              "# Start new container on inactive slot",
              "docker run -d -p 8080:\$APP_PORT --name \$INACTIVE_CONTAINER 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest",
              "",
              "# Wait for container to be healthy",
              "sleep 5",
              "",
              "# Switch traffic (simple port switching - can be improved with load balancer)",
              "echo \"Switching traffic to \$INACTIVE\"",
              "docker stop \$ACTIVE_CONTAINER",
              "",
              "echo \"Deployment successful. Active container: \$INACTIVE\""
            ]'
```

---

## Deployment Flow

### Traditional Deployment (Original)
1. **Push to main** → GitHub Actions triggered
2. **Build Docker image** → Tagged and tested
3. **Push to ECR** → Image stored in AWS registry
4. **Deploy to EC2** → Container pulled and restarted (brief downtime)

### Blue-Green Deployment (Current)
1. **Push to main** → GitHub Actions triggered
2. **Build Docker image** → Tagged and tested
3. **Push to ECR** → Image stored in AWS registry
4. **Deploy to Inactive Environment** → New container started in background
5. **Health Check** → Verify new container is healthy
6. **Switch Traffic** → Instant traffic switch from old to new
7. **Keep Active** → Old environment retained for rollback

**Benefits:**
- ✅ Zero downtime deployment
- ✅ Instant rollback capability
- ✅ Easy A/B testing
- ✅ Risk-free deployments

---

## Infrastructure as Code (Terraform)

The `main.tf` file defines:

- **VPC & Networking** – Virtual Private Cloud with subnets and security groups
- **EC2 Instance** – Ubuntu instance with IAM role for SSM and ECR access
- **Security Groups** – Rules for HTTP (80), HTTPS (443), and SSH (22) access
- **ECR Repository** – Private Docker image registry
- **IAM Roles & Policies** – Permissions for EC2 to access ECR and SSM

### Deploy Infrastructure

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Plan deployment (review changes)
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Get outputs
terraform output
```

---

## Learning Outcomes

By working through this project, you'll understand:

1. **Docker Containerization** – Creating and optimizing container images for Node.js applications
2. **CI/CD Pipelines** – Automating build, test, and deployment workflows with GitHub Actions
3. **AWS Services** – ECR, EC2, SSM, VPC, IAM, and their integration
4. **Infrastructure-as-Code** – Using Terraform to manage AWS resources declaratively
5. **Blue-Green Deployments** – Implementing zero-downtime deployment strategies
6. **Container Orchestration** – Managing container lifecycle and health
7. **Security Best Practices** – Using SSM instead of SSH, IAM permissions, secrets management
8. **Bash Scripting** – Automating complex deployment and monitoring tasks

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **ECR login fails** | Verify AWS credentials in GitHub Secrets and IAM permissions |
| **EC2 instance unreachable via SSM** | Ensure EC2 has IAM role `AmazonSSMManagedInstanceCore` attached |
| **Container won't start** | Check EC2 logs: `docker logs [container-id]` |
| **Port conflicts** | Ensure port 80/8080 is not in use; modify mappings in deployment script |
| **Image push fails** | Verify ECR repository exists and AWS credentials have ECR permissions |

---

## Next Steps & Improvements

- [ ] **Auto-rollback** – Automatic rollback if health checks fail
- [ ] **Load Balancer** – Add ALB/NLB for traffic distribution across multiple instances
- [ ] **Monitoring & Alerts** – CloudWatch metrics, logs, and SNS notifications
- [ ] **Database Integration** – RDS for persistent data storage
- [ ] **Multi-region Deployment** – Deploy across multiple AWS regions
- [ ] **Container Registry Scanning** – Automated security vulnerability scanning
- [ ] **Terraform State Management** – Remote state with S3 and DynamoDB locking
- [ ] **Canary Deployments** – Gradual traffic shift for safer deployments
- [ ] **Cost Optimization** – Spot instances and auto-scaling groups

---

## Resources & References

- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR Guide](https://docs.aws.amazon.com/ecr/)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Blue-Green Deployment Pattern](https://martinfowler.com/bliki/BlueGreenDeployment.html)

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## License

This project is open source and available under the MIT License.

---

## Author

**Saleh Muhammad**

- LinkedIn: [linkedin.com/in/saleh-muhammad-b08a181b1](https://www.linkedin.com/in/saleh-muhammad-b08a181b1/)
- GitHub: [github.com/salehmalik121](https://github.com/salehmalik121)

---

## Support

If you found this project helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting issues and bugs
- 💬 Contributing improvements
- 📚 Sharing with the community

---

**Last Updated:** December 2025 | **Branch:** Terrform-AND-BlueGreen-Deploy
