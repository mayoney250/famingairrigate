import 'package:flutter/material.dart';
import 'l10n_extensions.dart';

const List<String> soilTypeValues = [
  'Unknown',
  'Clay',
  'Sandy',
  'Loam',
  'Silt',
  'Peat',
  'Chalk',
];

List<DropdownMenuItem<String>> soilTypeDropdownItems(BuildContext context) {
  final l10n = context.l10n;
  final map = {
    'Unknown': l10n.unknown,
    'Clay': l10n.clay,
    'Sandy': l10n.sandy,
    'Loam': l10n.loam,
    'Silt': l10n.silt,
    'Peat': l10n.peat,
    'Chalk': l10n.chalk,
  };

  return soilTypeValues.map((v) {
    return DropdownMenuItem(value: v, child: Text(map[v] ?? v));
  }).toList();
}
