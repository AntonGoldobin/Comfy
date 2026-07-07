# ComfyUI RunPod Deployment Guide

## Overview

This guide covers deploying ComfyUI RunPod Serverless for Reelant AI video generation.

**Deployment Flow:**
1. `startup.sh` starts ComfyUI as a sidecar process
2. `startup.sh` waits for ComfyUI to be ready (via `/system_stats`)
3. `startup.sh` runs `handler.py`
4. `handler.py` starts `runpod.serverless.start()` with the handler function
5. Handler submits workflows to ComfyUI, polls for completion, uploads to S3

---

## Prerequisites

### Required Accounts
- [RunPod](https://runpod.io) account with GPU credits
- [AWS](https://aws.amazon.com) account with S3 bucket
- GitHub account with GHCR access (for container registry)

### CLI Tools
```bash
# RunPod CLI
pip install runpod

# Docker
docker --version

# AWS CLI (for S3)
pip install awscli
```

### Environment Setup
```bash
# Configure RunPod
runpod config

# Verify login
runpod whoami
```

---

## Step 1: Configure S3 Bucket

Run the S3 setup script:
```bash
cd /Volumes/SSDNSKIY/VSCODE/Comfy
./scripts/s3_setup.sh
```

Or manually:
```bash
# Create bucket
aws s3 mb s3://your-bucket-name --region us-east-1

# Configure CORS (required for signed URLs)
aws s3api put-bucket-cors --bucket your-bucket-name --cors-configuration '{
  "CORSRules": [{
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedHeaders": ["*"]
  }]
}'
```

---

## Step 2: Configure Environment Variables

```bash
cd /Volumes/SSDNSKIY/VSCODE/Comfy
cp .env.example .env
nano .env
```

Required variables:
```env
RUNPOD_API_KEY=your_runpod_api_key
S3_BUCKET=your-bucket-name
S3_ACCESS_KEY_ID=your_aws_access_key
S3_SECRET_ACCESS_KEY=your_aws_secret_key
S3_REGION=us-east-1
```

---

## Step 3: Build and Push Docker Image

### Option A: Using the deploy script (Recommended)

```bash
cd /Volumes/SSDNSKIY/VSCODE/Comfy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Option B: Manual build and push

```bash
cd /Volumes/SSDNSKIY/VSCODE/Comfy

# Build the image
docker build -f Dockerfile.serverless -t comfyui-runpod:latest .

# Tag for GHCR (replace YOUR_GITHUB_USERNAME)
IMAGE_TAG="ghcr.io/YOUR_GITHUB_USERNAME/comfy-runpod:latest"
docker tag comfyui-runpod:latest $IMAGE_TAG

# Push to GHCR
docker push $IMAGE_TAG
```

**Note:** The ComfyUI fork (AntonGoldobin/Comfy) is private, so you need to use the official `comfyanonymous/comfyui` base image and add your customizations on top.

---

## Step 4: Create RunPod Endpoint

### Using RunPod CLI

```bash
# Create new endpoint
runpod endpoint create
```

Required configuration:
```
Docker image: ghcr.io/YOUR_GITHUB_USERNAME/comfy-runpod:latest
GPU: NVIDIA RTX 4090
Container disk: 50GB
Volume disk: 100GB
Min vCPU: 2
Max vCPU: 4
```

### Environment Variables (in RunPod dashboard)
```
S3_BUCKET=your-bucket-name
S3_ACCESS_KEY_ID=your_aws_access_key
S3_SECRET_ACCESS_KEY=your_aws_secret_key
S3_REGION=us-east-1
COMFYUI_URL=http://localhost:8188
PYTHONUNBUFFERED=1
```

### Using runpod CLI with JSON config
```bash
runpod endpoint create --name comfyui-serverless << 'EOF'
{
  "containerDiskInGb": 50,
  "dockerImage": "ghcr.io/YOUR_GITHUB_USERNAME/comfy-runpod:latest",
  "env": [
    {"key": "S3_BUCKET", "value": "your-bucket-name"},
    {"key": "S3_ACCESS_KEY_ID", "value": "your_access_key"},
    {"key": "S3_SECRET_ACCESS_KEY", "value": "your_secret_key"}
  ],
  "gpuCount": 1,
  "gpuTypeId": "NVIDIA RTX 4090",
  "location": "US East",
  "volumeInGb": 100
}
EOF
```

---

## Step 5: Get Your Endpoint ID

After creation, get the endpoint ID from the RunPod console:
- Go to [RunPod Console](https://runpod.io/console/serverless)
- Click on your endpoint
- Copy the **Endpoint ID** (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

Or via CLI:
```bash
runpod endpoint list
```

---

## Step 6: Update Configuration

### Update Comfy .env
```bash
echo "RUNPOD_ENDPOINT_ID=your_endpoint_id" >> /Volumes/SSDNSKIY/VSCODE/Comfy/.env
```

### Update Reelant backend .env
```bash
echo "RUNPOD_ENDPOINT_ID=your_endpoint_id" >> /Volumes/SSDNSKIY/VSCODE/reelant/.env
```

---

## Step 7: Verify Deployment

### Test /system_stats endpoint
```bash
curl -X POST "https://api.runpod.io/v1/${RUNPOD_ENDPOINT_ID}/run" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -d '{"input": {}}'
```

### Or check endpoint status
```bash
curl -X POST "https://api.runpod.io/v1/${RUNPOD_ENDPOINT_ID}/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -d '{}'
```

### Run integration test
```bash
cd /Volumes/SSDNSKIY/VSCODE/Comfy
./scripts/test-connection.sh
```

---

## Deployment Checklist

- [ ] RunPod account with credits
- [ ] RunPod CLI installed and configured (`runpod whoami` works)
- [ ] AWS S3 bucket created with CORS configured
- [ ] S3 credentials with put/get permissions
- [ ] Docker image built and pushed to GHCR
- [ ] RunPod endpoint created
- [ ] Environment variables configured in RunPod dashboard
- [ ] `RUNPOD_ENDPOINT_ID` added to Reelant `.env`
- [ ] `/system_stats` endpoint returns 200 OK
- [ ] Test workflow execution successful

---

## SVD (Stable Video Diffusion) Support

The base image `comfyanonymous/comfyui:latest` includes SVD nodes:
- `SVD_Load`
- `SVD_Sampler`
- `SVD_img2vid_Conditioning`

These are built into ComfyUI core.

**The SVD model weights (`svd.safetensors`) are NOT included** in the base image.

### SVD Model Download

The Dockerfile includes a placeholder for SVD model download. To add SVD support:

1. **Option A: Download during Docker build (for faster cold starts)**
   ```dockerfile
   # Add to Dockerfile.serverless
   RUN mkdir -p /workspace/ComfyUI/models/checkpoints && \
       wget -q https://huggingface.co/stabilityai/stable-video-diffusion-img2vid/resolve/main/svd.safetensors \
       -O /workspace/ComfyUI/models/checkpoints/svd.safetensors
   ```

2. **Option B: Download at container startup**
   The container will download models on first use, but this increases cold start time.

### Verify SVD is Available

After deployment, check ComfyUI system stats:
```bash
curl http://YOUR_ENDPOINT_ID-xxxx.proxy.runpodpod.com/system_stats
```

---

## Troubleshooting

### Cold Start Timeout
If the endpoint times out on first request:
- Increase "Execution Timeout" in RunPod dashboard
- The SVD model download adds ~30-60s to cold start

### GPU Not Available
- Ensure RTX 4090 is available in your selected region
- Try alternative regions (US West, EU Central)

### Out of Memory
- Reduce video frame count in workflow
- Use SVD image2video instead of larger models

### Image Build Fails
- Ensure GHCR access: `docker login ghcr.io`
- Check if your GitHub username is correct in the image tag

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      RunPod Endpoint                         │
│                                                              │
│  ┌──────────────┐    ┌──────────────────────────────────┐   │
│  │  startup.sh  │───>│  ComfyUI Sidecar (port 8188)    │   │
│  │              │    │  - main.py --listen 0.0.0.0    │   │
│  └──────────────┘    └──────────────────────────────────┘   │
│         │                       ▲                            │
│         ▼                       │                            │
│  ┌──────────────┐    ┌──────────────────────────────────┐   │
│  │  handler.py  │────│  RunPod Serverless Worker       │   │
│  │  (blocks)    │    │  - Receives jobs via /run       │   │
│  └──────────────┘    │  - Submits to ComfyUI API        │   │
│                       │  - Polls /history/{prompt_id}    │   │
│                       │  - Uploads outputs to S3          │   │
│                       └──────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Cost Estimation

- **RTX 4090**: ~$0.50/hr (RunPod serverless)
- **SVD inference** (25 frames, 1024x1024): ~30-60 seconds
- **Cost per generation**: ~$0.01-0.025 per video

Monitor costs at: https://runpod.io/console/billing
