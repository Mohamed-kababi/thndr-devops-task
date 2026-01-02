#!/bin/bash
# push.sh - Push Docker image to Docker Hub

# Exit on error
set -e

# Variables
DOCKER_USERNAME=$1
IMAGE_TAG=$2

# Check if variables are provided
if [ -z "$DOCKER_USERNAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: ./push.sh <docker_username> <image_tag>"
    exit 1
fi

# Push the Docker image
echo "Pushing Docker image to Docker Hub..."
docker push $DOCKER_USERNAME/thndr-api:$IMAGE_TAG

# Also tag and push as latest
docker tag $DOCKER_USERNAME/thndr-api:$IMAGE_TAG $DOCKER_USERNAME/thndr-api:latest
docker push $DOCKER_USERNAME/thndr-api:latest

echo "Push completed successfully"
