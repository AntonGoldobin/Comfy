FROM comfyorg/comfyui

# Install Python dependencies for the RunPod handler
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy handler files
COPY runpod_handler.py /workspace/ComfyUI/
COPY handler.py /workspace/ComfyUI/

# Create output and input directories
RUN mkdir -p /output /input

# Set environment
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_URL=http://localhost:8188

# ComfyUI API port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -sf http://localhost:8188/system_stats || exit 1

# Start ComfyUI in background, then run the RunPod handler
WORKDIR /workspace/ComfyUI
ENTRYPOINT ["python", "handler.py"]
