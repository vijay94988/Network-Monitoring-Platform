#!/bin/bash

# Exit on any error
set -e

echo "Setting up SNMP monitoring..."

# Install SNMP utilities for testing
echo "Installing SNMP utilities..."
sudo apt update
sudo apt install -y snmp snmp-mibs-downloader

# Uncomment the mibs line in snmp.conf to enable MIB loading
sudo sed -i 's/mibs :/# mibs :/' /etc/snmp/snmp.conf

# Create directory for snmp_exporter configuration
echo "Setting up SNMP exporter configuration..."
mkdir -p snmp
cp snmp/snmp.yml snmp/snmp.yml.bak

# Create a test script to verify SNMP connectivity
echo "Creating SNMP test script..."
cat > test_snmp.sh << 'EOF'
#!/bin/bash
# Test script for SNMP connectivity
# Usage: ./test_snmp.sh <ip_address> <community>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <ip_address> <community>"
    exit 1
fi

IP=$1
COMMUNITY=$2

echo "Testing SNMP connectivity to $IP with community $COMMUNITY..."
snmpwalk -v 2c -c $COMMUNITY $IP 1.3.6.1.2.1.1.1
snmpwalk -v 2c -c $COMMUNITY $IP 1.3.6.1.2.1.2.1  # ifNumber

if [ $? -eq 0 ]; then
    echo "SNMP test successful!"
else
    echo "SNMP test failed. Check your network settings and SNMP configuration."
fi
EOF

chmod +x test_snmp.sh

# Update prometheus.yml to make sure SNMP targets are correctly configured
echo "Updating Prometheus configuration for SNMP..."
# Extract SNMP targets from prometheus.yml
SNMP_TARGETS=$(grep -A10 '- job_name: '\''snmp'\' prometheus/prometheus.yml | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '^172')

# Display the targets
echo "Found SNMP targets:"
echo "$SNMP_TARGETS"

# Check the docker network
echo "Checking Docker network..."
docker network ls

echo "SNMP setup complete!"
echo "To verify SNMP connectivity, run:"
echo "./test_snmp.sh <device_ip> public"
echo ""
echo "To restart the monitoring stack with new configuration:"
echo "docker-compose down && docker-compose up -d" 