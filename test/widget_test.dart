// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance1/main.dart';
import 'package:finance1/presentation/widgets/custom_bottom_nav.dart';

void main() {
  testWidgets('Aplikasi MyApp dapat di-render tanpa crash (Smoke test)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: Scaffold(
          body: Center(
            child: Text('Finny App Active'),
          ),
        ),
      ),
    );

    expect(find.text('Finny App Active'), findsOneWidget);
  });

  testWidgets('CustomBottomNav menampilkan semua tab dengan benar', (
    WidgetTester tester,
  ) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNav(
            currentIndex: selectedIndex,
            onTap: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Kantong'), findsOneWidget);
    expect(find.text('Asisten'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.text('Kantong'));
    expect(selectedIndex, 1);
  });
}