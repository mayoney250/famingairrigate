from flask import Flask, jsonify, render_template_string, request
import minimalmodbus
import serial
import serial.tools.list_ports
import threading
import time
import logging
from datetime import datetime
import csv
import os
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('sensor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# --- Firebase Setup ---
try:
    cred = credentials.Certificate("firebase_key.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    logger.info("Firebase Admin SDK initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Firebase: {e}")
    db = None

# --- Modbus RS485 Sensor Setup ---
instrument = None
instrument_lock = threading.Lock()

def list_available_ports():
    """List all available COM ports"""
    ports = serial.tools.list_ports.comports()
    logger.info("Available COM ports:")
    for port in ports:
        logger.info(f"  {port.device}: {port.description}")
    return ports

def initialize_sensor(port='COM6'):
    """Initialize Modbus sensor with proper port handling"""
    global instrument
    
    try:
        with instrument_lock:
            # Close existing connection if any
            if instrument is not None:
                try:
                    if hasattr(instrument, 'serial') and instrument.serial:
                        if instrument.serial.is_open:
                            instrument.serial.close()
                        time.sleep(0.5)  # Give the port time to close
                except Exception as e:
                    logger.warning(f"Error closing previous connection: {e}")
            
            # Create new instrument with proper settings
            instrument = minimalmodbus.Instrument(port, 1)
            instrument.serial.baudrate = 9600
            instrument.serial.bytesize = 8
            instrument.serial.parity = serial.PARITY_NONE
            instrument.serial.stopbits = 1
            instrument.serial.timeout = 1
            instrument.close_port_after_each_call = True  # CRITICAL: Close port between calls
            instrument.clear_buffers_before_each_transaction = True
            
            logger.info(f"Modbus sensor initialized on {port}")
            return True
            
    except Exception as e:
        logger.error(f"Failed to initialize sensor: {e}")
        instrument = None
        return False

# --- Global state with thread safety ---
data_lock = threading.Lock()
sensor_active = True
latest_data = {
    "moisture": 0,
    "temperature": 0,
    "timestamp": None,
    "status": "initializing",
    "moisture_status": "",
    "temp_status": ""
}

# CSV logging configuration
CSV_FILE = "sensor_data.csv"
ENABLE_CSV_LOGGING = True

def initialize_csv():
    """Initialize CSV file with headers if it doesn't exist"""
    if not os.path.exists(CSV_FILE):
        try:
            with open(CSV_FILE, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['timestamp', 'moisture', 'temperature'])
            logger.info(f"Created CSV file: {CSV_FILE}")
        except Exception as e:
            logger.error(f"Failed to create CSV file: {e}")

def log_to_csv(moisture, temperature):
    """Log sensor data to CSV file"""
    if not ENABLE_CSV_LOGGING:
        return
    try:
        with open(CSV_FILE, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                datetime.now().isoformat(),
                moisture,
                temperature
            ])
    except Exception as e:
        logger.error(f"Failed to write to CSV: {e}")

def evaluate_conditions(moisture, temperature):
    """Return status messages based on moisture and temperature levels."""
    if moisture < 30:
        moisture_status = "🌵 Too Dry — Irrigation Needed!"
    elif 30 <= moisture <= 60:
        moisture_status = "✅ Moisture Good"
    else:
        moisture_status = "💧 Too Wet — Check Drainage"

    if temperature < 10:
        temp_status = "❄️ Too Cold — Poor Growth"
    elif 10 <= temperature <= 35:
        temp_status = "🌿 Temperature Good"
    else:
        temp_status = "🔥 Too Hot — Stress Risk"

    return moisture_status, temp_status

def read_soil_sensor():
    """Background thread that continuously reads Modbus RS485 soil sensor data."""
    global sensor_active, instrument
    logger.info("Sensor thread started")
    
    consecutive_errors = 0
    max_consecutive_errors = 3
    last_success_time = time.time()

    while True:
        try:
            if sensor_active:
                if instrument is None:
                    logger.info("Initializing sensor connection...")
                    if initialize_sensor():
                        consecutive_errors = 0
                        time.sleep(1)  # Give sensor time to stabilize
                    else:
                        with data_lock:
                            latest_data["status"] = "error"
                        time.sleep(5)
                        continue

                try:
                    with instrument_lock:
                        # Read Modbus registers (holding registers 0 & 1)
                        moisture_raw = instrument.read_register(0, 0, 3)
                        time.sleep(0.1)  # Small delay between reads
                        temp_raw = instrument.read_register(1, 0, 3)
                    
                    # Reset error counter on successful read
                    consecutive_errors = 0
                    last_success_time = time.time()
                    
                    # Convert to engineering units
                    moisture = moisture_raw / 10.0
                    temperature = temp_raw / 10.0

                    # Evaluate conditions
                    moisture_status, temp_status = evaluate_conditions(moisture, temperature)

                    # Thread-safe data update
                    with data_lock:
                        latest_data["moisture"] = round(moisture, 1)
                        latest_data["temperature"] = round(temperature, 1)
                        latest_data["timestamp"] = time.time()
                        latest_data["status"] = "active"
                        latest_data["moisture_status"] = moisture_status
                        latest_data["moisture_status"] = moisture_status
                        latest_data["temp_status"] = temp_status

                    # Upload to Firestore
                    if db:
                        try:
                            doc_ref = db.collection('faminga_sensors').document('latest')
                            doc_ref.set({
                                'moisture': round(moisture, 1),
                                'temperature': round(temperature, 1),
                                'moisture_status': moisture_status,
                                'temp_status': temp_status,     
                                'timestamp': firestore.SERVER_TIMESTAMP
                            })
                            logger.info("Data uploaded to Firestore")
                        except Exception as e:
                            logger.error(f"Failed to upload to Firestore: {e}")

                    # Log to CSV
                    log_to_csv(moisture, temperature)

                    logger.info(f"Read: {moisture:.1f}% moisture, {temperature:.1f}°C")
                
                except (serial.SerialException, PermissionError, OSError) as e:
                    consecutive_errors += 1
                    logger.error(f"Communication error ({consecutive_errors}/{max_consecutive_errors}): {e}")
                    
                    if consecutive_errors >= max_consecutive_errors:
                        logger.error("Too many errors, reinitializing sensor...")
                        with instrument_lock:
                            if instrument and hasattr(instrument, 'serial'):
                                try:
                                    instrument.serial.close()
                                except:
                                    pass
                            instrument = None
                        consecutive_errors = 0
                    
                    with data_lock:
                        latest_data["status"] = "error"
                    time.sleep(2)
                    continue
                
                except minimalmodbus.NoResponseError:
                    consecutive_errors += 1
                    logger.error(f"No response from sensor ({consecutive_errors}/{max_consecutive_errors})")
                    if consecutive_errors >= max_consecutive_errors:
                        with instrument_lock:
                            instrument = None
                    with data_lock:
                        latest_data["status"] = "error"
                    time.sleep(2)
                    continue
                
                except minimalmodbus.InvalidResponseError as e:
                    consecutive_errors += 1
                    logger.error(f"Invalid response: {e}")
                    if consecutive_errors >= max_consecutive_errors:
                        with instrument_lock:
                            instrument = None
                    with data_lock:
                        latest_data["status"] = "error"
                    time.sleep(2)
                    continue

            else:
                # Sensor is stopped
                with data_lock:
                    latest_data["status"] = "stopped"

            time.sleep(5)  # Read every 5 seconds

        except Exception as e:
            logger.error(f"Unexpected error: {e}", exc_info=True)
            with data_lock:
                latest_data["status"] = "error"
            time.sleep(5)

# --- HTML page with Chart.js dashboard ---
HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>FAMINGA Soil Reader</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Poppins', sans-serif;
            background: #F5F5F5;
            padding: 20px;
            min-height: 100vh;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding: 30px;
            background: white;
            border-radius: 20px;
            border-bottom: 4px solid #FFA500;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }
        
        .logo {
            font-size: 48px;
            font-weight: 700;
            color: #1a1a1a;
            margin-bottom: 5px;
        }
        
        .logo-accent {
            color: #FFA500;
        }
        
        .subtitle {
            color: #666;
            font-size: 14px;
            letter-spacing: 3px;
            text-transform: uppercase;
            font-weight: 600;
        }
        
        .container { 
            max-width: 1400px; 
            margin: 0 auto;
        }
        
        .status-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 20px 30px;
            margin-bottom: 30px;
            background: white;
            border-radius: 15px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }
        
        .status-indicator {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        
        .status-dot.active { background: #00cc66; box-shadow: 0 0 10px #00cc66; }
        .status-dot.error { background: #ff4444; box-shadow: 0 0 10px #ff4444; }
        .status-dot.stopped { background: #FFA500; box-shadow: 0 0 10px #FFA500; }
        .status-dot.initializing { background: #0099ff; box-shadow: 0 0 10px #0099ff; }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.2); opacity: 0.7; }
        }
        
        .status-text {
            color: #1a1a1a;
            font-size: 16px;
            font-weight: 600;
        }
        
        .last-update {
            color: #666;
            font-size: 14px;
            font-weight: 500;
        }
        
        .metrics-grid { 
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px; 
            margin-bottom: 30px; 
        }
        
        .metric-card { 
            position: relative;
            padding: 35px;
            background: white;
            border-radius: 20px;
            overflow: hidden;
            transition: all 0.3s ease;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }
        
        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.12);
        }
        
        .metric-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: #FFA500;
        }
        
        .metric-icon {
            font-size: 56px;
            margin-bottom: 15px;
            filter: grayscale(0.3);
        }
        
        .metric-label {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 2px;
            color: #888;
            font-weight: 700;
            margin-bottom: 10px;
        }
        
        .metric-value { 
            font-size: 64px; 
            font-weight: 700; 
            color: #1a1a1a;
            margin: 15px 0;
        }
        
        .metric-unit {
            font-size: 28px;
            color: #666;
            font-weight: 500;
        }
        
        .metric-status {
            font-size: 14px;
            margin-top: 15px;
            padding: 10px 16px;
            background: #f8f8f8;
            border-radius: 8px;
            border-left: 3px solid #FFA500;
            color: #333;
            font-weight: 500;
        }
        
        .controls {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin: 30px 0;
        }
        
        button { 
            padding: 15px 40px; 
            font-size: 16px; 
            cursor: pointer;
            background: linear-gradient(135deg, #FFA500 0%, #FF8C00 100%);
            color: white;
            border: none;
            border-radius: 50px;
            font-weight: 600;
            transition: all 0.3s;
            box-shadow: 0 5px 20px rgba(255, 165, 0, 0.4);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        button:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 30px rgba(255, 165, 0, 0.6);
            background: linear-gradient(135deg, #FF8C00 0%, #FFA500 100%);
        }
        
        button:active {
            transform: translateY(-1px);
        }
        
        .chart-section {
            margin-top: 40px;
            padding: 35px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }
        
        .chart-header {
            color: #1a1a1a;
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .chart-header::before {
            content: '📊';
            font-size: 32px;
        }
        
        canvas {
            background: #fafafa;
            border-radius: 12px;
            padding: 15px;
        }
        
        @media (max-width: 768px) {
            .logo { font-size: 36px; }
            .metrics-grid { grid-template-columns: 1fr; }
            .metric-value { font-size: 42px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🌱 <span class="logo-accent">FAMINGA</span></div>
            <div class="subtitle">Soil Monitoring System</div>
        </div>
        
        <div class="status-bar">
            <div class="status-indicator">
                <div id="status-dot" class="status-dot initializing"></div>
                <div class="status-text" id="status-text">Initializing...</div>
            </div>
            <div class="last-update" id="last-update">Waiting for data...</div>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-icon">💧</div>
                <div class="metric-label">Soil Moisture</div>
                <div class="metric-value">
                    <span id="moisture">--</span><span class="metric-unit">%</span>
                </div>
                <div class="metric-status" id="moisture-status">Waiting for data...</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-icon">🌡️</div>
                <div class="metric-label">Temperature</div>
                <div class="metric-value">
                    <span id="temperature">--</span><span class="metric-unit">°C</span>
                </div>
                <div class="metric-status" id="temp-status">Waiting for data...</div>
            </div>
        </div>
        
        <div class="controls">
            <button onclick="toggleSensor()">⚡ Toggle Sensor</button>
        </div>
        
        <div class="chart-section">
            <div class="chart-header">Real-Time Data Analytics</div>
            <canvas id="chart"></canvas>
        </div>
    </div>

    <script>
        const moistureData = [];
        const tempData = [];
        const labels = [];
        
        const ctx = document.getElementById('chart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Moisture (%)',
                    data: moistureData,
                    borderColor: '#FFA500',
                    backgroundColor: 'rgba(255, 165, 0, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointRadius: 4,
                    pointBackgroundColor: '#FFA500',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }, {
                    label: 'Temperature (°C)',
                    data: tempData,
                    borderColor: '#00ff88',
                    backgroundColor: 'rgba(0, 255, 136, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointRadius: 4,
                    pointBackgroundColor: '#00ff88',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: {
                            color: '#1a1a1a',
                            font: { size: 14, weight: 600 },
                            padding: 20
                        }
                    }
                },
                scales: {
                    y: { 
                        beginAtZero: true,
                        grid: { color: 'rgba(0, 0, 0, 0.06)' },
                        ticks: { color: '#666', font: { size: 12, weight: 500 } }
                    },
                    x: {
                        grid: { color: 'rgba(0, 0, 0, 0.06)' },
                        ticks: { color: '#666', font: { size: 12, weight: 500 } }
                    }
                }
            }
        });

        function updateData() {
            fetch('/data')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('moisture').textContent = data.moisture;
                    document.getElementById('temperature').textContent = data.temperature;
                    document.getElementById('moisture-status').textContent = data.moisture_status;
                    document.getElementById('temp-status').textContent = data.temp_status;
                    
                    const statusDot = document.getElementById('status-dot');
                    const statusText = document.getElementById('status-text');
                    statusDot.className = 'status-dot ' + data.status;
                    statusText.textContent = 'Status: ' + data.status.toUpperCase();
                    
                    const now = new Date();
                    document.getElementById('last-update').textContent = 
                        'Last Update: ' + now.toLocaleTimeString();
                    
                    const time = now.toLocaleTimeString();
                    labels.push(time);
                    moistureData.push(data.moisture);
                    tempData.push(data.temperature);
                    
                    if (labels.length > 30) {
                        labels.shift();
                        moistureData.shift();
                        tempData.shift();
                    }
                    
                    chart.update('none');
                })
                .catch(err => {
                    console.error('Failed to fetch data:', err);
                });
        }

        function toggleSensor() {
            fetch('/toggle', {method: 'POST'})
                .then(r => r.json())
                .then(data => {
                    const message = data.active ? '✅ Sensor Activated' : '⏸️ Sensor Stopped';
                    alert(message);
                    updateData();
                })
                .catch(err => alert('❌ Failed to toggle sensor'));
        }

        setInterval(updateData, 3000);
        updateData();
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_PAGE)

