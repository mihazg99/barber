// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame. Requires ProviderScope for Riverpod.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // App should build without error (onboarding/auth/home depends on providers).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
