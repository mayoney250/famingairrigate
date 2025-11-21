import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherDataModel {
  final String id;
  final String userId;
  final String location;
  final double temperature; // Celsius
  final double humidity; // Percentage
  final String condition; // Sunny, Cloudy, Rainy, etc.
  final String description;
  final DateTime timestamp;
  final DateTime? lastUpdated;

  WeatherDataModel({
    required this.id,
    required this.userId,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.timestamp,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      'temperature': temperature,
      'humidity': humidity,
      'condition': condition,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory WeatherDataModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return WeatherDataModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      location: map['location'] ?? '',
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      condition: map['condition'] ?? 'Clear',
      description: map['description'] ?? '',
      timestamp: parseDate(map['timestamp']),
      lastUpdated: map['lastUpdated'] != null ? parseDate(map['lastUpdated']) : null,
    );
  }

  factory WeatherDataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeatherDataModel.fromMap(data);
  }

  String get weatherIcon {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'clouds':
      case 'cloudy':
        return '☁️';
      case 'rain':
      case 'rainy':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      default:
        return '☁️';
    }
  }

  String get temperatureDisplay => '${temperature.toStringAsFixed(0)}°C';
}

