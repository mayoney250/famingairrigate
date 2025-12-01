// Widget tests for Faminga Irrigation app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:faminga_irrigation/config/colors.dart';

void main() {
  testWidgets('Brand colors are defined correctly', (WidgetTester tester) async {
    // Verify Faminga brand colors
    expect(FamingaBrandColors.primaryOrange, const Color(0xFFD47B0F));
    expect(FamingaBrandColors.darkGreen, const Color(0xFF2D4D31));
    expect(FamingaBrandColors.white, const Color(0xFFFFFFFF));
    expect(FamingaBrandColors.cream, const Color(0xFFFFF5EA));
    expect(FamingaBrandColors.black, const Color(0xFF000000));
  });

  testWidgets('GetMaterialApp can be created', (WidgetTester tester) async {
    // Build a simple GetMaterialApp to verify Get package works
    await tester.pumpWidget(
      GetMaterialApp(
        title: 'Faminga Irrigation',
        home: Scaffold(
          appBar: AppBar(title: const Text('Test')),
          body: const Center(child: Text('Test App')),
        ),
      ),
    );

    // Verify that the app initializes
    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });
}
