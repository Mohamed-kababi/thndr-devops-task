# Step-by-Step Deployment Guide

This guide explains how to deploy the Thndr DevOps Task project from scratch.

---

## Prerequisites

Before you start, make sure you have:
- Ubuntu terminal (local machine)
- AWS account with EKS cluster already created
- Docker Hub account
- GitHub account

---

## PART 1: Local Ubuntu Setup

### Step 1.1: Install Required Tools

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Git
sudo apt install -y git

# Install Docker
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Verify installations
docker --version
kubectl version --client
aws --version
git --version
```

**Explanation:**
- `docker.io` - Container runtime to build and run Docker images
- `kubectl` - Kubernetes command-line tool to manage clusters
- `aws cli` - Amazon Web Services command-line interface
- `git` - Version control system

### Step 1.2: Configure AWS CLI

```bash
aws configure
```

Enter when prompted:
- AWS Access Key ID: (your access key)
- AWS Secret Access Key: (your secret key)
- Default region: (e.g., us-east-1)
- Output format: json

**Explanation:**
This stores your AWS credentials in `~/.aws/credentials` so you can interact with AWS services.

### Step 1.3: Configure kubectl for EKS

```bash
# Update kubeconfig to connect to your EKS cluster
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION

# Test connection
kubectl get nodes
```

**Explanation:**
- `aws eks update-kubeconfig` downloads the cluster configuration and merges it into your local kubeconfig file (`~/.kube/config`)
- `kubectl get nodes` verifies you can connect to the cluster

### Step 1.4: Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password.

**Explanation:**
This stores your Docker Hub credentials locally so you can push images.

---

## PART 2: GitHub Repository Setup

### Step 2.1: Create Private GitHub Repository

1. Go to https://github.com/new
2. Name: `thndr-devops-task`
3. Select "Private"
4. Click "Create repository"

### Step 2.2: Clone and Push Project

```bash
# Navigate to your project folder
cd /path/to/devops-task

# Initialize git repository
git init

# Add remote origin
git remote add origin https://github.com/YOUR_USERNAME/thndr-devops-task.git

# Add all files
git add .

# Commit
git commit -m "Initial commit"

# Push to GitHub
git branch -M main
git push -u origin main
```

**Explanation:**
- `git init` creates a new Git repository
- `git remote add origin` links your local repo to GitHub
- `git push` uploads your code to GitHub

### Step 2.3: Configure GitHub Secrets

Go to your GitHub repository -> Settings -> Secrets and variables -> Actions

Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DOCKER_USERNAME` | your-dockerhub-username | Docker Hub username |
| `DOCKER_PASSWORD` | your-dockerhub-password | Docker Hub password or access token |
| `AWS_ACCESS_KEY_ID` | AKIA... | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | your-secret-key | AWS secret key |
| `AWS_REGION` | us-east-1 | Your AWS region |
| `EKS_CLUSTER_NAME` | your-cluster-name | Name of your EKS cluster |

**Explanation:**
GitHub Secrets store sensitive data securely. The CI/CD pipeline uses these to authenticate with Docker Hub and AWS.

---

## PART 3: AWS CloudShell - Install Istio and NGINX Ingress

### Step 3.1: Open AWS CloudShell

1. Log into AWS Console
2. Click the CloudShell icon (terminal icon) in the top navigation bar

### Step 3.2: Configure kubectl in CloudShell

```bash
# Update kubeconfig
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region YOUR_REGION

# Verify connection
kubectl get nodes
```

### Step 3.3: Install Istio

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -

# Move to Istio directory (version may vary)
cd istio-*

# Add istioctl to PATH
export PATH=$PWD/bin:$PATH

# Install Istio with default profile
istioctl install --set profile=default -y

# Verify Istio installation
kubectl get pods -n istio-system
```

**Explanation:**
- Downloads and installs Istio service mesh
- `profile=default` installs core components (istiod, ingress gateway)
- Istio runs in `istio-system` namespace

### Step 3.4: Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

**Explanation:**
- Deploys NGINX Ingress Controller in the cluster
- Creates a LoadBalancer service that gets an AWS ELB
- Handles incoming HTTP/HTTPS traffic

### Step 3.5: Get Ingress External IP

```bash
kubectl get svc -n ingress-nginx
```

Note the EXTERNAL-IP of the `ingress-nginx-controller` service. This is your application's entry point.

---

## PART 4: Deploy Monitoring Stack (CloudShell)

### Step 4.1: Clone Repository in CloudShell

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/thndr-devops-task.git
cd thndr-devops-task
```

