#!/bin/bash
set -euo pipefail

# Configuration
DOCKER_USER="${1:-nylh6}"
TAG="${2:-v1}"

echo "=================================================="
echo " Building & Pushing Docker Images"
echo " Docker Hub Username: ${DOCKER_USER}"
echo " Tag:                 ${TAG}"
echo "=================================================="

BACKEND_IMAGE="${DOCKER_USER}/cloud-backend:${TAG}"
FRONTEND_IMAGE="${DOCKER_USER}/cloud-frontend:${TAG}"

# Move to repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo ""
echo ">> Step 1: Building Backend Image: ${BACKEND_IMAGE}..."
docker build -f apps/api/Dockerfile -t "${BACKEND_IMAGE}" .

echo ""
echo ">> Step 2: Building Frontend Image: ${FRONTEND_IMAGE}..."
docker build -f apps/web/Dockerfile -t "${FRONTEND_IMAGE}" .

echo ""
echo ">> Step 3: Pushing Backend Image to Docker Hub..."
docker push "${BACKEND_IMAGE}"

echo ""
echo ">> Step 4: Pushing Frontend Image to Docker Hub..."
docker push "${FRONTEND_IMAGE}"

echo ""
echo "=================================================="
echo " Successfully pushed both images!"
echo " - Backend:  ${BACKEND_IMAGE}"
echo " - Frontend: ${FRONTEND_IMAGE}"
echo "=================================================="
