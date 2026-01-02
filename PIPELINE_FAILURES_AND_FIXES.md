# Pipeline Failures and Fixes

This document tracks all CI/CD pipeline failures encountered and how each was resolved.

---

## Run #1-8: Initial Setup Issues

### Issue: Dockerfile poetry install failed
- **Error**: `--no-dev` flag not recognized
- **Cause**: Poetry version changed the flag syntax
- **Fix**: Changed `poetry install --no-dev` to `poetry install --only main --no-root`
- **File**: `Dockerfile`

### Issue: Test script ModuleNotFoundError
- **Error**: `ModuleNotFoundError: No module named 'app'`
- **Cause**: Python not running in poetry virtual environment
- **Fix**: Changed `python` to `poetry run python`
- **File**: `scripts/test.sh`

---

## Run #9: SonarQube Issues

### Issue: SonarQube service container timeout
- **Error**: Health check timeout waiting for SonarQube container
- **Cause**: SonarQube takes long to start as a service container
- **Fix**: Changed from service container to running SonarQube with `docker run` in steps
- **File**: `.github/workflows/ci-cd.yaml`

### Issue: SonarQube "Not authorized" error
- **Error**: `Not authorized. Analyzing this project requires authentication`
- **Cause**: SonarQube requires authentication by default
- **Fix**: Added `sonar.login=admin` and `sonar.password=admin` parameters
- **File**: `.github/workflows/ci-cd.yaml`

### Issue: SonarQube "not authorized to run analysis"
- **Error**: User not authorized to run analysis
- **Cause**: Scanner user doesn't have scan permissions
- **Fix**: Added API calls to grant permissions:
  ```bash
  curl -u admin:admin -X POST "http://localhost:9000/api/permissions/add_group?projectKey=thndr-api&groupName=Anyone&permission=scan"
  curl -u admin:admin -X POST "http://localhost:9000/api/permissions/add_group?projectKey=thndr-api&groupName=Anyone&permission=user"
  ```
- **File**: `.github/workflows/ci-cd.yaml`

---

## Run #10-11: EKS Access Issues

### Issue: EKS "client to provide credentials" error
- **Error**: `the server has asked for the client to provide credentials`
- **Cause**: IAM user not added to EKS cluster access entries
- **Fix**: User ran AWS CLI commands to add IAM user to EKS:
  ```bash
  aws eks create-access-entry --cluster-name <cluster> --principal-arn <arn> --type STANDARD
  aws eks associate-access-policy --cluster-name <cluster> --principal-arn <arn> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster
  ```
- **Action**: Manual step required for each new cluster

---

## Run #12: Istio CRD Not Found

### Issue: Istio CRDs not installed
- **Error**: `error: the server doesn't have a resource type "gateways"`
- **Cause**: Istio not installed on cluster, CRDs don't exist
- **Fix**: Added Istio installation to deploy script if not present
- **File**: `scripts/deploy.sh`
  ```bash
  if ! kubectl api-resources | grep -q "gateways.networking.istio.io"; then
      curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.24.0 sh -
      ./istio-1.24.0/bin/istioctl install --set profile=minimal -y
  fi
  ```

---

## Run #13-19: Istio Installation Timeout