### Step 4.2: Deploy Monitoring

```bash
# Make script executable
chmod +x scripts/deploy-monitoring.sh

# Deploy monitoring stack
./scripts/deploy-monitoring.sh
```

**Explanation:**
- Creates `monitoring` namespace
- Deploys Prometheus (metrics collection)
- Deploys Grafana (visualization)

### Step 4.3: Verify Monitoring

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

You should see prometheus and grafana pods running.

---

## PART 5: Manual Deployment (First Time)

If you want to deploy manually before CI/CD is working:

### Step 5.1: Build and Push Docker Image Locally

On your local Ubuntu machine:

```bash
cd /path/to/devops-task

# Build image
docker build -t YOUR_DOCKERHUB_USERNAME/thndr-api:v1 .

# Push to Docker Hub
docker push YOUR_DOCKERHUB_USERNAME/thndr-api:v1
```

### Step 5.2: Update Deployment Image

Edit `k8s/deployment.yaml` and change:
```yaml
image: YOUR_DOCKERHUB_USERNAME/thndr-api:v1
```

Replace `YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username.

### Step 5.3: Deploy to Kubernetes

In AWS CloudShell:

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Apply Istio configurations
kubectl apply -f istio/gateway.yaml
kubectl apply -f istio/virtualservice.yaml
kubectl apply -f istio/destinationrule.yaml
kubectl apply -f istio/peerauthentication.yaml

# Check deployment status
kubectl get pods -n thndr-app
kubectl get svc -n thndr-app
kubectl get ingress -n thndr-app
```

---

## PART 6: Trigger CI/CD Pipeline

### Step 6.1: Make a Change and Push

On your local Ubuntu machine:

```bash
cd /path/to/devops-task

# Make any small change (e.g., update README)
echo "# Updated" >> README.md

# Commit and push
git add .
git commit -m "Trigger CI/CD pipeline"
git push origin main
```

### Step 6.2: Watch Pipeline Execute

1. Go to your GitHub repository
2. Click "Actions" tab
3. Watch the pipeline run:
   - test -> build -> security-scan -> deploy

### Step 6.3: Verify Deployment

In AWS CloudShell:

```bash
# Check if new pods are running
kubectl get pods -n thndr-app

# Check deployment status
kubectl rollout status deployment/thndr-api -n thndr-app
```

---

## PART 7: Testing the Application

### Step 7.1: Get Application URL

```bash
# Get Istio Ingress Gateway IP
kubectl get svc istio-ingressgateway -n istio-system

# Or get NGINX Ingress IP
kubectl get svc -n ingress-nginx
```

### Step 7.2: Test Endpoints

```bash
# Test root endpoint
curl http://EXTERNAL_IP/ -H "user_id: 1"

# Test deposit endpoint (after implementing)
curl -X POST http://EXTERNAL_IP/deposit \
  -H "user_id: 1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}'

# Test withdraw endpoint (after implementing)
curl -X POST http://EXTERNAL_IP/withdraw \
  -H "user_id: 1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 50}'
```

---

## PART 8: Access Monitoring Dashboards

### Step 8.1: Access Grafana

```bash
# Port forward Grafana (run in CloudShell or local machine with kubectl configured)
kubectl port-forward svc/grafana-service 3000:3000 -n monitoring
```

Open browser: http://localhost:3000
- Username: admin
- Password: admin123

### Step 8.2: Access Prometheus

```bash
kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring
```

Open browser: http://localhost:9090

---

## File Explanations

### Dockerfile

```dockerfile
FROM python:3.12-slim          # Base image with Python 3.12
WORKDIR /app                   # Set working directory inside container
RUN apt-get update...          # Install system dependencies
RUN pip install poetry         # Install poetry package manager
COPY pyproject.toml...         # Copy dependency files
RUN poetry install...          # Install Python dependencies
COPY . .                       # Copy application code
ENV PYTHONPATH=/app            # Set Python path
EXPOSE 8000                    # Document that container listens on port 8000
CMD ["sh", "-c", "..."]        # Run migrations and start server
```

### k8s/namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: thndr-app              # Creates isolated namespace for our app
  labels:
    istio-injection: enabled   # Tells Istio to inject sidecar proxies
