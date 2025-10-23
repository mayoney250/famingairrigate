// Widget tests for Faminga Irrigation app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:faminga_irrigation/main.dart';
import 'package:faminga_irrigation/config/colors.dart';

void main() {
  testWidgets('App initializes and shows splash screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FamingaIrrigationApp());

    // Verify that the app initializes
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });

  testWidgets('Brand colors are defined correctly', (WidgetTester tester) async {
    // Verify Faminga brand colors
    expect(FamingaBrandColors.primaryOrange, const Color(0xFFD47B0F));
    expect(FamingaBrandColors.darkGreen, const Color(0xFF2D4D31));
    expect(FamingaBrandColors.white, const Color(0xFFFFFFFF));
    expect(FamingaBrandColors.cream, const Color(0xFFFFF5EA));
    expect(FamingaBrandColors.black, const Color(0xFF000000));
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const FamingaIrrigationApp());

    // Verify app title is set correctly
    final GetMaterialApp app = tester.widget<GetMaterialApp>(
      find.byType(GetMaterialApp),
    );
    expect(app.title, 'Faminga Irrigation');
  });
}
