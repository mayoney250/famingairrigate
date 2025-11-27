# Script to add live sensor subscription to dashboard provider
# Run this from the project root: .\update_dashboard_provider.ps1

$file = "lib\providers\dashboard_provider.dart"
$content = Get-Content $file -Raw

Write-Host "Updating dashboard_provider.dart..." -ForegroundColor Cyan

# 1. Replace _avgSoilMoisture with _liveSensorData in state variables
$content = $content -replace 'double\? _avgSoilMoisture; // Add field', @'
  
  // Live sensor data from /sensors/faminga_2in1_sensor/latest/current
  SensorDataModel? _liveSensorData;
'@

Write-Host "Updated state variables" -ForegroundColor Green

# 2. Replace avgSoilMoisture getter with liveSensorData
$content = $content -replace 'double\? get avgSoilMoisture => _avgSoilMoisture;', @'
  
  // Live sensor data from Firestore
  SensorDataModel? get liveSensorData => _liveSensorData;
'@

Write-Host "Updated getters" -ForegroundColor Green

# 3. Update systemStatus to use liveSensorData
$oldSystemStatus = @'
  // Get system status
  String get systemStatus {
    if (_avgSoilMoisture == null || _avgSoilMoisture! < 40) {
      return 'Attention Required';
    } else if (_avgSoilMoisture! >= 60 && _avgSoilMoisture! <= 80) {
      return 'Optimal';
    } else {
      return 'Good';
    }
  }
'@

$newSystemStatus = @'
  // Get system status based on live sensor data
  String get systemStatus {
    if (_liveSensorData == null) {
      return 'No Data';
    }
    
    final moisture = _liveSensorData!.soilMoisture;
    if (moisture < 40) {
      return 'Attention Required';
    } else if (moisture >= 60 && moisture <= 80) {
      return 'Optimal';
    } else {
      return 'Good';
    }
  }
'@

$content = $content -replace [regex]::Escape($oldSystemStatus), $newSystemStatus

Write-Host "Updated systemStatus method" -ForegroundColor Green

# 4. Replace _refreshDailySoilAverage call with _subscribeLiveSensor
$content = $content -replace 'await _refreshDailySoilAverage\(\)\.timeout\(const Duration\(seconds: 10\)\)\.catchError\(\(e\) \{[^}]+\}\);', @'
// Subscribe to live sensor data from new path
          _subscribeLiveSensor();
'@

Write-Host "Updated loadDashboardData to call _subscribeLiveSensor" -ForegroundColor Green

# 5. Add _subscribeLiveSensor method before the closing brace of the class
$subscribeLiveSensorMethod = @'

  // ===== LIVE SENSOR SUBSCRIPTION =====
  
  /// Subscribe to live sensor data from /sensors/faminga_2in1_sensor/latest/current
  void _subscribeLiveSensor() {
    dev.log('[DASHBOARD] Subscribing to live sensor stream');
    
    _sensorDataService.streamLiveSensor().listen((sensorData) {
      dev.log('[DASHBOARD] Live sensor update: moisture=${sensorData?.soilMoisture}, temp=${sensorData?.temperature}');
      
      if (sensorData != null) {
        _liveSensorData = sensorData;
        
        // Log staleness
        if (sensorData.isStale) {
          dev.log('[DASHBOARD] Sensor data is STALE: ${sensorData.stalenessMessage}');
        } else {
          dev.log('[DASHBOARD] Sensor data is fresh: ${sensorData.stalenessMessage}');
        }
        
        notifyListeners();
      }
    }, onError: (error) {
      dev.log('[DASHBOARD] Error in live sensor stream: $error');
    });
  }
}
'@

# Find the last closing brace and replace it
$content = $content -replace '\}\s*$', $subscribeLiveSensorMethod

Write-Host "Added _subscribeLiveSensor method" -ForegroundColor Green

# Save the file
$content | Set-Content $file -NoNewline

Write-Host ""
Write-Host "Dashboard provider updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Add userId and fieldId to /sensors/faminga_2in1_sensor/latest/current in Firestore"
Write-Host "2. Hot reload the app (press 'r' in Flutter terminal)"
Write-Host "3. Check console for [DASHBOARD] and [LIVE SENSOR] logs"
Write-Host ""
