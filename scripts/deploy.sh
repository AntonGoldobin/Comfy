#!/bin/bash
set -e

echo "=== ComfyUI RunPod Serverless Deployment ==="

# Check prerequisites
if ! command -v runpod &> /dev/null; then
    echo "Error: 'runpod' CLI not found. Install with: pip install runpod"
    exit 1
fi

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Validate required env vars
required_vars=(RUNPOD_API_KEY S3_BUCKET S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set"
        exit 1
    fi
done

echo "Building Docker image..."
docker build -f Dockerfile.serverless -t comfyui-runpod:latest .

echo "Pushing to GHCR (GitHub Container Registry)..."
# Note: You need to push to a container registry that RunPod can pull from
IMAGE_TAG="ghcr.io/YOUR_GITHUB_USERNAME/comfy-runpod:latest"
docker tag comfyui-runpod:latest $IMAGE_TAG
docker push $IMAGE_TAG

echo ""
echo "Creating RunPod endpoint..."
echo "IMPORTANT: Create endpoint manually at https://runpod.io/console/serverless"
echo "Or use: runpod endpoint create"
echo ""
echo "Or update existing endpoint:"
echo "  runpod endpoint update ENDPOINT_ID ."
echo ""
echo "Required endpoint config:"
echo "  - Docker image: $IMAGE_TAG"
echo "  - GPU: NVIDIA RTX 4090"
echo "  - Container disk: 50GB"
echo "  - Volume disk: 100GB"
echo "  - Environment variables:"
echo "    - S3_BUCKET=$S3_BUCKET"
echo "    - S3_ACCESS_KEY_ID=***"
echo "    - S3_SECRET_ACCESS_KEY=***"
echo ""
echo "After deployment, update /Volumes/SSDNSKIY/VSCODE/reelant/.env with:"
echo "  RUNPOD_ENDPOINT_ID=<your_endpoint_id>"
