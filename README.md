# finance1

A new Flutter project.

## Konfigurasi AI Finny

Blok `KONFIGURASI AI: BASE URL & API KEY` di `chat_screen.dart` dan
`home_screen.dart` menunjukkan konfigurasi yang dipakai oleh kedua layar.
Isi nilainya sekali di file lokal `secrets.json` pada root proyek:

```json
{
  "AI_BASE_URL": "https://api.penyedia-anda.com/v1",
  "AI_API_KEY": "PASTE_API_KEY_ANDA_DI_SINI",
  "AI_MODEL": ""
}
```

Jika file belum ada, salin `secrets.json.example` menjadi `secrets.json`.
Ganti `AI_BASE_URL` dan `AI_API_KEY` dengan nilai dari penyedia AI Anda.
URL bisa berupa base API (contoh `https://api.penyedia-anda.com/v1`)
atau endpoint lengkap `https://api.penyedia-anda.com/v1/chat/completions`.
Awalan path penyedia dan parameter query tetap dipertahankan.
Key dikirim melalui header `Authorization: Bearer`, bukan parameter URL.

Integrasi mendukung **OpenAI-compatible Chat Completions**, tanpa model atau
host penyedia yang dikunci di kode. Contohnya, [Groq](https://console.groq.com/docs/openai)
memakai base URL `https://api.groq.com/openai/v1`.
API native dengan format lain, seperti Anthropic `/messages`, OpenAI `/responses`,
atau Gemini `generateContent`, memerlukan endpoint kompatibel atau adapter lain.

`AI_MODEL` boleh kosong. Aplikasi mencoba mengambil daftar dari endpoint `/models`
di base API yang sama, melewati model audio/gambar/embedding yang dikenali, lalu
memakai model teks pertama yang tersedia. Pilihan tersebut disimpan selama layar
aktif. Jika penyedia tidak menyediakan daftar model, model yang terpilih tidak
mendukung chat, atau Anda ingin memilih sendiri, isi `AI_MODEL` dengan ID model
chat dari penyedia. Tidak semua API dapat digunakan dengan URL dan key saja.
Untuk server lokal tanpa autentikasi, `AI_API_KEY` boleh kosong.

Konfigurasi lama `GEMINI_BASE_URL` dan `GEMINI_API_KEY` tidak dipakai lagi oleh AI.
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
