#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -k|--keys-file PATH"
  echo "Configure AWS CLI and update GitHub secrets from a .keys file"
  echo ""
  echo "Options:"
  echo "  -k, --keys-file PATH    Path to the .keys file (required)"
  echo "  -h, --help             Show this help message"
  echo ""
  echo "The .keys file should contain:"
  echo "AWS_ACCESS_KEY_ID=your-access-key-id"
  echo "AWS_SECRET_ACCESS_KEY=your-secret-access-key"
  echo "AWS_DEFAULT_REGION=us-east-1  # optional"
}

keys_example() {
  echo "Example .keys file content:"
  echo "AWS_ACCESS_KEY_ID=your-access-key-id"
  echo "AWS_SECRET_ACCESS_KEY=your-secret-access-key"
  echo "AWS_DEFAULT_REGION=us-east-1  # optional"
}

# Parse command line arguments
KEYS_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -k|--keys-file)
      KEYS_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Check if keys file path was provided
if [ -z "$KEYS_FILE" ]; then
  echo "Error: Keys file path is required!"
  echo ""
  usage
  exit 1
fi

# Check if .keys file exists
if [ ! -f "$KEYS_FILE" ]; then
  echo "Error: Keys file '$KEYS_FILE' not found!"
  echo "Create a .keys file at '$KEYS_FILE' with the following content:"
  keys_example
  exit 1
fi

# Validate .keys file structure
echo "Using keys file: $KEYS_FILE"
source "$KEYS_FILE"

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Error: .keys file '$KEYS_FILE' must define AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY."
  keys_example
  exit 1
fi

# Configure AWS CLI non-interactively
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

# Optionally set default region if present in .keys
if [ ! -z "$AWS_DEFAULT_REGION" ]; then
  aws configure set region "$AWS_DEFAULT_REGION"
fi
