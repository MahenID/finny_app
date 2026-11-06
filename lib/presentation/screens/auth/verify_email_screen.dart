import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_wrapper.dart';
import '../../../../core/theme/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool loading = false;
  bool resending = false;

  Future<void> checkVerification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await currentUser.reload();
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email berhasil diverifikasi!"),
            backgroundColor: AppColors.accentGreen,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email belum diverifikasi. Cek kotak masuk atau spam."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memeriksa verifikasi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> resendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => resending = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email verifikasi telah dikirim ulang."),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim ulang email: $e")),
      );
    } finally {
      if (mounted) setState(() => resending = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.mark_email_read,
                size: 90,
                color: AppColors.accentGreen,
              ),

              const SizedBox(height: 30),

              const Text(
                "Verifikasi Email",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Text(
                "Kami telah mengirim email verifikasi ke\n$email",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : checkVerification,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                  ),

                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Saya Sudah Verifikasi",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: resending ? null : resendVerification,
                child: resending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Kirim Ulang Email"),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 16, color: Colors.blueGrey),
                label: const Text(
                  "Keluar / Ganti Akun",
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
