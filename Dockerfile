FROM comfyorg/comfyui

# Install custom nodes if needed
# COPY custom_nodes /workspace/ComfyUI/custom_nodes

# Install additional dependencies
# RUN pip install <additional-packages>

WORKDIR /workspace/ComfyUI

CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
