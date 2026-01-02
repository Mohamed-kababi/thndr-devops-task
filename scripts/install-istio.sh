#!/bin/bash
# install-istio.sh - Install Istio on Kubernetes cluster

# Exit on error
set -e

echo "Downloading Istio..."
curl -L https://istio.io/downloadIstio | sh -

# Find the istio directory
ISTIO_DIR=$(ls -d istio-* | head -1)

echo "Installing Istio..."
cd $ISTIO_DIR
export PATH=$PWD/bin:$PATH

# Install Istio with default profile
istioctl install --set profile=default -y

echo "Verifying Istio installation..."
kubectl get pods -n istio-system

echo "Istio installed successfully!"
echo "To use istioctl, run: export PATH=$PWD/bin:\$PATH"
