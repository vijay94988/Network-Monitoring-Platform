#!/usr/bin/env python3
import time
import random
from http.server import HTTPServer, BaseHTTPRequestHandler

class MockSuricata(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        metrics = []
        
        # Generate mock Suricata metrics
        
        # Events count
        metrics.append('# HELP suricata_events_total Total number of Suricata events')
        metrics.append('# TYPE suricata_events_total counter')
        metrics.append(f'suricata_events_total{{type="alert"}} {random.randint(100, 500)}')
        metrics.append(f'suricata_events_total{{type="flow"}} {random.randint(5000, 10000)}')
        metrics.append(f'suricata_events_total{{type="http"}} {random.randint(2000, 5000)}')
        metrics.append(f'suricata_events_total{{type="dns"}} {random.randint(1000, 3000)}')
        metrics.append(f'suricata_events_total{{type="tls"}} {random.randint(500, 2000)}')
        
        # Alerts by category
        metrics.append('# HELP suricata_alerts_total Total number of Suricata alerts by category')
        metrics.append('# TYPE suricata_alerts_total counter')
        metrics.append(f'suricata_alerts_total{{category="malware"}} {random.randint(10, 50)}')
        metrics.append(f'suricata_alerts_total{{category="command-and-control"}} {random.randint(5, 20)}')
        metrics.append(f'suricata_alerts_total{{category="intrusion"}} {random.randint(20, 100)}')
        metrics.append(f'suricata_alerts_total{{category="network-scan"}} {random.randint(50, 200)}')
        
        # Stats
        metrics.append('# HELP suricata_uptime_seconds Suricata uptime in seconds')
        metrics.append('# TYPE suricata_uptime_seconds gauge')
        metrics.append(f'suricata_uptime_seconds {random.randint(3600, 86400)}')
        
        metrics.append('# HELP suricata_drop_packets_total Number of packets dropped by Suricata')
        metrics.append('# TYPE suricata_drop_packets_total counter')
        metrics.append(f'suricata_drop_packets_total {random.randint(10, 1000)}')
        
        # Join and encode all metrics
        metrics_text = '\n'.join(metrics) + '\n'
        self.wfile.write(metrics_text.encode())
        
    def log_message(self, format, *args):
        # Suppress logging to keep output clean
        return

def run(server_class=HTTPServer, handler_class=MockSuricata, port=9917):
    server_address = ('0.0.0.0', port)  # Bind to all interfaces
    httpd = server_class(server_address, handler_class)
    print(f"Starting mock Suricata exporter on port {port}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run() 