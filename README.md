# ComfyUI RunPod Deployment

Self-hosted GPU ComfyUI server for Reelant AI generation.

## Prerequisites

- Docker with NVIDIA GPU support (nvidia-docker)
- Docker Compose v2+
- NVIDIA GPU with CUDA support

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url> /Volumes/SSDNSKIY/VSCODE/Comfy
cd /Volumes/SSDNSKIY/VSCODE/Comfy
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
nano .env
```

### 3. Run Locally

```bash
# Make startup script executable
chmod +x startup.sh

# Start ComfyUI
./startup.sh

# Or use docker-compose directly:
docker compose up -d
```

### 4. Verify

Open http://localhost:8188 in your browser, or run the test script:

```bash
./scripts/test-connection.sh
```

## RunPod Deployment

### Option 1: RunPod Persistent Volume

1. Create a RunPod instance with a persistent volume
2. Clone this repository to the volume
3. Set environment variables (`RUNPOD_API_KEY`, `COMFYUI_HOST`)
4. Run `docker compose up -d`

### Option 2: Docker Run

```bash
docker run --gpus all \
  -p 8188:8188 \
  -v $(pwd)/output:/output \
  -v $(pwd)/models:/models \
  --name comfyui \
  comfyorg/comfyui
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNPOD_API_KEY` | RunPod API key for deployment | - |
| `COMFYUI_HOST` | ComfyUI server hostname | localhost |
| `COMFYUI_PORT` | ComfyUI server port | 8188 |
| `COMFYUI_API_KEY` | Optional API key for authentication | - |
| `COMFYUI_URL` | Full URL for API requests | http://localhost:8188 |

## Testing the Connection

```bash
# Run the test script
./scripts/test-connection.sh

# Manual test
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

### GPU Not Detected

Ensure NVIDIA Docker runtime is installed:
```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Port Already in Use

Change the port in `docker-compose.yml` or stop the conflicting service.

### Container Crashes on Start

Check logs:
```bash
docker compose logs comfyui
```
