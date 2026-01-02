#!/bin/bash
# build.sh - Build Docker image for thndr-api

# Exit on error
set -e

# Variables
DOCKER_USERNAME=$1
IMAGE_TAG=$2

# Check if variables are provided
if [ -z "$DOCKER_USERNAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./build.sh <docker_username> <image_tag>"
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t $DOCKER_USERNAME/thndr-api:$IMAGE_TAG .

echo "Build completed: $DOCKER_USERNAME/thndr-api:$IMAGE_TAG"
