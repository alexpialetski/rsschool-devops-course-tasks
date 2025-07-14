#!/bin/bash
# Function to display usage information
usage() {
  echo "Usage: $0 -f|--file PATH"
  echo "Configure environment variables from a .env file"
  echo ""
  echo "Options:"
  echo "  -f, --file PATH          Path to the .env file (required)"
  echo "  -h, --help               Show this help message"
  echo ""
  echo "The .env file should contain lines like:"
  echo "TF_VAR_region=us-east-1"
  echo "TF_VAR_account_id=767398003596"
  echo "TF_WORKSPACE=dev"
}

# Parse command line arguments
ENV_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--env-file)
      ENV_FILE="$2"
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

if [ -z "$ENV_FILE" ]; then
  echo "Error: Environment file path is required!"
  echo ""
  usage
  exit 1
fi

# Populate the .env file with AWS CLI information
{
  echo "TF_VAR_region=$(aws configure get region)"
  echo "TF_VAR_account_id=$(aws sts get-caller-identity --query Account --output text)"
  echo "TF_WORKSPACE=dev"
} > "$ENV_FILE"

echo "Environment variables configured in '$ENV_FILE'."

