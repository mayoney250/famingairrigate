class ForecastDay {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double windSpeed;
  final double rainMm;
  final double pop; // Probability of precipitation (0-1)
  final String status; // Rain, Clear, Clouds, etc.
  final int humidity;

  ForecastDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.windSpeed,
    required this.rainMm,
    required this.pop,
    required this.status,
    this.humidity = 0,
  });

  factory ForecastDay.fromMap(Map<String, dynamic> map) {
    return ForecastDay(
      date: DateTime.parse(map['date'] as String),
      tempMin: (map['tempMin'] ?? 0).toDouble(),
      tempMax: (map['tempMax'] ?? 0).toDouble(),
      windSpeed: (map['windSpeed'] ?? 0).toDouble(),
      rainMm: (map['rainMm'] ?? 0).toDouble(),
      pop: (map['pop'] ?? 0).toDouble(),
      status: (map['status'] ?? 'Clear').toString(),
      humidity: (map['humidity'] ?? 0).toInt(),
    );
  }

  String get tempMaxString => '${tempMax.round()}°';
  String get tempMinString => '${tempMin.round()}°';
  String get popPercentage => '${(pop * 100).round()}%';
  String get windSpeedString => '${windSpeed.toStringAsFixed(1)} m/s';
  String get rainAmountString => '${rainMm.toStringAsFixed(1)} mm';
  String get humidityString => '$humidity%';
  
  String get dayName {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date == today) return 'Today';
    if (date == tomorrow) return 'Tomorrow';
    
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
