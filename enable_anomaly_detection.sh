#!/bin/bash

set -e

echo "Enabling Network Anomaly Detection..."

if [ ! -d "/opt/monitoring-stack/venv" ]; then
    echo "Python virtual environment not found, running setup script first..."
    bash setup_anomaly_detection.sh
else
    echo "Found existing setup, continuing with service activation..."
fi

sed -i "s|\$USER|$(whoami)|" network-anomaly-detection.service

echo "Installing and starting systemd service..."
sudo cp network-anomaly-detection.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable network-anomaly-detection.service
sudo systemctl restart network-anomaly-detection.service

echo "Network Anomaly Detection service enabled and started!"
echo "Check status with: sudo systemctl status network-anomaly-detection.service"
echo "View logs with: tail -f /opt/monitoring-stack/anomaly_detection.log" 