```

### k8s/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thndr-api              # Name of the deployment
  namespace: thndr-app         # Which namespace to deploy in
spec:
  replicas: 2                  # Run 2 copies of the application
  selector:
    matchLabels:
      app: thndr-api           # How to find pods belonging to this deployment
  template:
    spec:
      containers:
        - name: thndr-api
          image: ...           # Docker image to use
          ports:
            - containerPort: 8000    # Port the app listens on
          resources:
            requests:          # Minimum resources needed
              memory: "128Mi"
              cpu: "100m"
            limits:            # Maximum resources allowed
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:       # Checks if app is alive
            httpGet:
              path: /
              port: 8000
          readinessProbe:      # Checks if app is ready for traffic
            httpGet:
              path: /
              port: 8000
```

### k8s/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: thndr-api-service      # Name other services use to connect
  namespace: thndr-app
spec:
  type: ClusterIP              # Only accessible within cluster
  ports:
    - port: 80                 # Port the service listens on
      targetPort: 8000         # Port to forward to (container port)
  selector:
    app: thndr-api             # Which pods to send traffic to
```

### k8s/ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: thndr-api-ingress
  annotations:
    kubernetes.io/ingress.class: nginx    # Use NGINX ingress controller
spec:
  rules:
    - host: thndr-api.local    # Hostname (for local testing)
      http:
        paths:
          - path: /            # Route all paths
            pathType: Prefix
            backend:
              service:
                name: thndr-api-service   # Send to this service
                port:
                  number: 80
```

### istio/gateway.yaml

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: thndr-gateway
spec:
  selector:
    istio: ingressgateway      # Use Istio's ingress gateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "*"                  # Accept traffic for any hostname
```

### istio/virtualservice.yaml

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: thndr-virtualservice
spec:
  hosts:
    - "*"
  gateways:
    - thndr-gateway            # Use our gateway
  http:
    - route:
        - destination:
            host: thndr-api-service   # Route to our service
            port:
              number: 80
          weight: 100          # 100% of traffic (can split for canary)
```

### istio/peerauthentication.yaml

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: thndr-mtls
  namespace: thndr-app
spec:
  mtls:
    mode: STRICT               # Require mTLS for all traffic in namespace
```

### .github/workflows/ci-cd.yaml

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]           # Run on push to main
  pull_request:
    branches: [main]           # Run on PRs to main

jobs:
  test:                        # Job 1: Run tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3       # Get code
      - uses: actions/setup-python@v4   # Install Python
      - run: ./scripts/test.sh          # Run tests

  build:                       # Job 2: Build and push image
    needs: test                # Only run if tests pass
    steps:
      - uses: docker/login-action@v2    # Login to Docker Hub
      - run: ./scripts/build.sh         # Build image
      - run: ./scripts/push.sh          # Push image

  security-scan:               # Job 3: Scan for vulnerabilities
    needs: build
    steps:
      - run: ./scripts/trivy-scan.sh    # Scan Docker image

  deploy:                      # Job 4: Deploy to Kubernetes
    needs: security-scan
    if: github.ref == 'refs/heads/main' # Only on main branch
    steps:
      - uses: aws-actions/configure-aws-credentials@v2  # AWS auth
      - run: aws eks update-kubeconfig...   # Get cluster config
      - run: ./scripts/deploy.sh            # Deploy to K8s
```

---

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n thndr-app

# Check pod logs
kubectl logs <pod-name> -n thndr-app

# Describe pod for events
kubectl describe pod <pod-name> -n thndr-app
```

### Image pull errors

```bash
# Check if image exists on Docker Hub
docker pull YOUR_USERNAME/thndr-api:latest

# Create image pull secret if needed
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  -n thndr-app
```

### Istio issues

```bash
# Check Istio status
istioctl analyze -n thndr-app

# Check if sidecar is injected
kubectl get pods -n thndr-app -o jsonpath='{.items[*].spec.containers[*].name}'
```

---

## Quick Reference Commands

```bash
# View all resources in namespace
kubectl get all -n thndr-app

# View logs
kubectl logs -f deployment/thndr-api -n thndr-app

# Restart deployment
kubectl rollout restart deployment/thndr-api -n thndr-app

# Scale deployment
kubectl scale deployment/thndr-api --replicas=3 -n thndr-app

# Delete and recreate
kubectl delete -f k8s/ && kubectl apply -f k8s/

# Port forward for local testing
kubectl port-forward svc/thndr-api-service 8000:80 -n thndr-app
```
