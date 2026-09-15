import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../auth/otp_screen.dart'; // Import halaman OTP
import '../auth/login_screen.dart'; // Import halaman Login untuk akhir alur

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  bool _isObscure = true;
  String? _errorText;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    setState(() => _errorText = null);

    if (_oldPasswordController.text.isEmpty) {
      setState(() => _errorText = "Password saat ini tidak boleh kosong");
    } else {
      // 1. Navigasi ke OTP (Membawa isFromForgotPassword = true agar alurnya ke Buat Sandi Baru)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          // Ganti email dummy di bawah ini dengan email user yang login nantinya
          builder: (context) => const OtpScreen(
            email: "user@email.com",
            isFromForgotPassword: true,
          ),
        ),
      );

      // 2. Jika seluruh alur (OTP -> Buat Sandi) berhasil dan melempar nilai true kembali ke sini
      if (result == true && mounted) {
        // Tampilkan pesan sukses hijau
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password berhasil diubah! Silakan masuk kembali."),
            backgroundColor: AppColors.accentGreen,
            duration: Duration(seconds: 2),
          ),
        );

        // 3. Lempar user ke halaman Login dan hapus semua riwayat halaman sebelumnya
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOMBOL BACK ---
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(height: 32),

              // --- IKON SHIELD ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.accentGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // --- JUDUL & DESKRIPSI ---
              const Text(
                "Ganti Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Masukkan kata sandi Anda saat ini untuk keamanan. Kami akan mengirimkan kode OTP ke email Anda untuk proses selanjutnya.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // --- INPUT KATA SANDI LAMA ---
              const Text(
                "Password Saat Ini",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController,
                obscureText: _isObscure,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Masukkan kata sandi lama",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _isObscure = !_isObscure),
                    child: Icon(
                      _isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _errorText != null
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _errorText != null
                          ? Colors.red.shade300
                          : AppColors.accentGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // --- TOMBOL KIRIM OTP ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Kirim Kode OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
