#!/bin/bash

GH_CMD="gh.exe"

# Check if gh is authenticated
if ! "$GH_CMD" auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI is not authenticated."
  echo "Please run: $GH_CMD auth login"
  exit 1
fi

# Get repository information
REPO=$(git config --get remote.origin.url | sed -E 's/.*github.com[/:]([^/]+\/[^.]+)(.git)?/\1/')
if [ -z "$REPO" ]; then
  echo "Error: Could not determine GitHub repository from git remote."
  exit 1
fi

# Get AWS credentials
KEY_ID=$(aws configure get aws_access_key_id)
SECRET_KEY=$(aws configure get aws_secret_access_key)

if [ -z "$KEY_ID" ] || [ -z "$SECRET_KEY" ]; then
  echo "Error: AWS credentials not found. Please run configure_aws.sh first."
  exit 1
fi

echo "Updating GitHub secrets for repo: $REPO"

# Update secrets using the found gh command
if "$GH_CMD" secret set AWS_ACCESS_KEY_ID -b"$KEY_ID" -R "$REPO"; then
  echo "✓ AWS_ACCESS_KEY_ID updated successfully"
else
  echo "✗ Failed to update AWS_ACCESS_KEY_ID"
  exit 1
fi

if "$GH_CMD" secret set AWS_SECRET_ACCESS_KEY -b"$SECRET_KEY" -R "$REPO"; then
  echo "✓ AWS_SECRET_ACCESS_KEY updated successfully"
else
  echo "✗ Failed to update AWS_SECRET_ACCESS_KEY"
  exit 1
fi

echo "GitHub secrets updated successfully."
