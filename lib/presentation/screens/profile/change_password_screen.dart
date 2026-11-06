import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    setState(() => _errorText = null);

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty) {
      setState(() => _errorText = "Kata sandi saat ini tidak boleh kosong");
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorText = "Kata sandi baru minimal 6 karakter");
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorText = "Konfirmasi kata sandi baru tidak cocok");
      return;
    }
    if (oldPassword == newPassword) {
      setState(() => _errorText = "Kata sandi baru tidak boleh sama dengan kata sandi lama");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _errorText = "Sesi telah berakhir. Silakan login kembali.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kata sandi berhasil diperbarui!"),
          backgroundColor: AppColors.accentGreen,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _errorText = "Kata sandi saat ini salah.");
      } else if (e.code == 'weak-password') {
        setState(() => _errorText = "Kata sandi terlalu lemah.");
      } else {
        setState(() => _errorText = e.message ?? "Gagal mengubah kata sandi.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = "Terjadi kesalahan: $e");
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
                "Masukkan kata sandi saat ini dan tentukan kata sandi baru untuk akun Finny kamu.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Password Saat Ini
              const Text(
                "Kata Sandi Saat Ini",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _oldPasswordController,
                obscureText: _isObscureOld,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Masukkan kata sandi saat ini",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 22),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _isObscureOld = !_isObscureOld),
                    child: Icon(
                      _isObscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Password Baru
              const Text(
                "Kata Sandi Baru",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _isObscureNew,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Minimal 6 karakter",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.lock_reset_rounded, color: Colors.grey.shade400, size: 22),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _isObscureNew = !_isObscureNew),
                    child: Icon(
                      _isObscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Konfirmasi Password Baru
              const Text(
                "Konfirmasi Kata Sandi Baru",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _isObscureConfirm,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Ulangi kata sandi baru",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.check_circle_outline, color: Colors.grey.shade400, size: 22),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                    child: Icon(
                      _isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
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
                          "Simpan Kata Sandi Baru",
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
