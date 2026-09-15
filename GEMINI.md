# Finny App Development Guidelines & Rules

Setiap kali melakukan tugas modifikasi kode, perbaikan bug, atau mempercantik UI pada aplikasi Finny:

1. **Pemeriksaan API Key Gemini (Wajib)**:
   - File `lib/presentation/screens/ai/chat_screen.dart` dan `lib/presentation/screens/home/home_screen.dart` **wajib** menggunakan `ApiConstants.geminiApiKey` (dari `lib/core/constants/api_constants.dart`).
   - Jangan pernah meninggalkan API Key asli secara hardcoded di source code.
   - Jika API key sempat diisi langsung untuk testing sementara, kembalikan ke `ApiConstants.geminiApiKey` sebelum commit.
   - Kredensial lokal harus tetap berada di file `secrets.json` (yang sudah terdaftar di `.gitignore`).

2. **Commit & Langsung Push ke GitHub `main`**:
   - Setelah pekerjaan selesai dan dipastikan aman dari secret leak:
     1. Stage semua file terkait: `git add .`
     2. Commit dengan pesan yang jelas: `git commit -m "<deskripsi pekerjaan>"`
     3. Push langsung ke remote: `git push origin main`
