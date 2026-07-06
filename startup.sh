#!/bin/bash
set -e

echo "Starting ComfyUI..."

# Load environment variables if .env exists
if [ -f .env ]; then
    echo "Loading environment from .env..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Build extra arguments
EXTRA_ARGS=""

if [ -n "$COMFYUI_API_KEY" ]; then
    echo "API key is set - ComfyUI will require authentication"
    # Note: ComfyUI doesn't have built-in API key auth in the standard image
    # If needed, use a reverse proxy with auth
fi

# Start docker-compose
echo "Starting container..."
docker compose up -d

echo ""
echo "Waiting for ComfyUI to be ready..."
sleep 5

# Follow logs
echo ""
echo "=== ComfyUI Startup Logs ==="
docker compose logs -f
