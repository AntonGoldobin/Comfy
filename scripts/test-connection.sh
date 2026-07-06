#!/bin/bash
set -e

# Load environment if available
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

# Use environment variables or defaults
COMFYUI_HOST=${COMFYUI_HOST:-localhost}
COMFYUI_PORT=${COMFYUI_PORT:-8188}
COMFYUI_URL=${COMFYUI_URL:-http://${COMFYUI_HOST}:${COMFYUI_PORT}}

echo "Testing ComfyUI connection at ${COMFYUI_URL}..."
echo ""

# Test 1: Basic connectivity
echo "Test 1: Basic connectivity"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${COMFYUI_URL}/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "404" ]; then
    echo "  PASS: Server is responding (HTTP ${HTTP_CODE})"
else
    echo "  FAIL: Server not responding (HTTP ${HTTP_CODE})"
    echo "  Is ComfyUI running? Try: docker compose up -d"
    exit 1
fi

# Test 2: System stats endpoint
echo ""
echo "Test 2: /system_stats endpoint"
RESPONSE=$(curl -s --max-time 10 "${COMFYUI_URL}/system_stats" 2>/dev/null || echo "{}")
if echo "$RESPONSE" | grep -q "error"; then
    echo "  WARN: system_stats returned an error"
    echo "  Response: $RESPONSE"
else
    echo "  PASS: system_stats is accessible"
    echo "  Response: $RESPONSE"
fi

# Test 3: API key if set
if [ -n "$COMFYUI_API_KEY" ]; then
    echo ""
    echo "Test 3: API key authentication"
    AUTH_RESPONSE=$(curl -s -H "X-API-Key: ${COMFYUI_API_KEY}" --max-time 10 "${COMFYUI_URL}/system_stats" 2>/dev/null || echo "{}")
    if echo "$AUTH_RESPONSE" | grep -q "error"; then
        echo "  WARN: API key authentication may not be configured"
    else
        echo "  PASS: API key authentication works"
    fi
fi

echo ""
echo "Connection test complete!"
