#!/bin/bash

echo "=== ComfyUI RunPod Serverless Connection Test ==="

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

ENDPOINT_URL="${RUNPOD_API_BASE_URL:-https://api.runpod.io/v1}"
ENDPOINT_ID="${RUNPOD_ENDPOINT_ID:-}"
API_KEY="${RUNPOD_API_KEY:-}"

if [ -z "$ENDPOINT_ID" ] || [ -z "$API_KEY" ]; then
    echo "Error: RUNPOD_ENDPOINT_ID and RUNPOD_API_KEY must be set"
    exit 1
fi

echo "Testing /system_stats..."
curl -s -X POST "$ENDPOINT_URL/$ENDPOINT_ID/status" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{}' | python3 -m json.tool

echo ""
echo "Testing /run (minimal workflow)..."
TEST_WORKFLOW='{
  "input": {
    "workflow": {
      "LoadImage": {
        "class_type": "LoadImage",
        "inputs": {"image": ""}
      }
    }
  }
}'
curl -s -X POST "$ENDPOINT_URL/$ENDPOINT_ID/run" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "$TEST_WORKFLOW" | python3 -m json.tool
