import 'package:flutter/material.dart';

const List<String> growthStageValues = [
  'Germination',
  'Seedling',
  'Vegetative Growth',
  'Flowering',
  'Fruit',
  'Maturity',
  'Harvest',
];

const List<String> cropTypeValues = [
  'Unknown',
  'Maize',
  'Wheat',
  'Rice',
  'Soybean',
  'Cotton',
  'Coffee',
  'Tea',
  'Vegetables',
  'Fruits',
];

bool isValidGrowthStage(String v) {
  final norm = v.trim().toLowerCase();
  return growthStageValues.any((s) => s.toLowerCase() == norm);
}

bool isValidCropType(String v) {
  final norm = v.trim().toLowerCase();
  return cropTypeValues.any((s) => s.toLowerCase() == norm);
}
