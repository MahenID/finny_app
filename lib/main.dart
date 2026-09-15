import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa tambah google_fonts di pubspec.yaml
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import '../screens/main_wrapper.dart';
import 'presentation/screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Planner AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ), // Font rounded
        primarySwatch: Colors.green,
      ),
      home: const AuthWrapper(), // Ganti dengan MainWrapper() jika sudah login
    );
  }
}
