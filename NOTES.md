# Project Notes and Documentation

## Project Overview

This project is a FastAPI application for deposit and withdraw operations, deployed on AWS EKS with a complete DevOps pipeline.

## Architecture

```
GitHub Repository (Private)
        |
        v
GitHub Actions (CI/CD)
        |
        +--> Build Docker Image
        |
        +--> Trivy Security Scan
        |
        +--> Push to Docker Hub
        |
        v
AWS EKS Cluster
        |
        +--> Istio Service Mesh
        |
        +--> NGINX Ingress Controller
        |
        +--> Application Pods
        |
        +--> Prometheus + Grafana (Monitoring)
```

## Project Structure

```
devops-task/
├── app/                    # Python FastAPI application
├── alembic/               # Database migrations
├── k8s/                   # Kubernetes manifests
│   ├── namespace.yaml     # Creates thndr-app namespace
│   ├── deployment.yaml    # Application deployment
│   ├── service.yaml       # ClusterIP service
│   └── ingress.yaml       # NGINX Ingress
├── istio/                 # Istio service mesh configs
│   ├── gateway.yaml       # Istio Gateway
│   ├── virtualservice.yaml # Traffic routing
│   ├── destinationrule.yaml # Traffic policies
│   └── peerauthentication.yaml # mTLS config
├── monitoring/            # Monitoring stack
│   ├── namespace.yaml     # monitoring namespace
│   ├── prometheus-config.yaml # Prometheus config
│   ├── prometheus-deployment.yaml # Prometheus
│   └── grafana-deployment.yaml # Grafana
├── scripts/               # Shell scripts for CI/CD
│   ├── build.sh          # Build Docker image
│   ├── push.sh           # Push to Docker Hub
│   ├── trivy-scan.sh     # Security scanning
│   ├── deploy.sh         # Deploy to K8s
│   ├── deploy-monitoring.sh # Deploy monitoring
│   └── test.sh           # Run tests
├── .github/workflows/     # GitHub Actions
│   └── ci-cd.yaml        # CI/CD pipeline
├── Dockerfile            # Container image
└── NOTES.md              # This file
```

## Security Implementation

### 1. Secrets Management

**GitHub Secrets Used:**
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/token
- `AWS_ACCESS_KEY_ID` - AWS access key for EKS
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (e.g., us-east-1)
- `EKS_CLUSTER_NAME` - Name of EKS cluster

**Kubernetes Secrets:**
For production, sensitive data should be stored in Kubernetes secrets:
```bash
kubectl create secret generic app-secrets \
  --from-literal=db-password=your-password \
  -n thndr-app
```

### 2. Docker Image Security Scanning

We use Trivy to scan Docker images for vulnerabilities:
- Scans for HIGH and CRITICAL vulnerabilities
- Runs after image is built and pushed
- Scans the Docker image from Docker Hub (not GitHub repo - avoids private repo issues)

**Why scan Docker image instead of GitHub repo:**
- Trivy requires paid subscription to scan private GitHub repos
- Scanning Docker image achieves the same security goal
- Catches vulnerabilities in base images and dependencies

### 3. Service Mesh Security (Istio)

**mTLS (Mutual TLS):**
- Enabled via PeerAuthentication with STRICT mode
- All service-to-service communication is encrypted
- Certificates managed automatically by Istio

**Traffic Policies:**
- DestinationRule configured for ISTIO_MUTUAL TLS
- All internal traffic encrypted by default

### 4. Network Security

- Application runs in dedicated namespace (thndr-app)
- ClusterIP service (not exposed directly)
- Traffic goes through Istio Gateway and NGINX Ingress

### 5. Container Security Best Practices

- Using slim Python base image
- Non-sensitive data only in image
- Dependencies pinned via poetry.lock
- Image tagged with commit SHA for traceability

## CI/CD Pipeline Explanation

### Pipeline Flow:
```
1. test    --> 2. build --> 3. security-scan --> 4. deploy
```

### Job Details:

**1. test:**
- Runs on every push and pull request
- Sets up Python 3.12
- Runs application tests

**2. build:**
- Only runs if tests pass
- Logs into Docker Hub
- Builds Docker image with commit SHA tag
- Pushes image to Docker Hub

**3. security-scan:**
- Only runs after successful build
- Installs Trivy scanner
- Pulls image from Docker Hub
- Scans for vulnerabilities

**4. deploy:**
- Only runs on main branch
- Only runs after security scan passes
- Configures AWS credentials
- Updates kubeconfig for EKS
- Deploys to Kubernetes cluster

## Monitoring Setup

### Prometheus
- Collects metrics from:
  - Kubernetes pods
  - Istio service mesh
  - Application endpoints
- Scrape interval: 15 seconds

### Grafana
- Visualization dashboard
- Default credentials: admin/admin123
- Access via port-forward:
  ```bash
  kubectl port-forward svc/grafana-service 3000:3000 -n monitoring
  ```

## Istio Service Mesh Features

### 1. Traffic Management
- Gateway handles incoming traffic
- VirtualService routes to application
- Supports canary deployments (weight-based routing)

### 2. Security
- mTLS enabled cluster-wide
- Automatic certificate rotation

### 3. Observability
- Distributed tracing (with Jaeger)
- Metrics collection (with Prometheus)
- Traffic visualization (with Kiali)

## Decisions Made

1. **Simple Kubernetes manifests instead of Helm templates:**
   - Easier to understand and modify
   - No template complexity
   - Direct YAML files

2. **Shell scripts for CI/CD operations:**
   - Reusable outside of GitHub Actions
   - Easier to test locally
   - Clear separation of concerns

3. **Trivy scans Docker images:**
   - Works with private GitHub repos
   - No subscription needed
   - Catches all vulnerabilities

4. **NGINX Ingress instead of AWS ALB:**
   - More portable across cloud providers
   - Works with Istio
   - Standard Kubernetes approach

5. **Istio for service mesh:**
   - Built-in mTLS
   - Traffic management
   - Observability features

## Future Improvements

- Add unit tests for API endpoints
- Implement proper database (PostgreSQL)
- Add horizontal pod autoscaler
- Set up Kiali for Istio visualization
- Add proper logging with ELK stack
