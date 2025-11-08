#!/bin/bash

# Exit on any error
set -e

echo "Setting up Suricata IDS..."

# Install Suricata
echo "Installing Suricata..."
sudo apt update
sudo apt install -y suricata

# Configure Suricata
echo "Configuring Suricata..."
# Make a backup of the original config
sudo cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak

# Update default network interface
IFACE=$(ip route | grep default | awk '{print $5}')
sudo sed -i "s/- interface: eth0/- interface: $IFACE/" /etc/suricata/suricata.yaml

# Enable EVE JSON logging (needed for Prometheus)
sudo sed -i 's/eve-log:.*$/eve-log:\n    enabled: yes\n    filetype: regular\n    filename: eve.json/' /etc/suricata/suricata.yaml

# Update rule sources
sudo suricata-update add-source emerging-threats https://rules.emergingthreats.net/open/suricata-6.0/emerging.rules.tar.gz
sudo suricata-update update-sources
sudo suricata-update

# Enable and start Suricata
echo "Starting Suricata service..."
sudo systemctl enable suricata
sudo systemctl start suricata

# Configure Suricata logs to be readable by Prometheus exporter
echo "Setting up log permissions..."
sudo mkdir -p /var/log/suricata
sudo chmod -R 755 /var/log/suricata

# Install the Suricata Prometheus exporter
echo "Installing Suricata Prometheus exporter..."
sudo apt install -y golang-go
go get -u github.com/prometheus/node_exporter
cd /tmp
git clone https://github.com/corelight/suricata_exporter.git
cd suricata_exporter
make
sudo cp suricata_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/suricata_exporter

# Create systemd service for Suricata exporter
echo "Creating Suricata exporter service..."
cat << EOF | sudo tee /etc/systemd/system/suricata-exporter.service
[Unit]
Description=Suricata Prometheus Exporter
After=network.target suricata.service

[Service]
Type=simple
ExecStart=/usr/local/bin/suricata_exporter --suricata.stats-file=/var/run/suricata/stats.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable suricata-exporter.service
sudo systemctl start suricata-exporter.service

echo "Suricata IDS setup complete!"
echo "You can check the service status with: sudo systemctl status suricata"
echo "Suricata logs are available at: /var/log/suricata/"
echo "Suricata Prometheus metrics available at: http://localhost:9917/metrics" 