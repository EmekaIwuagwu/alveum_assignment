#!/bin/bash
echo "Installing Terraform..."
sudo apt-get update -y
sudo apt-get install -y terraform

echo "Installing AWS CLI..."
sudo apt-get install -y awscli

echo "Setup complete!"
