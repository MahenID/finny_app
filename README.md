# finance1

A new Flutter project.

## Konfigurasi AI Finny

Blok `KONFIGURASI AI: BASE URL & API KEY` di `chat_screen.dart` dan
`home_screen.dart` menunjukkan konfigurasi yang dipakai oleh kedua layar.
Isi nilainya sekali di file lokal `secrets.json` pada root proyek:

```json
{
  "GEMINI_BASE_URL": "https://generativelanguage.googleapis.com/v1beta",
  "GEMINI_API_KEY": "MASUKKAN_API_KEY_ANDA_DI_SINI"
}
```

Jika file belum ada, salin `secrets.json.example` menjadi `secrets.json`.
Base URL adalah URL dasar API Gemini, tanpa `/models/...:generateContent`
atau `?key=...`. Pemanggilan AI menggunakan format Gemini `generateContent`.
File `secrets.json` diabaikan Git; jangan menulis key asli di source Dart.

Jalankan aplikasi dengan:

```sh
flutter run --dart-define-from-file=secrets.json
```

Konfigurasi Run/Debug VS Code sudah membaca file ini. Setelah mengubah nilainya,
hentikan lalu jalankan ulang aplikasi agar konfigurasi baru terbaca.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
