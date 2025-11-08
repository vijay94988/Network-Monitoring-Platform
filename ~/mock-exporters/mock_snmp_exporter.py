#!/usr/bin/env python3
import time
import random
from http.server import HTTPServer, BaseHTTPRequestHandler

class MockSNMP(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        metrics = []
        
        # Generate mock SNMP metrics for router interfaces
        interfaces = ['eth0', 'eth1', 'wlan0', 'wlan1']
        
        # Device info
        metrics.append('# HELP snmp_device_info Device information')
        metrics.append('# TYPE snmp_device_info gauge')
        metrics.append('snmp_device_info{name="Router",model="TP-Link AC1750",version="2.4"} 1')
        
        # Interface metrics
        metrics.append('# HELP snmp_interface_speed_bps Interface speed in bits per second')
        metrics.append('# TYPE snmp_interface_speed_bps gauge')
        metrics.append('# HELP snmp_interface_in_octets_total Incoming traffic in octets')
        metrics.append('# TYPE snmp_interface_in_octets_total counter')
        metrics.append('# HELP snmp_interface_out_octets_total Outgoing traffic in octets')
        metrics.append('# TYPE snmp_interface_out_octets_total counter')
        metrics.append('# HELP snmp_interface_status Interface status (1=up, 0=down)')
        metrics.append('# TYPE snmp_interface_status gauge')
        
        for interface in interfaces:
            speed = 1000000000 if interface.startswith('eth') else 300000000
            metrics.append(f'snmp_interface_speed_bps{{interface="{interface}"}} {speed}')
            metrics.append(f'snmp_interface_in_octets_total{{interface="{interface}"}} {random.randint(1000000, 5000000)}')
            metrics.append(f'snmp_interface_out_octets_total{{interface="{interface}"}} {random.randint(500000, 2000000)}')
            metrics.append(f'snmp_interface_status{{interface="{interface}"}} 1')
        
        # CPU and memory
        metrics.append('# HELP snmp_cpu_load_percentage CPU load percentage')
        metrics.append('# TYPE snmp_cpu_load_percentage gauge')
        metrics.append(f'snmp_cpu_load_percentage {{device="router"}} {random.randint(20, 80)}')
        
        metrics.append('# HELP snmp_memory_usage_percentage Memory usage percentage')
        metrics.append('# TYPE snmp_memory_usage_percentage gauge')
        metrics.append(f'snmp_memory_usage_percentage {{device="router"}} {random.randint(30, 90)}')
        
        # Join and encode all metrics
        metrics_text = '\n'.join(metrics) + '\n'
        self.wfile.write(metrics_text.encode())
        
    def log_message(self, format, *args):
        # Suppress logging to keep output clean
        return

def run(server_class=HTTPServer, handler_class=MockSNMP, port=9116):
    server_address = ('0.0.0.0', port)  # Bind to all interfaces
    httpd = server_class(server_address, handler_class)
    print(f"Starting mock SNMP exporter on port {port}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run() 