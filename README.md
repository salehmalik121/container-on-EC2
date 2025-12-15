# Automated EC2 Deployment with Docker and AWS ECR

## Project Overview

This project demonstrates a **fully automated CI/CD pipeline** for deploying a Node.js server on AWS EC2 using **Docker containers** and **AWS services**. The workflow builds, pushes, and deploys the container image without manual intervention, showcasing DevOps automation skills with GitHub Actions and AWS.

It also serves as a learning resource for anyone wanting to understand **containerization, CI/CD, AWS ECR, EC2, and SSM automation**.

---

## Features

* **CI/CD Automation:** GitHub Actions pipeline builds, tags, and pushes Docker images automatically on `main` branch push.
* **Docker Containerization:** Dockerized Node.js server for consistent environments.
* **AWS ECR Integration:** Private Docker registry on AWS, including automated authentication.
* **EC2 Deployment via SSM:** Secure, zero-touch deployment using AWS Systems Manager Session Manager.
* **Container Lifecycle Management:** Automatically checks for running containers, stops/removes them, and runs the new image.
* **Error Handling & Environment Setup:** Installs necessary tools like Session Manager plugin if missing.

---

## Tech Stack

* **GitHub Actions** – CI/CD automation
* **Docker** – Containerization
* **AWS ECR** – Container registry
* **AWS EC2** – Server for deployment
* **AWS SSM** – Remote execution without SSH
* **Bash scripting** – Automation and command orchestration
* **Node.js** – Server application

---

## Project Structure

```
.
├── .github/workflows/
│   └── deploy.yml        
├── Dockerfile            
├── app/                  
│   └── index.js
├── README.md             
```

---

## Prerequisites

1. **AWS Account** with permissions for:

   * ECR (AmazonEC2ContainerRegistryFullAccess)
   * EC2 instance with SSM access (AmazonSSMManagedInstanceCore)
2. **GitHub Repository** with secrets set:

   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`
3. **Node.js project** ready for containerization.
4. Docker installed locally for building/testing images.

---

## Setup Instructions

### 1. Dockerize the Node.js App

Create a `Dockerfile` in your project root:

```dockerfile
FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3001
CMD ["node", "index.js"]
```

### 2. Configure GitHub Actions

Add workflow in `.github/workflows/deploy.yml`:

```yaml
name: "EC2 Server Update"

on:
  push:
    branches: "main"

jobs:
  buildImage:
    name: "Build & Deploy Node.js Server"
    runs-on: ubuntu-latest
    environment: secrets
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Build Docker Image
        run: |
          docker build -t learning/minimal-node-server .
          docker images

      - name: Push Image to AWS ECR
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 007572786776.dkr.ecr.us-east-1.amazonaws.com
          docker tag learning/minimal-node-server:latest 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest
          docker push 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest
          echo "Container Image Pushed to ECR"

      - name: Deploy on EC2 via SSM
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: "us-east-1"
        run: |
          # Install Session Manager Plugin if not installed
          if ! command -v session-manager-plugin >/dev/null; then
            echo "Installing Session Manager Plugin..."
            curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
            sudo dpkg -i session-manager-plugin.deb
          fi

          # Deploy Container via SSM
          aws ssm send-command \
            --document-name "AWS-RunShellScript" \
            --targets "Key=InstanceIds,Values=i-016e18ffc42a90e46" \
            --comment "Deploy minimal-node-server" \
            --parameters 'commands=[
              "if docker ps | grep -q minimal-node-server; then echo minimal node server running; docker rm $(docker kill $(docker ps -q -f name=minimal-server-container)); fi",
              "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 007572786776.dkr.ecr.us-east-1.amazonaws.com",
              "docker pull 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest",
              "docker run -d -p 80:3001 --name minimal-server-container 007572786776.dkr.ecr.us-east-1.amazonaws.com/learning/minimal-node-server:latest"
            ]'
```

---

## How it Works

1. **Push to Main Branch:** Triggers GitHub Actions workflow.
2. **Docker Build:** Builds Node.js container image locally.
3. **Push to ECR:** Tags and uploads image to AWS ECR.
4. **Deploy on EC2:**

   * Checks if a container is running and removes it.
   * Logs into ECR from EC2.
   * Pulls the latest image and starts it.
5. **Result:** EC2 is automatically updated with the latest containerized Node.js server.

---

## Learning Outcomes

* Understanding **Docker containerization** for Node.js apps.
* CI/CD workflow creation with **GitHub Actions**.
* Pushing and pulling images from **AWS ECR**.
* Remote execution on EC2 using **AWS SSM** without SSH.
* Automation of **container lifecycle** (stop/remove/start).
* Handling **dependencies and plugin installation** in a CI/CD pipeline.

---

## Next Steps / Improvements

* Add **health checks** to ensure container starts successfully.
* Implement **rollback strategy** if the new container fails.
* Extend to **multiple EC2 instances** for scalable deployment.
* Add **monitoring & logging** integration (CloudWatch).

---

## Author

Saleh Muhammad – Intermediate DevOps Engineer | Cloud & CI/CD Enthusiast

* [LinkedIn](#https://github.com/salehmalik121)
