class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String condition; // sunny, cloudy, rainy, etc.
  final String description;
  final double windSpeed;
  final int pressure;
  final DateTime timestamp;
  final String location;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.windSpeed,
    required this.pressure,
    required this.timestamp,
    required this.location,
  });

  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> map) {
    final main = map['main'] ?? {};
    final weather = (map['weather'] as List?)?.first ?? {};
    final wind = map['wind'] ?? {};

    return WeatherData(
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      condition: _mapWeatherCondition(weather['main'] ?? ''),
      description: weather['description'] ?? '',
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      pressure: main['pressure'] ?? 0,
      timestamp: DateTime.now(),
      location: map['name'] ?? 'Unknown',
    );
  }

  // Map OpenWeatherMap condition to our internal format
  static String _mapWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'sunny';
      case 'clouds':
        return 'cloudy';
      case 'rain':
      case 'drizzle':
        return 'rainy';
      case 'thunderstorm':
        return 'stormy';
      case 'snow':
        return 'snowy';
      default:
        return 'unknown';
    }
  }

  // Get weather icon based on condition
  String get iconName {
    switch (condition) {
      case 'sunny':
        return 'wb_sunny';
      case 'cloudy':
        return 'cloud';
      case 'rainy':
        return 'water_drop';
      case 'stormy':
        return 'thunderstorm';
      case 'snowy':
        return 'ac_unit';
      default:
        return 'help_outline';
    }
  }

  // Format temperature
  String get temperatureString => '${temperature.round()}°C';
  String get feelsLikeString => '${feelsLike.round()}°C';
  String get humidityString => '$humidity%';
<<<<<<< HEAD
=======
  
  Map<String, dynamic> toMap() => {
    'temperature': temperature,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'condition': condition,
    'description': description,
    'windSpeed': windSpeed,
    'pressure': pressure,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'location': location,
  };
  
  factory WeatherData.fromMap(Map<String, dynamic> m) => WeatherData(
    temperature: (m['temperature'] ?? 0).toDouble(),
    feelsLike: (m['feelsLike'] ?? 0).toDouble(),
    humidity: (m['humidity'] ?? 0).toInt(),
    condition: (m['condition'] ?? 'unknown').toString(),
    description: (m['description'] ?? '').toString(),
    windSpeed: (m['windSpeed'] ?? 0).toDouble(),
    pressure: (m['pressure'] ?? 0).toInt(),
    timestamp: DateTime.fromMillisecondsSinceEpoch((m['timestamp'] ?? DateTime.now().millisecondsSinceEpoch).toInt()),
    location: (m['location'] ?? 'Unknown').toString(),
  );
>>>>>>> hyacinthe
}

