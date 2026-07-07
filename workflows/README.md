# ComfyUI Video Workflows

## SVD Image-to-Video Workflow

Model: Stable Video Diffusion (svd.safetensors)
Usage: Takes a reference image and generates a video animation.

### ParamMapping for Reelant

| Param Key | class_type | input | type | default |
|-----------|------------|-------|------|---------|
| input_image | LoadImage | image | image | — |
| seed | KSampler | seed | number | 42 |
| steps | KSampler | steps | number | 30 |
| cfg | KSampler | cfg | number | 7.0 |
| strength | SVD_img2vid_Conditioning | strength | number | 1.0 |
| width | EmptyLatentVideo | width | number | 1024 |
| height | EmptyLatentVideo | height | number | 1024 |
| frames | EmptyLatentVideo | frames | number | 25 |
| fps | VHS_VideoCombine | fps | number | 30 |
| prompt | CLIPTextEncode_pos | text | text | — |
| negative_prompt | CLIPTextEncode_neg | text | text | blurry, low quality |

## Portrait Video Workflow

Model: Stable Video Diffusion (svd.safetensors)
Usage: Generates portrait-oriented video (512x768) from a reference image.

### ParamMapping for Reelant

| Param Key | class_type | input | type | default |
|-----------|------------|-------|------|---------|
| input_image | LoadImage | image | image | — |
| seed | KSampler_Portrait | seed | number | 123 |
| prompt | CLIPTextEncode_pos_portrait | text | text | portrait photo, professional lighting |

## Text-to-Video Workflow (CogVideoX)

Model: CogVideoX-2b
Usage: Generates video from text prompt (future implementation).

### ParamMapping for Reelant

| Param Key | class_type | input | type | default |
|-----------|------------|-------|------|---------|
| prompt | TextEncode_Pos | text | text | — |
| negative_prompt | TextEncode_Neg | text | text | blurry, low quality |
| seed | CogVideoX_Sampler | seed | number | 42 |
| steps | CogVideoX_Sampler | steps | number | 50 |
| cfg | CogVideoX_Sampler | cfg | number | 6.0 |
| frames | EmptyLatentVideo_Text2Video | frames | number | 48 |
| fps | VHS_VideoCombine_Text2Video | fps | number | 16 |

## Important Notes

- These workflows use `class_type` as keys (NOT numeric IDs) — this is correct for WorkflowBuilder
- The `{{param_name}}` syntax in default values is for documentation; actual params come from `gen.params` in Reelant
- `input_image` is a special image type — the worker uploads the image and passes the filename
- VHS_VideoCombine saves to `/output` which the handler then uploads to S3
- WorkflowBuilder.merge() binds params by `class_type + input` (NOT numeric node ID)
