/// Konfigurasi API untuk Finny App.
///
/// Isi AI_BASE_URL dan AI_API_KEY di secrets.json pada root proyek.
/// AI_MODEL opsional: kosongkan untuk mencoba memilih model secara otomatis.
/// Jalankan dengan `flutter run --dart-define-from-file=secrets.json`.
/// File secrets.json diabaikan Git agar API key tidak ikut di-commit.
class ApiConstants {
  /// Base URL API atau URL lengkap endpoint /chat/completions.
  static const String aiBaseUrl = String.fromEnvironment('AI_BASE_URL');

  static const String aiApiKey = String.fromEnvironment('AI_API_KEY');

  static const String aiModel = String.fromEnvironment('AI_MODEL');
}
