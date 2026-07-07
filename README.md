# ComfyUI RunPod Deployment

Self-hosted GPU ComfyUI server for Reelant AI generation.

## Deployment Options

This repository supports two deployment modes:
1. **RunPod Serverless** - Recommended for production (GPU on-demand, auto-scaling)
2. **Local Docker** - For local development and testing

---

## RunPod Serverless Deployment (Recommended)

### Prerequisites

- [RunPod](https://runpod.io) account with GPU credits
- [RunPod CLI](https://docs.runpod.io/cli/getting-started) installed
- AWS S3 bucket for output storage
- Docker for building the serverless image

### Install RunPod CLI

```bash
pip install runpod
runpod config
```

### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
nano .env
```

Required environment variables:

| Variable | Description |
|----------|-------------|
| `RUNPOD_API_KEY` | RunPod API key from your dashboard |
| `RUNPOD_ENDPOINT_ID` | Your serverless endpoint ID (after creation) |
| `S3_BUCKET` | S3 bucket name for output storage |
| `S3_ACCESS_KEY_ID` | AWS access key |
| `S3_SECRET_ACCESS_KEY` | AWS secret key |
| `S3_REGION` | AWS region (default: us-east-1) |

### 2. Set Up S3 Bucket

Run the S3 setup script to create and configure your bucket:

```bash
./scripts/s3_setup.sh
```

This will:
- Create the S3 bucket (if it doesn't exist)
- Configure CORS for signed URL access
- Set up bucket policy for RunPod access

### 3. Deploy to RunPod

```bash
# Make deploy script executable (if not already)
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh
```

The deploy script will:
- Build the Docker image with serverless optimizations
- Push to GitHub Container Registry (GHCR)
- Provide instructions for endpoint configuration

### 4. Create RunPod Endpoint

After pushing the image, create your serverless endpoint:

1. Go to [RunPod Console](https://runpod.io/console/serverless)
2. Click "New Endpoint"
3. Configure:
   - **Docker image**: `ghcr.io/YOUR_GITHUB_USERNAME/comfy-runpod:latest`
   - **GPU**: NVIDIA RTX 4090
   - **Container disk**: 50GB
   - **Volume disk**: 100GB
   - **Environment variables**:
     - `S3_BUCKET`
     - `S3_ACCESS_KEY_ID`
     - `S3_SECRET_ACCESS_KEY`

4. Deploy and copy your **Endpoint ID**

### 5. Update Configuration

Update your `.env` file with the endpoint ID:

```bash
RUNPOD_ENDPOINT_ID=your_endpoint_id_here
```

Then update the Reelant backend `.env`:

```bash
RUNPOD_ENDPOINT_ID=<your_endpoint_id>
```

### 6. Test the Connection

```bash
./scripts/test-connection.sh
```

Or manually:

```bash
curl -X POST "https://api.runpod.io/v1/${RUNPOD_ENDPOINT_ID}/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -d '{}'
```

---

## Local Docker Deployment

For local development and testing only.

### Prerequisites

- Docker with NVIDIA GPU support (nvidia-docker)
- Docker Compose v2+
- NVIDIA GPU with CUDA support

### Quick Start

```bash
git clone <repository-url> /Volumes/SSDNSKIY/VSCODE/Comfy
cd /Volumes/SSDNSKIY/VSCODE/Comfy

# Configure environment
cp .env.example .env
nano .env

# Start ComfyUI
chmod +x startup.sh
./startup.sh

# Or use docker-compose directly:
docker compose up -d
```

### Verify Local Installation

Open http://localhost:8188 in your browser, or run:

```bash
./scripts/test-connection.sh
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNPOD_API_KEY` | RunPod API key | - |
| `RUNPOD_ENDPOINT_ID` | Serverless endpoint ID | - |
| `RUNPOD_API_BASE_URL` | RunPod API base URL | https://api.runpod.io/v1 |
| `S3_BUCKET` | S3 bucket for outputs | comfyui-outputs |
| `S3_ACCESS_KEY_ID` | AWS access key ID | - |
| `S3_SECRET_ACCESS_KEY` | AWS secret key | - |
| `S3_REGION` | AWS region | us-east-1 |
| `COMFYUI_HOST` | ComfyUI server hostname | localhost |
| `COMFYUI_PORT` | ComfyUI server port | 8188 |
| `COMFYUI_API_KEY` | Optional API key | - |
| `COMFYUI_URL` | Full URL for API requests | http://localhost:8188 |

## Testing the Connection

### RunPod Serverless

```bash
./scripts/test-connection.sh
```

### Local Docker

```bash
curl http://localhost:8188/system_stats
```

## Volumes

| Volume | Description |
|--------|-------------|
| `output` | Generated images and workflow outputs |
| `models` | Stable Diffusion models, checkpoints, etc. |
| `custom_nodes` | Custom ComfyUI nodes |

## Styles/Templates

ComfyUI does not have a built-in workflow templates API. Styles for Reelant are stored in the Reelant database (`styles` table with `comfyWorkflowJson` column).

## Troubleshooting

### RunPod Deployment Issues

**Endpoint not responding:**
- Check endpoint status in RunPod console
- Verify API key and endpoint ID are correct
- Check CloudWatch logs if enabled

**GPU not available:**
- Ensure your RunPod plan includes GPU
- RTX 4090 may not be available in all regions - try alternative regions

### Local GPU Issues

**GPU Not Detected:**

Ensure NVIDIA Docker runtime is installed:
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

**Port Already in Use:**

Change the port in `docker-compose.yml` or stop the conflicting service.

**Container Crashes on Start:**

Check logs:
```bash
docker compose logs comfyui
```
