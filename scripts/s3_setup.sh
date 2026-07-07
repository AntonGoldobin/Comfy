#!/bin/bash
set -e

echo "=== S3 Bucket Setup for ComfyUI Outputs ==="

# This script creates the S3 bucket and configures CORS if needed

if [ -z "$S3_ACCESS_KEY_ID" ] || [ -z "$S3_SECRET_ACCESS_KEY" ]; then
    echo "Error: S3 credentials not set"
    exit 1
fi

BUCKET="${S3_BUCKET:-comfyui-outputs}"
REGION="${S3_REGION:-us-east-1}"

echo "Creating bucket (if not exists)..."
aws s3 mb s3://$BUCKET 2>/dev/null || echo "Bucket already exists or created"

echo "Enabling CORS for signed URLs..."
aws s3api put-bucket-cors --bucket $BUCKET --cors-configuration '{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET", "POST"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3600
    }
  ]
}'

echo "Bucket policy for private access..."
aws s3api put-bucket-policy --bucket $BUCKET --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"AllowRunPodUpload\",
      \"Effect\": \"Allow\",
      \"Principal\": {\"AWS\": \"arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):user/runpod\"},
      \"Action\": [\"s3:PutObject\", \"s3:GetObject\"],
      \"Resource\": \"arn:aws:s3:::$BUCKET/*\"
    }
  ]
}"

echo ""
echo "S3 setup complete!"
echo "Bucket: $BUCKET"
echo "Update your .env with:"
echo "  S3_BUCKET=$BUCKET"
