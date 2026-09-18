import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import 'change_password_screen.dart';
import 'language_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoading = true;

  // State Pengaturan Finansial
  String _currency = 'IDR';
  int _budgetCycleDay = 1;
  bool _hideBalanceByDefault = false;

  // State Notifikasi & Pengingat
  bool _dailyReminder = true;
  bool _budgetAlertEnabled = true;
  bool _aiDigestEnabled = true;

  // State Keamanan & Preferensi
  bool _appLockEnabled = false;
  String _currentLangCode = 'id';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      setState(() {
        _currency = data?['currency'] ?? 'IDR';
        _budgetCycleDay = (data?['budgetCycleDay'] ?? 1) as int;
        _hideBalanceByDefault = data?['hideBalanceByDefault'] ?? false;

        _dailyReminder = data?['dailyReminder'] ?? true;
        _budgetAlertEnabled = data?['budgetAlertEnabled'] ?? true;
        _aiDigestEnabled = data?['aiDigestEnabled'] ?? true;

        _appLockEnabled = data?['appLockEnabled'] ?? false;
        _currentLangCode = data?['language'] ?? 'id';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR LOAD SETTINGS: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("ERROR SAVE SETTINGS: $e");
    }
  }

  void _showCurrencyPicker() {
    final currencies = [
      {'code': 'IDR', 'label': 'Rupiah Indonesia (Rp)', 'symbol': 'Rp'},
      {'code': 'USD', 'label': 'US Dollar (\$)', 'symbol': '\$'},
      {'code': 'SGD', 'label': 'Singapore Dollar (S\$)', 'symbol': 'S\$'},
      {'code': 'MYR', 'label': 'Ringgit Malaysia (RM)', 'symbol': 'RM'},
      {'code': 'EUR', 'label': 'Euro (€)', 'symbol': '€'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "Pilih Mata Uang Utama",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ...currencies.map((curr) {
                final isSelected = _currency == curr['code'];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: isSelected ? AppColors.accentGreen.withValues(alpha: 0.1) : null,
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppColors.accentGreen : Colors.grey.shade200,
                    child: Text(
                      curr['symbol']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(curr['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen) : null,
                  onTap: () async {
                    setState(() {
                      _currency = curr['code']!;
                    });
                    await _saveSettings({'currency': curr['code']});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetCyclePicker() {
    final days = [1, 20, 25, 27, 28];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "Awal Hari Siklus Anggaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  "Sesuaikan dengan tanggal gajian atau awal periode pembukuanmu:",
                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 12),
              ...days.map((day) {
                final isSelected = _budgetCycleDay == day;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: isSelected ? AppColors.accentGreen.withValues(alpha: 0.1) : null,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentGreen : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    "Tanggal $day setiap bulan ${day == 1 ? '(Default Awal Bulan)' : '(Hari Gajian)'}",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen) : null,
                  onTap: () async {
                    setState(() {
                      _budgetCycleDay = day;
                    });
                    await _saveSettings({'budgetCycleDay': day});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpCenterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.help_center_rounded, color: AppColors.accentGreen),
            SizedBox(width: 8),
            Text("Pusat Bantuan Finny", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Bagaimana Finny Membantumu?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                "• Beranda: Ringkasan saldo aktif, perbandingan arus kas, dan Finny AI advisor real-time.\n"
                "• Kantong: Pembagian alokasi pengeluaran per kategori agar tidak overbudget.\n"
                "• Asisten AI: Tanyakan pertanyaan seputar keuanganmu secara instan.\n"
                "• Tambah Transaksi: Catat pengeluaran atau pemasukan secara cepat dengan quick chips.",
                style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText, height: 1.45),
              ),
              SizedBox(height: 12),
              Text(
                "Keamanan Data:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                "Seluruh data transaksi dan profil kamu tersimpan secara privat dan aman di Firebase Cloud.",
                style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Mengerti"),
          ),
        ],
      ),
    );
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Reset Data Transaksi?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Semua riwayat transaksi pemasukan dan pengeluaran kamu akan dihapus secara permanen. Akun dan identitas kamu akan tetap aman.",
          style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              try {
                final collection = FirebaseFirestore.instance
                    .collection('transactions')
                    .where('userId', isEqualTo: user.uid);

                final snapshot = await collection.get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Seluruh riwayat transaksi berhasil direset!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal reset data: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ya, Reset Semua"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP APP BAR
            _buildAppBar(context),

            // 2. LIST PENGATURAN
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // A. PREFERENSI FINANSIAL
                  _buildSectionTitle("PREFERENSI FINANSIAL"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.monetization_on_outlined,
                      iconColor: AppColors.accentGreen,
                      title: "Mata Uang Utama",
                      subtitle: "$_currency (${_currency == 'IDR' ? 'Rupiah Indonesia' : _currency})",
                      onTap: _showCurrencyPicker,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppColors.pocketBlue,
                      title: "Awal Siklus Anggaran",
                      subtitle: "Tanggal $_budgetCycleDay setiap bulan",
                      onTap: _showBudgetCyclePicker,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.visibility_off_outlined,
                      iconColor: Colors.purple,
                      title: "Sembunyikan Saldo Default",
                      subtitle: "Sensor angka saldo saat aplikasi dibuka",
                      trailing: Switch(
                        value: _hideBalanceByDefault,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _hideBalanceByDefault = val;
                          });
                          await _saveSettings({'hideBalanceByDefault': val});
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // B. NOTIFIKASI & PENGINGAT FINANSIAL
                  _buildSectionTitle("NOTIFIKASI & PENGINGAT"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: Colors.orange,
                      title: "Pengingat Catat Harian",
                      subtitle: "Ingatkan untuk mencatat belanja malam hari",
                      trailing: Switch(
                        value: _dailyReminder,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _dailyReminder = val;
                          });
                          await _saveSettings({'dailyReminder': val});
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.redAccent,
                      title: "Peringatan Batas Budget",
                      subtitle: "Beri tahu jika pengeluaran > 80% limit",
                      trailing: Switch(
                        value: _budgetAlertEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _budgetAlertEnabled = val;
                          });
                          await _saveSettings({'budgetAlertEnabled': val});
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.auto_awesome,
                      iconColor: AppColors.accentGreen,
                      title: "Rangkuman Mingguan Finny AI",
                      subtitle: "Kirim ringkasan tren finansial mingguan",
                      trailing: Switch(
                        value: _aiDigestEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _aiDigestEnabled = val;
                          });
                          await _saveSettings({'aiDigestEnabled': val});
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // C. KEAMANAN & AKUN
                  _buildSectionTitle("KEAMANAN & AKUN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.teal,
                      title: "Kunci Aplikasi & Privasi",
                      subtitle: "Minta autentikasi saat aplikasi dibuka",
                      trailing: Switch(
                        value: _appLockEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _appLockEnabled = val;
                          });
                          await _saveSettings({'appLockEnabled': val});
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.password_rounded,
                      iconColor: Colors.blue.shade700,
                      title: "Ganti Kata Sandi",
                      subtitle: "Perbarui password login akun kamu",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: Colors.indigo,
                      title: "Bahasa Aplikasi",
                      subtitle: _currentLangCode == 'id' ? "Bahasa Indonesia" : "English",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LanguageScreen(currentLanguageCode: _currentLangCode),
                          ),
                        );
                        if (result != null && result is String) {
                          setState(() {
                            _currentLangCode = result;
                          });
                          await _saveSettings({'language': result});
                        }
                      },
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // D. DATA & CADANGAN
                  _buildSectionTitle("DATA & CADANGAN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.cloud_done_outlined,
                      iconColor: AppColors.accentGreen,
                      title: "Sinkronisasi Cloud",
                      subtitle: "Tersinkronisasi aman ke Cloud Firestore",
                      trailing: const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_sweep_rounded,
                      iconColor: Colors.red,
                      title: "Reset Riwayat Transaksi",
                      subtitle: "Hapus seluruh transaksi & mulai dari nol",
                      textColor: Colors.red.shade700,
                      onTap: _confirmResetData,
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // E. TENTANG & BANTUAN
                  _buildSectionTitle("TENTANG & BANTUAN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.blue,
                      title: "Pusat Bantuan & Panduan Finny",
                      subtitle: "Pelajari cara pembukuan pintar",
                      onTap: _showHelpCenterDialog,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: Colors.grey.shade600,
                      title: "Versi Aplikasi",
                      subtitle: "Finny v1.0.0 (Fintech Edition)",
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "LATEST",
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryText,
                size: 20,
              ),
            ),
          ),
          const Text(
            "Pengaturan Akun",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildSettingsGroup(List<Widget> children) {
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

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: Colors.grey.shade100);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
