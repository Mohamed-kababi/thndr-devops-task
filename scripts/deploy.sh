#!/bin/bash
# deploy.sh - Deploy application to Kubernetes

# Exit on error
set -e

# Variables
DOCKER_USERNAME=$1
IMAGE_TAG=$2
USE_HELM=${3:-false}

# Check if variables are provided
if [ -z "$DOCKER_USERNAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./deploy.sh <docker_username> <image_tag> [use_helm]"
    exit 1
fi

echo "Starting deployment to Kubernetes..."
echo "USE_HELM: $USE_HELM"

if [ "$USE_HELM" = "true" ]; then
    echo "Deploying with Helm..."

    # Update the deployment image in the Helm template
    sed -i "s|YOUR_DOCKERHUB_USERNAME|$DOCKER_USERNAME|g" helm/thndr-api/templates/deployment.yaml
    sed -i "s|:latest|:$IMAGE_TAG|g" helm/thndr-api/templates/deployment.yaml

    # Deploy using Helm chart
    helm upgrade --install thndr-api ./helm/thndr-api \
        --namespace thndr-app \
        --create-namespace

    echo "Helm deployment completed successfully!"
else
    echo "Deploying with kubectl..."

    # Update the deployment image in the YAML file
    sed -i "s|YOUR_DOCKERHUB_USERNAME|$DOCKER_USERNAME|g" k8s/deployment.yaml
    sed -i "s|:latest|:$IMAGE_TAG|g" k8s/deployment.yaml

    # Apply Kubernetes manifests
    echo "Applying namespace..."
    kubectl apply -f k8s/namespace.yaml

    echo "Applying deployment..."
    kubectl apply -f k8s/deployment.yaml

    echo "Applying service..."
    kubectl apply -f k8s/service.yaml

    echo "Applying ingress..."
    kubectl apply -f k8s/ingress.yaml

    # Apply Istio configurations
    echo "Applying Istio gateway..."
    kubectl apply -f istio/gateway.yaml

    echo "Applying Istio virtualservice..."
    kubectl apply -f istio/virtualservice.yaml

    echo "Applying Istio destinationrule..."
    kubectl apply -f istio/destinationrule.yaml

    echo "Applying Istio peerauthentication..."
    kubectl apply -f istio/peerauthentication.yaml

    echo "kubectl deployment completed successfully!"
fi

# Show deployment status
kubectl get pods -n thndr-app
kubectl get services -n thndr-app
