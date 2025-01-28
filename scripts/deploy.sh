#!/bin/bash
echo "Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
