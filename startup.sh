#!/bin/bash
set -e

echo "=== ComfyUI RunPod Serverless Startup ==="

# ComfyUI needs to be running for the handler to submit workflows
# Start ComfyUI in background
echo "Starting ComfyUI..."
python main.py --listen 0.0.0.0 --port 8188 &
COMFYUI_PID=$!

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
for i in {1..60}; do
    if curl -sf http://localhost:8188/system_stats > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    if ! kill -0 $COMFYUI_PID 2>/dev/null; then
        echo "ComfyUI process died!"
        exit 1
    fi
    echo "Waiting... ($i/60)"
    sleep 2
done

# Start the RunPod Serverless handler (this blocks)
echo "Starting RunPod Serverless Worker..."
exec python runpod_handler.py
