# Importing the Network Monitoring Dashboard into Grafana

Follow these steps to import the custom Network Monitoring Dashboard into your Grafana instance:

# Copy the Dashboard JSON

The dashboard configuration is stored in the `network_monitoring_dashboard.json` file.

# Import into Grafana

1. Open your Grafana instance in a web browser (http://your-server-ip:3000)
2. Log in with your credentials (default: admin/admin)
3. Click on the "+" icon in the left sidebar
4. Select "Import" from the dropdown menu
5. In the "Import via panel json" section, paste the entire content of the `network_monitoring_dashboard.json` file
6. Click "Load"
7. Set the name for your dashboard (or keep the default "Network Monitoring Dashboard")
8. Make sure to select "prometheus" as the data source in the dropdown
9. Click "Import"

# Configure Data Source

If you don't have a Prometheus data source configured:

1. Go to Configuration (gear icon) > Data Sources
2. Click "Add data source"
3. Select "Prometheus"
4. Set the URL to `http://prometheus:9090` (if using Docker) or `http://localhost:9090` (if running locally)
5. Click "Save & Test"

# Dashboard Features

This dashboard includes:
- Network traffic in/out metrics
- CPU and memory usage gauges
- Network errors monitoring
- Service status overview
- Network interface status
- Anomaly detection visualization based on network traffic patterns

# Troubleshooting

If you don't see data:
1. Make sure Prometheus is running and collecting data
2. Verify the Node Exporter is working properly
3. Check the time range in the upper right corner of Grafana 