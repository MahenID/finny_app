import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'change_password_screen.dart';
import 'language_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isTransactionNotifEnabled = true;
  String _currentLangCode = 'id';
  bool _isLoading = true;

  String _getLanguageName(String code) {
    switch (code) {
      case 'id':
        return "Indonesia";
      case 'en':
        return "English";
      default:
        return "Indonesia";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    setState(() {
      _isTransactionNotifEnabled = data?['notifTransaction'] ?? true;
      _currentLangCode = data?['language'] ?? 'id';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.background,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Pengaturan Akun",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // KEAMANAN
                  _buildSectionTitle("KEAMANAN"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      title: "Ganti Password",
                      subtitle: "Perbarui kata sandi login",
                      iconColor: AppColors.accentGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // NOTIFIKASI
                  _buildSectionTitle("NOTIFIKASI"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: "Notifikasi Transaksi",
                      subtitle: "Pemberitahuan masuk/keluar",
                      iconColor: Colors.blue,
                      trailing: Switch(
                        value: _isTransactionNotifEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) async {
                          setState(() {
                            _isTransactionNotifEnabled = val;
                          });

                          await _saveSettings({"notifTransaction": val});
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // PREFERENSI
                  _buildSectionTitle("PREFERENSI"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: "Bahasa",
                      subtitle: _getLanguageName(_currentLangCode),
                      iconColor: Colors.orange,
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LanguageScreen(
                              currentLanguageCode: _currentLangCode,
                            ),
                          ),
                        );

                        if (result != null && result is String) {
                          setState(() {
                            _currentLangCode = result;
                          });

                          await _saveSettings({"language": result});
                        }
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // LAINNYA
                  _buildSectionTitle("LAINNYA"),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: "Pusat Bantuan",
                      iconColor: Colors.blue,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.article_outlined,
                      title: "Syarat & Ketentuan",
                      iconColor: Colors.grey,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
