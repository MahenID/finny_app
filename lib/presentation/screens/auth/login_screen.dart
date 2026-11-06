import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isObscure = true;
  bool _isLoading = false;
  bool _showResetSuccess = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _switchMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _showResetSuccess = false;
    });
  }

  Future<void> _validateAndSubmit() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _showResetSuccess = false;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    bool isValid = true;

    if (!_isLogin && name.isEmpty) {
      _nameError = "Nama lengkap wajib diisi";
      isValid = false;
    } else if (!_isLogin && name.length < 3) {
      _nameError = "Nama minimal 3 karakter";
      isValid = false;
    }

    if (email.isEmpty) {
      _emailError = "Alamat email wajib diisi";
      isValid = false;
    } else if (!email.contains("@") || !email.contains(".")) {
      _emailError = "Format email belum sesuai";
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = "Kata sandi wajib diisi";
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = "Kata sandi minimal 6 karakter";
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isLoading = true);

    if (_isLogin) {
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;
        if (user == null) return;

        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Silakan verifikasi email terlebih dahulu."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message = e.message ?? "Gagal masuk ke akun.";
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          message = "Email atau kata sandi tidak cocok.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (credential.user != null) {
          await credential.user!.updateDisplayName(name);
          await credential.user!.sendEmailVerification();

          await FirebaseFirestore.instance
              .collection("users")
              .doc(credential.user!.uid)
              .set({
            "name": name,
            "email": email,
            "createdAt": Timestamp.now(),
          });
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message = e.message ?? "Pendaftaran gagal.";
        if (e.code == 'email-already-in-use') {
          message = "Email ini sudah terdaftar. Silakan pilih Masuk.";
        } else if (e.code == 'weak-password') {
          message = "Kata sandi terlalu mudah ditebak.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C2419),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // 1. HERO HEADER (Fintech Emerald Theme)
            _buildHeroHeader(context),

            // 2. FORM CARD CONTAINER
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Sukses Reset Password
                  if (_showResetSuccess) _buildResetSuccessBanner(),

                  // Segmented Switcher Masuk / Daftar
                  _buildTabSwitcher(),

                  const SizedBox(height: 28),

                  // Salam Sambutan Konseptual
                  Text(
                    _isLogin ? "Selamat Datang Kembali" : "Mulai Kelola Finansial",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? "Masuk untuk mengakses ringkasan budget & AI advisor kamu."
                        : "Daftar sekarang untuk pembukuan otomatis & analisis AI.",
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Form Fields
                  if (!_isLogin) ...[
                    _buildInputField(
                      label: "Nama Lengkap",
                      hint: "Contoh: Fajar Pratama",
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      focusNode: _nameFocus,
                      nextFocus: _emailFocus,
                      errorText: _nameError,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                  ],

                  _buildInputField(
                    label: "Alamat Email",
                    hint: "nama@email.com",
                    icon: Icons.mail_outline_rounded,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocus: _passwordFocus,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  _buildInputField(
                    label: "Kata Sandi",
                    hint: "Minimal 6 karakter",
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    isPassword: true,
                    errorText: _passwordError,
                    onSubmitted: (_) => _validateAndSubmit(),
                  ),

                  // Lupa Password Link
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            );

                            if (result == true && mounted) {
                              setState(() => _showResetSuccess = true);
                              Future.delayed(const Duration(seconds: 5), () {
                                if (mounted) {
                                  setState(() => _showResetSuccess = false);
                                }
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Lupa kata sandi?",
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Tombol Submit Utama
                  _buildSubmitButton(),

                  const SizedBox(height: 24),

                  // Security & Trust Badge
                  _buildTrustBadge(),

                  const SizedBox(height: 24),

                  // Syarat & Ketentuan
                  _buildFooterNotice(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN ---

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 28,
        24,
        36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C2419), // Deep Forest Slate
            Color(0xFF14532D), // Emerald Deep
            Color(0xFF166534), // Emerald Dark
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.accentGreen,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),

          // Nama App
          const Text(
            "Finny",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),

          // Slogan
          const Text(
            "Personal Financial AI Advisor",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          // Micro Pill Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMicroBadge(Icons.auto_awesome_rounded, "AI Advisor"),
              const SizedBox(width: 8),
              _buildMicroBadge(Icons.pie_chart_outline_rounded, "Budgeting"),
              const SizedBox(width: 8),
              _buildMicroBadge(Icons.shield_outlined, "Aman & Privat"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentGreen, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: "Masuk",
              isSelected: _isLogin,
              onTap: () => _switchMode(true),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: "Daftar Akun",
              isSelected: !_isLogin,
              onTap: () => _switchMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF166534) : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && _isObscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: (val) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else if (onSubmitted != null) {
              onSubmitted(val);
            }
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: errorText != null
                  ? Colors.red.shade400
                  : const Color(0xFF166534),
            ),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _isObscure = !_isObscure),
                    child: Icon(
                      _isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade300 : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade400 : const Color(0xFF166534),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF14532D),
            Color(0xFF166534),
            Color(0xFF15803D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166534).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _validateAndSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Masuk ke Akun" : "Daftar Akun Baru",
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_outlined, size: 16, color: Color(0xFF166534)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Tersimpan privat & terenkripsi aman di Firebase Cloud",
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tautan reset kata sandi telah dikirim ke email kamu.",
              style: TextStyle(
                color: Color(0xFF14532D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNotice() {
    return Center(
      child: Text(
        "Finny © ${DateTime.now().year} • Kelola keuangan dengan bijak",
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
