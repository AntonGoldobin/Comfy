#!/bin/bash
set -e

echo "=== ComfyUI RunPod Serverless Deployment ==="

# Check prerequisites
if ! command -v runpod &> /dev/null; then
    echo "Error: 'runpod' CLI not found. Install with: pip install runpod"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: 'docker' CLI not found. Install Docker first."
    exit 1
fi

# Get GitHub username from git config or prompt
GITHUB_USERNAME=${GITHUB_USERNAME:-$(git config user.name | tr '[:upper:]' '[:lower:]' | tr -d ' ' 2>/dev/null)}
if [ -z "$GITHUB_USERNAME" ]; then
    echo "Enter your GitHub username (for GHCR image path):"
    read -r GITHUB_USERNAME
fi

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Validate required env vars
required_vars=(RUNPOD_API_KEY S3_BUCKET S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

echo ""
echo "GitHub username: $GITHUB_USERNAME"
echo "S3 bucket: $S3_BUCKET"
echo ""

# Check if user is logged into GHCR
if ! docker ghcr.io | grep -q "ghcr.io"; then
    echo "Not logged into GHCR. Logging in..."
    echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin 2>/dev/null || \
    docker login ghcr.io -u "$GITHUB_USERNAME"
fi

IMAGE_TAG="ghcr.io/${GITHUB_USERNAME}/comfy-runpod:latest"

echo "Building Docker image..."
docker build -f Dockerfile.serverless -t comfyui-runpod:latest .

echo "Tagging image as $IMAGE_TAG..."
docker tag comfyui-runpod:latest $IMAGE_TAG

echo "Pushing to GHCR..."
docker push $IMAGE_TAG

echo ""
echo "=== Image pushed successfully ==="
echo "Image: $IMAGE_TAG"
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Create RunPod endpoint (if not already created):"
echo "   runpod endpoint create"
echo ""
echo "2. Or update existing endpoint:"
echo "   runpod endpoint update ENDPOINT_ID ."
echo ""
echo "3. Required endpoint configuration in RunPod dashboard:"
echo "   - Docker image: $IMAGE_TAG"
echo "   - GPU: NVIDIA RTX 4090"
echo "   - Container disk: 50GB"
echo "   - Volume disk: 100GB"
echo "   - Min vCPU: 2, Max vCPU: 4"
echo "   - Environment variables:"
echo "     S3_BUCKET=$S3_BUCKET"
echo "     S3_ACCESS_KEY_ID=***"
echo "     S3_SECRET_ACCESS_KEY=***"
echo "     S3_REGION=${S3_REGION:-us-east-1}"
echo "     COMFYUI_URL=http://localhost:8188"
echo "     PYTHONUNBUFFERED=1"
echo ""
echo "4. After getting ENDPOINT_ID, update Reelant .env:"
echo "   RUNPOD_ENDPOINT_ID=<your_endpoint_id>"
echo ""
echo "5. Test deployment:"
echo "   curl -X POST \"https://api.runpod.io/v1/\${RUNPOD_ENDPOINT_ID}/status\" \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -H 'Authorization: Bearer \${RUNPOD_API_KEY}' \\"
echo "     -d '{}'"
