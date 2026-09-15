---
name: finny-git-workflow
description: >-
  Gunakan skill ini setiap kali user meminta perbaikan bug, mempercantik UI, menambah fitur, atau modifikasi kode pada finny_app.
  Memastikan pengecekan keamanan Gemini API key di chat_screen.dart dan home_screen.dart, mengembalikan kunci sementara, dan langsung melakukan commit & push ke GitHub main.
---

# Finny App Development & Safe Push Workflow

Instruksi kerja wajib setiap kali mengedit, memperbaiki bug, atau mempercantik UI di aplikasi Finny App.

## Alur Kerja Wajib

### 1. Eksekusi Perubahan Kode / UI
* Lakukan modifikasi UI, styling, tata letak, logika, atau perbaikan bug sesuai instruksi user.
* Pastikan kode tetap konsisten, bersih, dan tidak menimbulkan error pada platform Flutter.

### 2. Pengecekan Kredensial & API Key (Wajib)
Periksa dua file utama ini sebelum melakukan commit:
1. `lib/presentation/screens/ai/chat_screen.dart`
2. `lib/presentation/screens/home/home_screen.dart`

**Aturan Keamanan**:
* Kedua file di atas **WAJIB** menggunakan `ApiConstants.geminiApiKey` dari `lib/core/constants/api_constants.dart`.
* **DILARANG KERAS** membiarkan API Key asli tertulis langsung (*hardcoded*) di dalam source code, baik di variabel `apiKey` maupun di parameter query URL `...key=$apiKey`.
* Jika API Key sempat diubah sementara untuk pengetesan lokal, **segera kembalikan** ke `ApiConstants.geminiApiKey`.
* API Key rahasia hanya boleh berada di file lokal `secrets.json` yang diabaikan oleh `.gitignore`.

### 3. Verifikasi Keamanan Sebelum Commit
Jalankan verifikasi cepat di terminal untuk memastikan tidak ada token/secret yang bocor di staging:
```powershell
git diff --cached | Select-String "AQ.Ab8"
```

### 4. Commit & Push Otomatis ke GitHub `main`
Setelah perubahan selesai dan diverifikasi bersih dari kebocoran kredensial:
```powershell
git add .
git commit -m "feat/fix/style: <deskripsi perubahan yang jelas>"
git push origin main
```
Pastikan push berhasil tanpa penolakan dari GitHub Push Protection.
