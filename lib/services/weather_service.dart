import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // OpenWeatherMap API key (You need to get your own from openweathermap.org)
  // For now, using a placeholder
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get weather by city name
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromOpenWeatherMap(data);
      } else {
        log('Weather API error: ${response.statusCode}');
        return _getMockWeather();
      }
    } catch (e) {
      log('Error fetching weather: $e');
      return _getMockWeather();
    }
  }

  // Get weather by coordinates
  Future<WeatherData?> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromOpenWeatherMap(data);
      } else {
        log('Weather API error: ${response.statusCode}');
        return _getMockWeather();
      }
    } catch (e) {
      log('Error fetching weather: $e');
      return _getMockWeather();
    }
  }

  // Get mock weather data (fallback)
  WeatherData _getMockWeather() {
    return WeatherData(
      temperature: 26.0,
      feelsLike: 28.0,
      humidity: 65,
      condition: 'sunny',
      description: 'Clear sky',
      windSpeed: 3.5,
      pressure: 1013,
      timestamp: DateTime.now(),
      location: 'Kigali',
    );
  }

  // Get weather for default location (Kigali, Rwanda)
  Future<WeatherData?> getDefaultWeather() async {
    return await getWeatherByCity('Kigali');
  }

  // Check if weather is good for irrigation
  bool isGoodForIrrigation(WeatherData weather) {
    // Don't irrigate if it's raining or about to rain
    if (weather.condition == 'rainy' || weather.condition == 'stormy') {
      return false;
    }
    // Don't irrigate if temperature is too high (evaporation)
    if (weather.temperature > 35) {
      return false;
    }
    return true;
  }

  // Get irrigation recommendation based on weather
  String getIrrigationRecommendation(WeatherData weather) {
    if (weather.condition == 'rainy') {
      return 'Rain expected. Skip irrigation today.';
    } else if (weather.temperature > 30) {
      return 'Hot weather. Irrigate early morning or evening.';
    } else if (weather.humidity > 80) {
      return 'High humidity. Reduce irrigation duration.';
    } else {
      return 'Good weather conditions for irrigation.';
    }
  }
}

