# Phase 1.5 — Comfy RunPod Integration Test Plan

## Overview

Test the end-to-end flow: Reelant → RunPod Comfy endpoint → video output → Reelant URL extraction.

---

## Prerequisites

1. **Comfy endpoint deployed** on RunPod with S3 storage configured
2. **RUNPOD_ENDPOINT_ID** known (e.g. `c8lktciap612s7`)
3. **Reelant infra running**: `cd /Volumes/SSDNSKIY/VSCODE/reelant/infra && docker compose up -d`
4. **Test user** logged into Reelant UI with available tokens

---

## Step 1: Update Reelant .env with New ENDPOINT_ID

Edit `/Volumes/SSDNSKIY/VSCODE/reelant/infra/.env`:

```bash
RUNPOD_ENDPOINT_ID=<your_new_endpoint_id>
```

Restart the worker to pick up the new value:

```bash
cd /Volumes/SSDNSKIY/VSCODE/reelant/infra && docker compose restart worker
```

**Current values** (from `infra/.env`):
```
RUNPOD_API_KEY=rpa_P7WFA4ZO0X0O0U9267YMZHXN08FSMVWOTOAN4IQVthx4a0
RUNPOD_ENDPOINT_ID=c8lktciap612s7
RUNPOD_API_BASE_URL=https://api.runpod.ai/v2
```

---

## Step 2: Create Test Style with SVD Video Workflow JSON in DB

Insert a Style row with a valid SVD (Stable Video Diffusion) ComfyUI workflow JSON.

**Minimal SVD workflow structure** (must include `VHS_VideoCombine` for video output):

```json
{
  "1": {
    "class_type": "VHS_LoadImages",
    "inputs": { "image_upload": "__PARAM__" }
  },
  "2": {
    "class_type": "SVD_img2vid_Conditioning",
    "inputs": { "width": 1024, "height": 1024, "video_frames": 25, "motion_bucket": 127 }
  },
  "3": {
    "class_type": "KSampler",
    "inputs": { "seed": 0, "steps": 20, "cfg": 3.5, "sampler_name": "euler", "scheduler": "normal" }
  },
  "4": {
    "class_type": "VHS_VideoCombine",
    "inputs": { "fps": 8, "loop_count": 0 }
  }
}
```

**Style record** (insert via DB or admin panel):
| Field | Value |
|-------|-------|
| `id` | UUID |
| `name` | `Test SVD Video` |
| `modelSet` | `wan` |
| `comfyWorkflowJson` | SVD JSON above |
| `paramMapping` | `{"prompt": {"class_type": "...", "input": "..."}}` |
| `maxExpectedDurationSec` | `300` |
| `avgDurationSec` | `120` |
| `tokenCost` | `10` |
| `isActive` | `true` |

---

## Step 3: Upload a Reference Image

1. Open Reelant UI at `https://mac-mini-anton.tail52fd42.ts.net`
2. Select the test style
3. Upload a reference image (JPG/PNG, ≤10MB)
4. Note the `uploadedImageName` returned by the API (used in Step 5)

---

## Step 4: Submit Generation via Reelant API

**Via UI**: Click "Generate" with the test style and reference image.

**Via API** (optional, for debugging):

```bash
curl -X POST https://mac-mini-anton.tail52fd42.ts.net/api/generations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "styleId": "<style-uuid>",
    "params": {"prompt": "test video"},
    "referenceImageId": "<image-id>"
  }'
```

---

## Step 5: Poll and Verify Video URL Extraction

### 5a: Monitor Worker Logs

```bash
cd /Volumes/SSDNSKIY/VSCODE/reelant/infra && docker compose logs -f worker
```

Expected log output:
```
RunPodProvider: submitted job <providerJobId>
extractVideoUrl: extracted https://signed-...
```

### 5b: Check Generation Status via API

```bash
curl https://mac-mini-anton.tail52fd42.ts.net/api/generations/<generation-id>
```

Expected response:
```json
{
  "status": "completed",
  "resultVideoUrl": "https://<storage>/<video>.mp4"
}
```

### 5c: Verify extractVideoUrl Contract

The `output-parser.ts` (`extractVideoUrl`) expects:

```typescript
output: {
  images: Array<{
    filename: string;   // matches /\.(mp4|webm)$/i
    type: 's3_url';     // MUST be 's3_url'
    data: string;        // signed URL
  }>
}
```

**The Comfy handler** (`runpod_handler.py` line 372-376) returns:

```python
output_files.append({
    'filename': fname,
    'type': file_type,  # 's3_url' on S3 success, 'local' on fallback
    'data': url
})
return {'images': output_files}
```

**Contract Status**: MATCHES when RunPod S3 upload succeeds. If S3 upload fails, `type='local'` and `extractVideoUrl` returns `undefined` — generation would fail.

---

## Step 6: Verify Video is Accessible

1. Copy `resultVideoUrl` from the generation response
2. Open in browser or curl:
   ```bash
   curl -I "https://<storage-url>"
   ```
3. Confirm:
   - HTTP 200 response
   - `Content-Type: video/mp4` or `video/webm`
   - Non-zero Content-Length

---

## Known Issues & Risks

### Issue 1: S3 Fallback Returns `type='local'`
**Location**: `Comfy/runpod_handler.py` lines 364-367
**Risk**: If S3 upload fails, `type` becomes `'local'` and `extractVideoUrl` returns `undefined`
**Impact**: Generation fails with "video URL not found"
**Mitigation**: Ensure S3 credentials are correct in RunPod endpoint env vars

### Issue 2: No Unit Tests for End-to-End Contract
The `runpod-provider.spec.ts` mocks the HTTP layer but does not test the full RunPod API contract.
**Mitigation**: Use the integration test above with a live endpoint

### Issue 3: STORAGE_DRIVER Mismatch
The `infra/.env` has `STORAGE_DRIVER=s3` but the Reelant RunPodProvider only includes `s3Config` when `storageDriver === 's3'`.
**Impact**: If RunPod S3 credentials differ from Reelant's S3, outputs may upload to different buckets.

---

## Run Unit Tests (Without Endpoint)

```bash
cd /Volumes/SSDNSKIY/VSCODE/reelant/apps/worker
npm run test -- --testPathPattern="runpod-provider|output-parser"
```

Tests covered:
- `output-parser.spec.ts`: 4 specs for `extractVideoUrl` edge cases
- `runpod-provider.spec.ts`: 4 specs for `submitJob` and `pollUntilDone`

These run entirely offline with mocked HTTP.
