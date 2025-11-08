#!/bin/bash

# Exit on any error
set -e

echo "Setting up Network Monitoring Stack..."

# Update and install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-compose

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER
echo "You may need to log out and back in for the docker group changes to take effect."

# Create directory for monitoring stack
mkdir -p ~/monitoring-stack
cd ~/monitoring-stack

# Copy all config files from the source directory to the monitoring-stack directory
echo "Copying configuration files..."
# (This assumes you've transferred the files from your local machine to the VM)

# Start the monitoring stack
echo "Starting the monitoring stack..."
docker-compose up -d

echo "Monitoring stack setup complete!"
echo "You can access the services at:"
echo "  - Prometheus: http://<VM_IP>:9090"
echo "  - Grafana: http://<VM_IP>:3000 (admin/admin)"
echo "  - AlertManager: http://<VM_IP>:9093"
echo "  - cAdvisor: http://<VM_IP>:8080" 