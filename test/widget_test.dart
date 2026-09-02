import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_connect/pages/splash_page.dart';

void main() {
  testWidgets('Splash affiche la marque FoodConnect', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(onFinished: () {}),
      ),
    );

    expect(find.text('FoodConnect'), findsOneWidget);
    expect(find.text('Vos DLC, en douceur'), findsOneWidget);
    expect(find.byIcon(Icons.eco_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
