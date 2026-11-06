import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (DefaultFirebaseOptions.isPlatformSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Inisialisasi Firebase gagal: $e');
    }
  } else {
    debugPrint(
      'Platform saat ini belum dikonfigurasi pada FirebaseOptions.',
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final Widget? home;

  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.green,
      ),
      home: home ??
          (DefaultFirebaseOptions.isPlatformSupported
              ? const AuthWrapper()
              : const Scaffold(
                  body: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Finny App saat ini hanya dikonfigurasi untuk Android dan iOS.\nSilakan jalankan pada emulator atau perangkat Android/iOS.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )),
    );
  }
}
