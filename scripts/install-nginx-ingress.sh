#!/bin/bash
# install-nginx-ingress.sh - Install NGINX Ingress Controller

# Exit on error
set -e

echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml

echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "NGINX Ingress Controller installed successfully!"
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
