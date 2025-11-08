#!/bin/bash

set -e

echo "===== Fixing SNMP Exporter ====="
docker stop snmp-exporter || true
docker rm snmp-exporter || true

cat > snmp/snmp.yml << 'EOF'
default:
  version: 2
  auth:
    community: public
  walk:
    - 1.3.6.1.2.1.1
    - 1.3.6.1.2.1.2
    - 1.3.6.1.2.1.25.1.1
  lookups:
    - source_indexes: [ifIndex]
      lookup: ifDescr
      drop_source_indexes: false
    - source_indexes: [ifIndex]
      lookup: ifType
      drop_source_indexes: false
EOF

docker run -d --name snmp-exporter -p 9116:9116 \
  -v $(pwd)/snmp/snmp.yml:/etc/snmp_exporter/snmp.yml \
  prom/snmp-exporter:v0.21.0

echo "===== Installing Suricata Prometheus Exporter ====="

sudo apt update
sudo apt install -y python3-pip
sudo pip3 install prometheus-client
sudo pip3 install prometheus-suricata-exporter || sudo pip3 install git+https://github.com/digitalocean/prometheus-suricata-exporter.git


sudo bash -c 'cat > /etc/systemd/system/suricata-exporter.service << EOF
[Unit]
Description=Suricata Prometheus Exporter
After=network.target suricata.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/prometheus-suricata-exporter --eve-file /var/log/suricata/eve.json --listen-port 9917
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable suricata-exporter
sudo systemctl start suricata-exporter || echo "Failed to start service, check if eve.json exists"

echo "===== Fixing Anomaly Detection Environment ====="

cd ~/anomaly_venv
. bin/activate
pip install prometheus-api-client numpy pandas scikit-learn matplotlib
deactivate

cd ~/ml-env
. bin/activate
pip install prometheus-api-client numpy pandas scikit-learn matplotlib
deactivate

cd ~/monitoring-stack

sudo bash -c 'cat > /etc/systemd/system/network-anomaly-detection.service << EOF
[Unit]
Description=Network Anomaly Detection Service
After=network.target

[Service]
Type=simple
User=alex
WorkingDirectory=/home/alex/monitoring-stack
ExecStart=/home/alex/anomaly_venv/bin/python3 /home/alex/monitoring-stack/network_anomaly_detection.py --prometheus_url=http://localhost:9090
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable network-anomaly-detection
sudo systemctl restart network-anomaly-detection || echo "Failed to start anomaly detection service"


echo "===== Reloading Prometheus Configuration ====="
curl -X POST http://localhost:9090/-/reload

echo "===== Done! ====="
echo "Check status with:"
echo "docker logs snmp-exporter"
echo "sudo systemctl status suricata-exporter"
echo "sudo systemctl status network-anomaly-detection" 