#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Default plan file name
PLANFILE=${1:-planfile}

# Optional apply flag (use --apply or --no-apply as the second argument)
APPLY_FLAG=${2:-}

# Define escape codes for red and bold text
RED="\033[31m"
BOLD="\033[1m"
RESET="\033[0m"

# Print the styled text
echo -e "${BOLD}${RED}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET}"
echo -e "${BOLD}${RED}                           
    ___        ______    ___ ____  ____  
   / \ \      / / ___|  |_ _|  _ \|  _ \ 
  / _ \ \ /\ / /\___ \   | || | | | |_) |
 / ___ \ V  V /  ___) |  | || |_| |  __/ 
/_/   \_\_/\_/  |____/  |___|____/|_|

${RESET}"
echo "An AWS Backed Intelligent Document Processing Solution"
echo "HK Transfield, 2024"
echo -e "${BOLD}${RED}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET}"

terraform init

echo "Validating Terraform configuration..."
terraform validate

echo "Planning Terraform changes..."
terraform plan -out="$PLANFILE"

# Determine if the plan should be applied
if [[ "$APPLY_FLAG" == "--apply" ]]; then
    echo "Applying Terraform changes..."
    terraform apply "$PLANFILE"

    # DATA_BUCKET = "$(terraform output -raw data_bucket)"
    # aws s3 cp classification-training s3://{data_bucket}/idp/textract --recursive --only-show-errors

elif [[ "$APPLY_FLAG" == "--no-apply" ]]; then
    echo "Skipping Terraform apply."

else
    # Interactive prompt if no flag is provided
    read -p "Do you want to apply the plan? (yes/no): " RESPONSE
    
    if [[ "$RESPONSE" == "yes" ]]; then
        echo "Applying Terraform changes..."
        terraform apply "$PLANFILE"
    
    else
        echo "Skipping Terraform apply."
    fi
fi