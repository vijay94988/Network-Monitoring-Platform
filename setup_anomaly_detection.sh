#!/bin/bash

set -e

echo "Setting up Network Anomaly Detection..."

# Install required packages
echo "Installing Python and dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# Create installation directory
echo "Creating installation directory..."
sudo mkdir -p /opt/monitoring-stack
sudo chown $USER:$USER /opt/monitoring-stack

# Copy necessary files
echo "Copying files to installation directory..."
cp network_anomaly_detection.py /opt/monitoring-stack/
cp requirements.txt /opt/monitoring-stack/

# Create Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv /opt/monitoring-stack/venv
/opt/monitoring-stack/venv/bin/pip install -r requirements.txt

# Update the service file
echo "Updating service file..."
# Replace python path with venv python
sed -i "s|ExecStart=/usr/bin/python3|ExecStart=/opt/monitoring-stack/venv/bin/python3|" network-anomaly-detection.service

# Copy service file and enable
echo "Setting up systemd service..."
sudo cp network-anomaly-detection.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable network-anomaly-detection.service
sudo systemctl start network-anomaly-detection.service

echo "Network Anomaly Detection setup complete!"
echo "You can check the service status with: sudo systemctl status network-anomaly-detection.service" 
echo "Logs will be available at: /opt/monitoring-stack/anomaly_detection.log" 