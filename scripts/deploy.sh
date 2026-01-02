#!/bin/bash
# deploy.sh - Deploy application to Kubernetes

set -e

# Variables
DOCKER_USERNAME=$1
IMAGE_TAG=$2
USE_HELM=${3:-false}
FULL_IMAGE="$DOCKER_USERNAME/thndr-api:$IMAGE_TAG"

if [ -z "$DOCKER_USERNAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./deploy.sh <docker_username> <image_tag> [use_helm]"
    exit 1
fi

echo "Starting deployment to Kubernetes..."
echo "Image: $FULL_IMAGE"

# Function to install Istio
install_istio() {
    echo "Installing Istio..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.24.0 sh -

    # Install Istio in background and wait with timeout
    ./istio-1.24.0/bin/istioctl install --set profile=minimal -y --readiness-timeout 10m0s || {
        echo "WARNING: Istio installation timed out, continuing..."
        echo "Istiod may still be starting in background"
    }
}

if [ "$USE_HELM" = "true" ]; then
    echo "Deploying with Helm..."

    # Replace image in Helm template
    sed -i "s|image:.*|image: $FULL_IMAGE|g" helm/thndr-api/templates/deployment.yaml

    helm upgrade --install thndr-api ./helm/thndr-api \
        --namespace thndr-app \
        --create-namespace

    echo "Helm deployment completed!"
else
    echo "Deploying with kubectl..."

    # Replace image in deployment yaml
    sed -i "s|image:.*|image: $FULL_IMAGE|g" k8s/deployment.yaml

    # Show what we're deploying
    echo "Deployment image:"
    grep "image:" k8s/deployment.yaml

    # Apply Kubernetes manifests
    echo "Applying namespace..."
    kubectl apply -f k8s/namespace.yaml

    # Delete old deployments to avoid rolling update issues
    echo "Recreating deployments..."
    kubectl delete deployment thndr-api -n thndr-app --ignore-not-found=true
    kubectl delete deployment thndr-api-canary -n thndr-app --ignore-not-found=true

    # Deploy stable version (v1)
    echo "Deploying stable version..."
    kubectl apply -f k8s/deployment.yaml

    # Deploy canary version (v2)
    echo "Deploying canary version..."
    sed -i "s|image:.*|image: $FULL_IMAGE|g" k8s/deployment-canary.yaml
    kubectl apply -f k8s/deployment-canary.yaml

    echo "Applying service..."
    kubectl apply -f k8s/service.yaml

    echo "Applying ingress..."
    kubectl apply -f k8s/ingress.yaml

    # Wait for app deployments to be ready
    echo "Waiting for stable deployment..."
    kubectl rollout status deployment/thndr-api -n thndr-app --timeout=180s
    echo "Waiting for canary deployment..."
    kubectl rollout status deployment/thndr-api-canary -n thndr-app --timeout=180s

    # Install Istio if not already installed
    if ! kubectl get namespace istio-system &>/dev/null; then
        install_istio
    elif ! kubectl get deployment istiod -n istio-system &>/dev/null; then
        install_istio
    else
        echo "Istio already installed, checking status..."
        kubectl wait --for=condition=available --timeout=60s deployment/istiod -n istio-system || install_istio
    fi

    # Apply Istio configurations (may fail if Istio not ready yet)
    echo "Applying Istio resources..."
    kubectl apply -f istio/gateway.yaml || echo "WARNING: gateway not applied"
    kubectl apply -f istio/virtualservice.yaml || echo "WARNING: virtualservice not applied"
    kubectl apply -f istio/destinationrule.yaml || echo "WARNING: destinationrule not applied"
    kubectl apply -f istio/peerauthentication.yaml || echo "WARNING: peerauthentication not applied"

    # Deploy monitoring stack (Prometheus & Grafana)
    echo "Deploying monitoring stack..."
    kubectl apply -f monitoring/namespace.yaml || echo "WARNING: monitoring namespace not applied"
    kubectl apply -f monitoring/prometheus-config.yaml || echo "WARNING: prometheus config not applied"
    kubectl apply -f monitoring/prometheus-deployment.yaml || echo "WARNING: prometheus not applied"
    kubectl apply -f monitoring/grafana-deployment.yaml || echo "WARNING: grafana not applied"

    echo "Deployment completed!"
fi

# Show status
echo ""
echo "=== Deployment Status ==="
echo "App Pods:"
kubectl get pods -n thndr-app
echo ""
echo "App Services:"
kubectl get services -n thndr-app
echo ""
echo "Canary Traffic Split: 90% stable (v1) / 10% canary (v2)"
echo ""
echo "Monitoring Pods:"
kubectl get pods -n monitoring 2>/dev/null || echo "Monitoring namespace not ready"
