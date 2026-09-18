import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../widgets/premium_paywall.dart';
import 'account_settings_screen.dart';
import 'edit_identity_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Pengguna Finny";
  String _userEmail = "-";
  String _userPhone = "-";

  int _income = 0;
  int _expense = 0;
  int _balance = 0;
  int _transactionCount = 0;
  int _monthlyBudgetLimit = 5000000;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      final transactions = await FirebaseFirestore.instance
          .collection("transactions")
          .where("userId", isEqualTo: user.uid)
          .get();

      int income = 0;
      int expense = 0;

      for (var item in transactions.docs) {
        final trx = item.data();
        final amount = (trx["amount"] ?? 0) as int;
        if (trx["type"] == "income") {
          income += amount;
        } else {
          expense += amount;
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = userData?["name"] ?? user.displayName ?? "Pengguna Finny";
        _userEmail = user.email ?? "-";
        _userPhone = userData?["phone"] ?? "-";
        _monthlyBudgetLimit = (userData?["monthlyBudgetLimit"] ?? 5000000) as int;

        _income = income;
        _expense = expense;
        _balance = income - expense;
        _transactionCount = transactions.docs.length;

        _loading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD USER PROFILE: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditIdentity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditIdentityScreen(
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
        ),
      ),
    );

    if (result != null && result is Map) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "name": result["name"],
          "phone": result["phone"],
        }, SetOptions(merge: true));
        _loadUser();
      }
    }
  }

  void _showMonthlyBudgetDialog() {
    final controller = TextEditingController(text: _monthlyBudgetLimit.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.track_changes_rounded, color: AppColors.accentGreen),
            SizedBox(width: 8),
            Text("Batas Budget Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tentukan batas maksimal pengeluaranmu per bulan untuk membantu kontrol finansial:",
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "Rp ",
                labelText: "Batas Pengeluaran",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLimit = int.tryParse(controller.text) ?? _monthlyBudgetLimit;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
                  "monthlyBudgetLimit": newLimit,
                }, SetOptions(merge: true));
              }
              setState(() {
                _monthlyBudgetLimit = newLimit;
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Batas anggaran bulanan berhasil disimpan!")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showExportSummaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.pocketBlue),
            SizedBox(width: 8),
            Text("Rekap Finansial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Total Pemasukan", CurrencyHelper.format(_income), AppColors.incomeGreen),
                  const Divider(height: 16),
                  _buildSummaryRow("Total Pengeluaran", CurrencyHelper.format(_expense), AppColors.expenseRed),
                  const Divider(height: 16),
                  _buildSummaryRow("Sisa Saldo Bersih", CurrencyHelper.format(_balance), AppColors.primaryText, isBold: true),
                  const Divider(height: 16),
                  _buildSummaryRow("Total Transaksi", "$_transactionCount transaksi", AppColors.secondaryText),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Data ini bersumber dari seluruh riwayat pembukuan akun Finny kamu.",
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Keluar Akun?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Kamu akan keluar dari akun Finny di perangkat ini. Apakah kamu yakin?",
          style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final bool isEmailVerified = user?.emailVerified ?? false;

    // Kalkulasi Skor Kesehatan Finansial
    final double expenseRatio = _income > 0 ? (_expense / _income) : (_expense > 0 ? 1.0 : 0.0);
    String healthStatus = "Prima 🌟";
    String healthDesc = "Pengeluaran terkendali dengan sangat baik";
    Color healthColor = AppColors.incomeGreen;

    if (expenseRatio > 0.8) {
      healthStatus = "Perlu Waspada ⚠️";
      healthDesc = "Pengeluaran melebihi 80% dari total pemasukan";
      healthColor = AppColors.expenseRed;
    } else if (expenseRatio > 0.5) {
      healthStatus = "Cukup Sehat 👍";
      healthDesc = "Pengeluaran dalam batas wajar dan terukur";
      healthColor = Colors.orange.shade700;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. MODERN FINTECH HEADER
              _buildModernProfileHeader(isEmailVerified),

              const SizedBox(height: 18),

              // 2. KARTU STATISTIK KEUANGAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFinancialStatsCard(),
              ),

              const SizedBox(height: 16),

              // 3. KARTU SKOR KESEHATAN FINANSIAL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFinancialHealthCard(healthStatus, healthDesc, healthColor, expenseRatio),
              ),

              const SizedBox(height: 16),

              // 4. BANNER FINNY PRO / PREMIUM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFinnyProBanner(),
              ),

              const SizedBox(height: 24),

              // 5. MENU FITUR PENGATUR KEUANGAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("PENGELOLAAN KEUANGAN"),
                    _buildGroupContainer([
                      _buildMenuTile(
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppColors.pocketBlue,
                        title: "Rekap & Ekspor Finansial",
                        subtitle: "Lihat ringkasan total pembukuan",
                        onTap: _showExportSummaryDialog,
                      ),
                      _buildTileDivider(),
                      _buildMenuTile(
                        icon: Icons.track_changes_rounded,
                        iconColor: Colors.purple,
                        title: "Batas Anggaran Bulanan",
                        subtitle: "Limit saat ini: ${CurrencyHelper.format(_monthlyBudgetLimit)}",
                        onTap: _showMonthlyBudgetDialog,
                      ),
                      _buildTileDivider(),
                      _buildMenuTile(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.accentGreen,
                        title: "Kelola Kantong Anggaran",
                        subtitle: "Atur pembagian kategori budget",
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _buildSectionHeader("PENGATURAN & KEAMANAN"),
                    _buildGroupContainer([
                      _buildMenuTile(
                        icon: Icons.manage_accounts_rounded,
                        iconColor: Colors.blue.shade700,
                        title: "Pengaturan Akun & Bahasa",
                        subtitle: "Kata sandi, preferensi bahasa, notifikasi",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                          );
                        },
                      ),
                      _buildTileDivider(),
                      _buildMenuTile(
                        icon: Icons.edit_note_rounded,
                        iconColor: Colors.teal,
                        title: "Edit Informasi Pribadi",
                        subtitle: "Perbarui nama dan nomor telepon",
                        onTap: _openEditIdentity,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _buildSectionHeader("LAINNYA"),
                    _buildGroupContainer([
                      _buildMenuTile(
                        icon: Icons.logout_rounded,
                        iconColor: Colors.red,
                        title: "Keluar Akun",
                        subtitle: "Keluar dari sesi saat ini",
                        textColor: Colors.red.shade700,
                        onTap: _confirmLogout,
                      ),
                    ]),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- KOMPONEN HEADER ---
  Widget _buildModernProfileHeader(bool isEmailVerified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F281E), // Deep Emerald Slate
            Color(0xFF166534), // Emerald Dark
            Color(0xFF15803D), // Emerald Green
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Profil Akun Finny",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),

          // Avatar dengan tombol edit
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : "F",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _openEditIdentity,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Nama User
          Text(
            _userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email & Telepon
          Text(
            _userEmail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          // Badge Email Verified
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEmailVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: isEmailVerified ? AppColors.accentGreen : Colors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  isEmailVerified ? "Akun Terverifikasi" : "Email Belum Terverifikasi",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KARTU STATISTIK KEUANGAN ---
  Widget _buildFinancialStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            "Saldo Bersih",
            CurrencyHelper.format(_balance),
            Icons.account_balance_wallet_rounded,
            AppColors.primaryText,
          ),
          _buildStatDivider(),
          _buildStatItem(
            "Pemasukan",
            CurrencyHelper.format(_income),
            Icons.arrow_downward_rounded,
            AppColors.incomeGreen,
          ),
          _buildStatDivider(),
          _buildStatItem(
            "Pengeluaran",
            CurrencyHelper.format(_expense),
            Icons.arrow_upward_rounded,
            AppColors.expenseRed,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 38,
      width: 1,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }

  // --- KARTU SKOR KESEHATAN FINANSIAL ---
  Widget _buildFinancialHealthCard(String status, String desc, Color color, double ratio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_rounded, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Kesehatan Finansial",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.primaryText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  // --- BANNER FINNY PRO ---
  Widget _buildFinnyProBanner() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const PremiumPaywallWidget(),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Finny Premium 🚀",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Buka analisis AI tanpa batas & fitur eksklusif",
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  // --- BUILD UTILITIES UNTUK MENU ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTileDivider() {
    return Divider(height: 1, indent: 56, color: Colors.grey.shade100);
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor ?? AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}