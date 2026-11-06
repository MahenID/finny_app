import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,6}$');

    if (email.isEmpty) {
      setState(() => _emailError = "Email tidak boleh kosong");
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tautan reset kata sandi telah dikirim ke email kamu! Silakan periksa inbox/spam.",
          ),
          backgroundColor: AppColors.accentGreen,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = e.message ?? "Gagal mengirim tautan reset";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = "Terjadi kesalahan saat menghubungi server";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

              // --- IKON KUNCI ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.vpn_key_outlined,
                  color: AppColors.accentGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),

              // --- JUDUL & DESKRIPSI ---
              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Masukkan alamat email yang terdaftar pada akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // --- INPUT EMAIL ---
              const Text(
                "Alamat Email",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                decoration: InputDecoration(
                  hintText: "nama@email.com",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: _emailError != null
                        ? Colors.red.shade300
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _emailError != null
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _emailError != null
                          ? Colors.red.shade300
                          : AppColors.accentGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // --- TOMBOL KIRIM TAUTAN ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Kirim Tautan",
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
