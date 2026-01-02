#!/bin/bash
# deploy-monitoring.sh - Deploy monitoring stack to Kubernetes

# Exit on error
set -e

echo "Deploying monitoring stack..."

# Apply monitoring namespace
echo "Creating monitoring namespace..."
kubectl apply -f monitoring/namespace.yaml

# Apply Prometheus config
echo "Deploying Prometheus..."
kubectl apply -f monitoring/prometheus-config.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml

# Apply Grafana
echo "Deploying Grafana..."
kubectl apply -f monitoring/grafana-deployment.yaml

echo "Monitoring stack deployed successfully!"

# Show deployment status
kubectl get pods -n monitoring
kubectl get services -n monitoring

echo ""
echo "To access Grafana, run:"
echo "kubectl port-forward svc/grafana-service 3000:3000 -n monitoring"
echo "Then open http://localhost:3000 (admin/admin123)"
