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
    ./istio-1.24.0/bin/istioctl install --set profile=minimal -y --readiness-timeout 15m0s

    echo "Waiting for Istiod..."
    kubectl wait --for=condition=available --timeout=900s deployment/istiod -n istio-system
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

    echo "Applying deployment..."
    kubectl apply -f k8s/deployment.yaml

    echo "Applying service..."
    kubectl apply -f k8s/service.yaml

    echo "Applying ingress..."
    kubectl apply -f k8s/ingress.yaml

    # Wait for app deployment to be ready
    echo "Waiting for app deployment..."
    kubectl rollout status deployment/thndr-api -n thndr-app --timeout=300s

    # Install Istio if not already installed
    if ! kubectl get namespace istio-system &>/dev/null; then
        install_istio
    elif ! kubectl get deployment istiod -n istio-system &>/dev/null; then
        install_istio
    else
        echo "Istio already installed, checking status..."
        kubectl wait --for=condition=available --timeout=60s deployment/istiod -n istio-system || install_istio
    fi

    # Apply Istio configurations
    echo "Applying Istio resources..."
    kubectl apply -f istio/gateway.yaml
    kubectl apply -f istio/virtualservice.yaml
    kubectl apply -f istio/destinationrule.yaml
    kubectl apply -f istio/peerauthentication.yaml

    echo "Deployment completed!"
fi

# Show status
echo ""
echo "=== Deployment Status ==="
kubectl get pods -n thndr-app
kubectl get services -n thndr-app
