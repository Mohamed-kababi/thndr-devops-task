#!/bin/bash
# trivy-scan.sh - Scan Docker image for vulnerabilities using Trivy

# Exit on error
set -e

# Variables
DOCKER_USERNAME=$1
IMAGE_TAG=$2

# Check if variables are provided
if [ -z "$DOCKER_USERNAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./trivy-scan.sh <docker_username> <image_tag>"
    exit 1
fi

IMAGE_NAME="$DOCKER_USERNAME/thndr-api:$IMAGE_TAG"

echo "Scanning Docker image: $IMAGE_NAME"

# Run Trivy scan on the Docker image
# Using --exit-code 0 to not fail the build on vulnerabilities (for demo purposes)
trivy image --severity HIGH,CRITICAL --exit-code 0 $IMAGE_NAME

echo "Trivy scan completed"
