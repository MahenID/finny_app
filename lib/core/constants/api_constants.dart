/// Konfigurasi API untuk Finny App.
/// 
/// Untuk keamanan, jangan commit API key pribadi/production secara hardcode ke repo publik.
/// Anda dapat memasukkan API key saat menjalankan aplikasi:
/// `flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key`
class ApiConstants {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );
}
