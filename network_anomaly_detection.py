#!/usr/bin/env python3

import time
import numpy as np
import pandas as pd
from prometheus_api_client import PrometheusConnect
from sklearn.ensemble import IsolationForest
import requests
import logging
import argparse

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("anomaly_detection.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Parse command line arguments
parser = argparse.ArgumentParser(description='Network Traffic Anomaly Detection')
parser.add_argument('--prometheus_url', default='http://localhost:9090', help='Prometheus URL')
parser.add_argument('--alertmanager_url', default='http://localhost:9093', help='AlertManager URL')
parser.add_argument('--interval', type=int, default=300, help='Sampling interval in seconds')
parser.add_argument('--training_period', type=int, default=24, help='Training period in hours')
args = parser.parse_args()

# Connect to Prometheus
prom = PrometheusConnect(url=args.prometheus_url, disable_ssl=True)

def get_network_metrics(time_range='1h'):
    """
    Fetch network traffic metrics from Prometheus
    """
    try:
        # Get network traffic rates
        receive_query = f'rate(node_network_receive_bytes_total[5m])'
        transmit_query = f'rate(node_network_transmit_bytes_total[5m])'
        
        receive_data = prom.custom_query(query=receive_query)
        transmit_data = prom.custom_query(query=transmit_query)
        
        # Get error rates
        rx_errors_query = f'rate(node_network_receive_errs_total[5m])'
        tx_errors_query = f'rate(node_network_transmit_errs_total[5m])'
        
        rx_errors_data = prom.custom_query(query=rx_errors_query)
        tx_errors_data = prom.custom_query(query=tx_errors_query)
        
        return {
            'receive_data': receive_data,
            'transmit_data': transmit_data,
            'rx_errors_data': rx_errors_data,
            'tx_errors_data': tx_errors_data
        }
    except Exception as e:
        logger.error(f"Error getting network metrics: {e}")
        return None

def prepare_data(metrics):
    """
    Prepare metrics data for anomaly detection
    """
    if not metrics:
        return None
    
    # Initialize empty DataFrame
    df = pd.DataFrame()
    
    # Process receive data
    for item in metrics['receive_data']:
        if 'value' in item:
            instance = item['metric'].get('instance', 'unknown')
            device = item['metric'].get('device', 'unknown')
            df.loc[f"{instance}_{device}", 'receive_bytes'] = float(item['value'][1])
    
    # Process transmit data
    for item in metrics['transmit_data']:
        if 'value' in item:
            instance = item['metric'].get('instance', 'unknown')
            device = item['metric'].get('device', 'unknown')
            df.loc[f"{instance}_{device}", 'transmit_bytes'] = float(item['value'][1])
    
    # Process error data
    for item in metrics.get('rx_errors_data', []):
        if 'value' in item:
            instance = item['metric'].get('instance', 'unknown')
            device = item['metric'].get('device', 'unknown')
            df.loc[f"{instance}_{device}", 'rx_errors'] = float(item['value'][1])
    
    for item in metrics.get('tx_errors_data', []):
        if 'value' in item:
            instance = item['metric'].get('instance', 'unknown')
            device = item['metric'].get('device', 'unknown')
            df.loc[f"{instance}_{device}", 'tx_errors'] = float(item['value'][1])
    
    # Fill NaN values with 0
    df = df.fillna(0)
    
    # Calculate total traffic
    df['total_traffic'] = df['receive_bytes'] + df['transmit_bytes']
    df['total_errors'] = df.get('rx_errors', 0) + df.get('tx_errors', 0)
    
    return df

def train_model(data_frames):
    """
    Train an anomaly detection model using historical data
    """
    if not data_frames or len(data_frames) == 0:
        logger.error("No data available for training")
        return None
    
    # Concatenate all historical data
    combined_data = pd.concat(data_frames)
    
    # Train Isolation Forest model
    model = IsolationForest(contamination=0.05, random_state=42)
    model.fit(combined_data[['total_traffic', 'total_errors']])
    
    logger.info("Anomaly detection model trained successfully")
    return model

def detect_anomalies(model, current_data):
    """
    Detect anomalies in current network data
    """
    if model is None or current_data is None or current_data.empty:
        return []
    
    # Predict anomalies (-1 for anomalies, 1 for normal)
    predictions = model.predict(current_data[['total_traffic', 'total_errors']])
    anomaly_scores = model.decision_function(current_data[['total_traffic', 'total_errors']])
    
    # Find anomalies
    anomalies = []
    for i, (idx, row) in enumerate(current_data.iterrows()):
        if predictions[i] == -1:
            anomaly = {
                'device': idx,
                'traffic': row['total_traffic'],
                'errors': row['total_errors'],
                'score': anomaly_scores[i],
                'timestamp': time.time()
            }
            anomalies.append(anomaly)
    
    return anomalies

def send_alert(anomalies):
    """
    Send alerts to AlertManager for detected anomalies
    """
    if not anomalies:
        return
    
    alerts = []
    for anomaly in anomalies:
        alert = {
            'labels': {
                'alertname': 'NetworkTrafficAnomaly',
                'severity': 'warning',
                'device': anomaly['device']
            },
            'annotations': {
                'summary': f"Anomalous network traffic detected on {anomaly['device']}",
                'description': (
                    f"Traffic: {anomaly['traffic']:.2f} bytes/sec, "
                    f"Errors: {anomaly['errors']:.2f}/sec, "
                    f"Anomaly score: {anomaly['score']:.4f}"
                )
            },
            'startsAt': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(anomaly['timestamp']))
        }
        alerts.append(alert)
    
    try:
        response = requests.post(
            f"{args.alertmanager_url}/api/v1/alerts",
            json=alerts
        )
        if response.status_code == 200:
            logger.info(f"Sent {len(alerts)} alerts to AlertManager")
        else:
            logger.error(f"Failed to send alerts: {response.status_code} - {response.text}")
    except Exception as e:
        logger.error(f"Error sending alerts: {e}")

def main():
    logger.info("Starting network anomaly detection service")
    
    # Historical data for training
    historical_data = []
    
    # Main monitoring loop
    while True:
        try:
            # Get current network metrics
            metrics = get_network_metrics()
            current_data = prepare_data(metrics)
            
            if current_data is not None and not current_data.empty:
                # Add to historical data
                historical_data.append(current_data)
                
                # Keep only the last N hours of data for training
                max_samples = (args.training_period * 3600) // args.interval
                if len(historical_data) > max_samples:
                    historical_data.pop(0)
                
                # Train model if we have enough data
                if len(historical_data) >= 5:  # Need some minimum amount of data
                    model = train_model(historical_data)
                    
                    # Detect anomalies
                    anomalies = detect_anomalies(model, current_data)
                    
                    if anomalies:
                        logger.warning(f"Detected {len(anomalies)} anomalies")
                        for anomaly in anomalies:
                            logger.warning(f"Anomaly on {anomaly['device']}: "
                                         f"Traffic={anomaly['traffic']:.2f}, "
                                         f"Errors={anomaly['errors']:.2f}, "
                                         f"Score={anomaly['score']:.4f}")
                        
                        # Send alerts
                        send_alert(anomalies)
            
            # Wait for next collection interval
            time.sleep(args.interval)
            
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(60)  # Wait a bit before retrying

if __name__ == "__main__":
    main() 