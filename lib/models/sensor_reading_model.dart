class SensorReading {
  final String readingId;
  final String sensorId;
  final String sensorType; // soil_moisture, temperature, humidity, ph, light
  final String farmId;
  final String fieldId;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SensorReading({
    required this.readingId,
    required this.sensorId,
    required this.sensorType,
    required this.farmId,
    required this.fieldId,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'readingId': readingId,
      'sensorId': sensorId,
      'sensorType': sensorType,
      'farmId': farmId,
      'fieldId': fieldId,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      readingId: map['readingId'] ?? '',
      sensorId: map['sensorId'] ?? '',
      sensorType: map['sensorType'] ?? '',
      farmId: map['farmId'] ?? '',
      fieldId: map['fieldId'] ?? '',
      value: map['value']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }

  // Get formatted value with unit
  String get formattedValue {
    if (sensorType == 'temperature') {
      return '${value.toStringAsFixed(1)}$unit';
    } else if (sensorType == 'soil_moisture' || sensorType == 'humidity') {
      return '${value.toInt()}$unit';
    } else {
      return '${value.toStringAsFixed(2)}$unit';
    }
  }

  // Check if reading is recent (within last hour)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 1;
  }
}