@app.route('/data')
def get_data():
    try:
        with data_lock:
            data = latest_data.copy()
        return jsonify(data)
    except Exception as e:
        logger.error(f"Error serving data: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/toggle', methods=['POST'])
def toggle_sensor():
    global sensor_active
    try:
        sensor_active = not sensor_active
        logger.info(f"Sensor {'activated' if sensor_active else 'deactivated'}")
        return jsonify({"active": sensor_active})
    except Exception as e:
        logger.error(f"Error toggling sensor: {e}")
        return jsonify({"error": "Failed to toggle sensor"}), 500

@app.route('/health')
def health_check():
    with data_lock:
        status = latest_data.get("status", "unknown")
        timestamp = latest_data.get("timestamp")
    is_healthy = status == "active" and timestamp and (time.time() - timestamp) < 10
    return jsonify({
        "status": "healthy" if is_healthy else "unhealthy",
        "sensor_active": sensor_active,
        "last_reading": timestamp
    }), 200 if is_healthy else 503

# --- Initialize and start ---
if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("Starting FAMINGA Soil Reader")
    logger.info("=" * 60)
    
    # List available ports
    list_available_ports()

    if ENABLE_CSV_LOGGING:
        initialize_csv()

    # Start sensor thread (it will initialize on its own)
    sensor_thread = threading.Thread(target=read_soil_sensor, daemon=True)
    sensor_thread.start()

    logger.info("Web server starting on http://0.0.0.0:2000")
    logger.info("Access dashboard at http://localhost:2000")
    
    app.run(host='0.0.0.0', port=2000, debug=False)

