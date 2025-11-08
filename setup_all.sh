#!/bin/bash

set -e

echo "====================================================="
echo "Setting up Complete Monitoring Stack"
echo "====================================================="

mkdir -p logs

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Run Suricata setup
echo "====================================================="
echo "Setting up Suricata IDS"
echo "====================================================="
sudo bash setup_suricata.sh | tee logs/suricata_setup.log

# Run SNMP setup
echo "====================================================="
echo "Setting up SNMP monitoring"
echo "====================================================="
bash setup_snmp.sh | tee logs/snmp_setup.log

# Run Anomaly Detection setup
echo "====================================================="
echo "Setting up Anomaly Detection"
echo "====================================================="
bash setup_anomaly_detection.sh | tee logs/anomaly_setup.log

# Start Docker Compose
echo "====================================================="
echo "Starting Docker services"
echo "====================================================="
docker-compose down
docker-compose up -d

echo "====================================================="
echo "Monitoring stack setup complete!"
echo "====================================================="
echo "Grafana UI:          http://localhost:3000 (admin/admin)"
echo "Prometheus UI:       http://localhost:9090"
echo "AlertManager UI:     http://localhost:9093"
echo "Node Exporter:       http://localhost:9100/metrics"
echo "SNMP Exporter:       http://localhost:9116/metrics"
echo "Suricata Exporter:   http://localhost:9917/metrics"
echo "====================================================="
echo "Check the logs/ directory for setup logs if you encounter any issues."
 