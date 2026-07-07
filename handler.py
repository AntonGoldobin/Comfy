"""
handler.py — RunPod Serverless entrypoint.

Starts ComfyUI as a sidecar, then runs the RunPod serverless handler.
"""

import asyncio
import subprocess
import sys
import time
import runpod

from runpod_handler import _worker


def start_comfyui_sidecar():
    """Start ComfyUI in background and wait for it to be ready."""
    print("Starting ComfyUI sidecar...")
    proc = subprocess.Popen(
        [sys.executable, "main.py", "--listen", "0.0.0.0", "--port", "8188"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    for _ in range(60):
        try:
            import httpx
            resp = httpx.get("http://localhost:8188/system_stats", timeout=2)
            if resp.status_code == 200:
                print("ComfyUI sidecar is ready")
                return proc
        except Exception:
            pass
        time.sleep(2)
    print("WARNING: ComfyUI sidecar may not be ready")
    return proc


def handler(job):
    """Named handler for runpod.serverless.start()."""
    return asyncio.get_event_loop().run_until_complete(_worker.handler(job))


# Start ComfyUI sidecar and then the RunPod serverless handler.
# This runs at module load time (not inside if __name__ == "__main__")
# so RunPod's pre-deploy scanner finds it.
start_comfyui_sidecar()
runpod.serverless.start({"handler": handler})
