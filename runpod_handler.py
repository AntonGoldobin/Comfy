import runpod
import json
import os
import asyncio
import boto3
from botocore.config import Config as BotoConfig


class ComfyWorker:
    def __init__(self):
        self.s3_client = None
        self.s3_bucket = None

    def setup(self, config):
        """Called once at startup - initialize S3 client if s3Config provided."""
        s3_config = config.get('s3Config')
        if s3_config:
            self.s3_client = boto3.client(
                's3',
                endpoint_url=s3_config.get('endpointUrl'),
                aws_access_key_id=s3_config['accessId'],
                aws_secret_access_key=s3_config['accessSecret'],
                config=BotoConfig(signature_version='s3v4')
            )
            self.s3_bucket = s3_config['bucketName']

    async def handler(self, job):
        """Called for each job - execute ComfyUI workflow."""
        job_input = job['input']
        workflow = job_input.get('workflow') or job_input.get('prompt')
        images = job_input.get('images', [])
        s3_config = job_input.get('s3Config')

        # Initialize S3 client per-job if provided in job input
        s3_client = self.s3_client
        s3_bucket = self.s3_bucket
        if s3_config:
            s3_client = boto3.client(
                's3',
                endpoint_url=s3_config.get('endpointUrl'),
                aws_access_key_id=s3_config['accessId'],
                aws_secret_access_key=s3_config['accessSecret'],
                config=BotoConfig(signature_version='s3v4')
            )
            s3_bucket = s3_config['bucketName']

        # 1. Save workflow to ComfyUI input directory
        workflow_path = '/tmp/workflow.json'
        with open(workflow_path, 'w') as f:
            json.dump(workflow, f)

        # 2. Execute via ComfyUI API (assumes ComfyUI running on port 8188)
        import httpx
        async with httpx.AsyncClient(timeout=600) as client:
            # Submit prompt
            resp = await client.post(
                'http://localhost:8188/prompt',
                json={'prompt': workflow}
            )
            resp.raise_for_status()
            prompt_id = resp.json()['prompt_id']

            # Poll for completion
            while True:
                hist_resp = await client.get(f'http://localhost:8188/history/{prompt_id}')
                hist_resp.raise_for_status()
                history = hist_resp.json()
                if prompt_id in history:
                    break
                await asyncio.sleep(2)

        # 3. Find output files in /output
        output_dir = '/output'
        output_files = []

        if not os.path.exists(output_dir):
            output_dir = os.path.expanduser('~/ComfyUI/output')

        for fname in os.listdir(output_dir):
            if fname.endswith(('.mp4', '.webm', '.png', '.jpg', '.jpeg', '.gif')):
                fpath = os.path.join(output_dir, fname)

                # 4. Upload to S3
                if s3_client:
                    s3_key = f'comfy-outputs/{prompt_id}/{fname}'
                    s3_client.upload_file(fpath, s3_bucket, s3_key)
                    url = s3_client.generate_presigned_url(
                        'get_object',
                        Params={'Bucket': s3_bucket, 'Key': s3_key},
                        ExpiresIn=3600
                    )
                    file_type = 's3_url'
                else:
                    # Fallback: local path
                    url = f'file://{fpath}'
                    file_type = 'local'

                output_files.append({
                    'filename': fname,
                    'type': file_type,
                    'data': url
                })

        return {'images': output_files}


# Start the serverless worker
if __name__ == '__main__':
    runpod.ServerlessWorker(ComfyWorker).start()
