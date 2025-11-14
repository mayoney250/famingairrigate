import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;

  final Map<String, Locale> _localeMap = {
    'English': const Locale('en'),
    'Kinyarwanda': const Locale('rw'),
    'French': const Locale('fr'),
    'Swahili': const Locale('sw'),
  };

  final Map<Locale, String> _localeToLanguageName = {
    const Locale('en'): 'English',
    const Locale('rw'): 'Kinyarwanda',
    const Locale('fr'): 'French',
    const Locale('sw'): 'Swahili',
  };

  String get currentLanguageName => _localeToLanguageName[_currentLocale] ?? 'English';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(String languageName) async {
    final locale = _localeMap[languageName];
    if (locale != null) {
      _currentLocale = locale;
      
      // Update GetX locale
      Get.updateLocale(locale);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', locale.languageCode);
      } catch (e) {
        print('Error saving language preference: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    
    // Update GetX locale
    Get.updateLocale(locale);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
    }
    
    notifyListeners();
  }

  Locale? getLocaleFromLanguageName(String languageName) {
    return _localeMap[languageName];
  }
}
