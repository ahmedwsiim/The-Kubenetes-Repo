#!/usr/bin/env bash
# Build and push the app image to Docker Hub.
# Usage: ./build_and_push.sh <dockerhub-username> [tag]
set -euo pipefail

USERNAME="${1:?Usage: ./build_and_push.sh <dockerhub-username> [tag]}"
TAG="${2:-1.0}"

IMAGE="${USERNAME}/myapp:${TAG}"

echo ">> Building ${IMAGE}"
docker build -t "${IMAGE}" .

echo ">> Pushing ${IMAGE}"
docker push "${IMAGE}"

echo ""
echo "Done. Now edit 01-app-deploy.yaml and set:"
echo "  image: ${IMAGE}"