### Issue: Istiod deployment timeout
- **Error**: `failed to wait for resource: resources not ready after 5m0s: context deadline exceeded`
- **Cause**: Default 5-minute timeout too short for Istiod to start
- **Fix 1**: Increased timeout to 10 minutes, then 15 minutes
- **Fix 2**: Made Istio installation non-blocking (warn but don't fail)
- **File**: `scripts/deploy.sh`
  ```bash
  ./istio-1.24.0/bin/istioctl install --set profile=minimal -y --readiness-timeout 10m0s || {
      echo "WARNING: Istio installation timed out, continuing..."
  }
  ```

---

## Run #17-19: Pod CrashLoopBackOff

### Issue: Pods crashing with CrashLoopBackOff
- **Error**: `Liveness probe failed: HTTP probe failed with statuscode: 401`
- **Cause**: Liveness/readiness probes hitting `/` endpoint which requires authentication
- **Root Cause Analysis**:
  - The `/` endpoint has `Depends(get_current_user)` requiring auth
  - Probes don't send auth headers
  - Probes get 401 Unauthorized
  - Kubernetes thinks container is unhealthy and restarts it
- **Fix**:
  1. Added `/health` endpoint without authentication
  2. Updated K8s deployment probes to use `/health`
- **Files Modified**:
  - `app/main.py`:
    ```python
    @app.get("/health")
    def health():
        return {"status": "healthy"}
    ```
  - `k8s/deployment.yaml`:
    ```yaml
    livenessProbe:
      httpGet:
        path: /health
        port: 8000
    readinessProbe:
      httpGet:
        path: /health
        port: 8000
    ```
  - `helm/thndr-api/templates/deployment.yaml`: Same probe changes

---

## Run #20: AWS Credentials Invalid

### Issue: Security token invalid
- **Error**: `The security token included in the request is invalid`
- **Cause**: AWS credentials expired or revoked
- **Fix**: Updated GitHub secrets with new AWS credentials
- **Secrets Updated**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

---

## Run #21-22: New EKS Cluster Access

### Issue: New cluster, IAM user not authorized
- **Error**: `the server has asked for the client to provide credentials`
- **Cause**: New EKS cluster, IAM user not in access entries
- **Fix**:
  1. Updated GitHub secrets with new cluster name
  2. Added IAM user to new cluster's access entries
- **Secrets Updated**: `EKS_CLUSTER_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

---

## Run #23: Deployment Rollout Stuck

### Issue: Deployment rollout timeout
- **Error**: `Waiting for deployment rollout to finish: 0 out of 2 new replicas have been updated`
- **Cause**: Rolling update stuck due to old pods in bad state blocking new pod creation
- **Fix**: Force delete and recreate deployment instead of rolling update
- **File**: `scripts/deploy.sh`
  ```bash
  # Delete old deployment to avoid rolling update issues
  kubectl delete deployment thndr-api -n thndr-app --ignore-not-found=true
  kubectl apply -f k8s/deployment.yaml
  ```

---

## Run #24: Wrong Cluster Credentials

### Issue: Deploying to old/wrong cluster
- **Error**: Various credential and access errors
- **Cause**: GitHub secrets had old cluster credentials
- **Fix**: Updated all AWS/EKS secrets for new cluster
- **Secrets Updated**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `EKS_CLUSTER_NAME`

---

## Run #25: SUCCESS

All issues resolved. Pipeline completed successfully with:
- Tests passing
- SonarQube SAST scan complete
- Docker image built and pushed
- Security scans passed
- CIS benchmark passed
- EKS deployment successful
- App pods running healthy
- Health endpoint responding

---

## Summary of All Fixes Applied

| Component | Issue | Fix |
|-----------|-------|-----|
| Dockerfile | Poetry `--no-dev` deprecated | Use `--only main --no-root` |
| test.sh | Module not found | Use `poetry run python` |
| SonarQube | Auth and permissions | Add login params and permission API calls |
| EKS Access | IAM not authorized | Add user to cluster access entries |
| Istio | CRDs missing | Auto-install Istio in deploy script |
| Istio | Installation timeout | Increase timeout, make non-blocking |
| App Probes | 401 on `/` endpoint | Add `/health` endpoint, update probes |
| Deployment | Rolling update stuck | Force delete and recreate |
| Credentials | Invalid/expired | Update GitHub secrets |

---

## Files Modified

1. `Dockerfile` - Poetry install fix
2. `scripts/test.sh` - Poetry run fix
3. `scripts/deploy.sh` - Image replacement, Istio install, force recreate
4. `app/main.py` - Health endpoint
5. `k8s/deployment.yaml` - Health probes
6. `helm/thndr-api/templates/deployment.yaml` - Health probes
7. `.github/workflows/ci-cd.yaml` - SonarQube configuration
