"""
handler.py — RunPod Serverless entrypoint.

This file exists solely to be scanned by RunPod's pre-deploy check.
All logic is delegated to runpod_handler module.
"""

import asyncio
import runpod

from runpod_handler import _worker

# RunPod pre-deploy check scans for this exact pattern:
runpod.serverless.start({"handler": lambda job: asyncio.get_event_loop().run_until_complete(_worker.handler(job))})
