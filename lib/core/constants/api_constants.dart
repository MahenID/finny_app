/// Konfigurasi API untuk Finny App.
///
/// Isi GEMINI_BASE_URL dan GEMINI_API_KEY di secrets.json pada root proyek.
/// Jalankan dengan `flutter run --dart-define-from-file=secrets.json`.
/// File secrets.json diabaikan Git agar API key tidak ikut di-commit.
class ApiConstants {
  /// URL dasar Gemini, tanpa /models/...:generateContent atau ?key=....
  static const String geminiBaseUrl = String.fromEnvironment(
    'GEMINI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );
}
