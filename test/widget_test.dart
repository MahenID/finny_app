// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance1/main.dart'; // Sesuaikan jika nama package Anda bukan project1

void main() {
  testWidgets('Aplikasi berjalan tanpa crash (Smoke test)', (WidgetTester tester) async {
    // Bangun aplikasi kita dan trigger frame.
    // Hapus kata 'const' di sini
    await tester.pumpWidget(MyApp());

    // Cek apakah teks 'Beranda' ada di layar (karena ada di Bottom Nav Bar kita)
    expect(find.text('Beranda'), findsWidgets);
    
    // Cek apakah judul sapaan ada di layar
    expect(find.text('Halo, Bro! 👋'), findsOneWidget);
  });
}