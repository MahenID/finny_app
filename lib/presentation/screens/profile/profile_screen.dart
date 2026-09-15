import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import 'account_settings_screen.dart';
import 'edit_identity_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String _userPhone = "-";

  int _income = 0;
  int _expense = 0;
  int _balance = 0;

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
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data();

      final transactions = await FirebaseFirestore.instance
          .collection("transactions")
          .where("userId", isEqualTo: user.uid)
          .get();

      int income = 0;
      int expense = 0;

      for (var item in transactions.docs) {
        final trx = item.data();

        if (trx["type"] == "income") {
          income += trx["amount"] as int;
        } else {
          expense += trx["amount"] as int;
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = data?["name"] ?? "User";
        _userEmail = user.email ?? "-";
        _userPhone = data?["phone"] ?? "-";

        _income = income;
        _expense = expense;
        _balance = income - expense;

        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Route _createSmoothTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              //------------------------------------------------
              // HEADER
              //------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 30,
                  bottom: 40,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff16A34A),
                      Color(0xff22C55E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),

                child: Column(
                  children: [

                    const Text(
                      "Profil Saya",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Stack(
                      children: [

                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              _userName.isEmpty
                                  ? "U"
                                  : _userName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.accentGreen,
                              size: 18,
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Icon(
                            user!.emailVerified
                                ? Icons.verified
                                : Icons.error_outline,
                            size: 18,
                            color: user.emailVerified
                                ? Colors.green
                                : Colors.orange,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            user.emailVerified
                                ? "Email Terverifikasi"
                                : "Belum Terverifikasi",

                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: user.emailVerified
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              //------------------------------------------------
              // CARD STATISTIK
              //------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(25),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [

                      _buildStat(
                        "Saldo",
                        "Rp $_balance",
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),

                      _buildDivider(),

                      _buildStat(
                        "Masuk",
                        "Rp $_income",
                        Icons.arrow_downward,
                        Colors.blue,
                      ),

                      _buildDivider(),

                      _buildStat(
                        "Keluar",
                        "Rp $_expense",
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              //------------------------------------------------
// IDENTITAS
//------------------------------------------------

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Identitas Diri",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

      _buildInfoTile(
        Icons.person_outline,
        "Nama Lengkap",
        _userName,
      ),

      const SizedBox(height: 15),

      _buildInfoTile(
        Icons.email_outlined,
        "Alamat Email",
        _userEmail,
      ),

      const SizedBox(height: 15),

      _buildInfoTile(
        Icons.phone_android,
        "Nomor Handphone",
        _userPhone,
      ),

      const SizedBox(height: 25),

      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text(
            "Edit Identitas",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),

          onPressed: () async {

            final result = await Navigator.push(
              context,
              _createSmoothTransition(
                EditIdentityScreen(
                  initialName: _userName,
                  initialEmail: _userEmail,
                  initialPhone: _userPhone,
                ),
              ),
            );

            if(result!=null){

              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .set({
                    "name":result["name"],
                    "phone":result["phone"],
                  },SetOptions(merge:true));

              _loadUser();

            }

          },
        ),
      ),

      const SizedBox(height:30),

      const Text(
        "Lainnya",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize:18,
        ),
      ),

      const SizedBox(height:15),

      _buildActionCard(
        icon: Icons.settings,
        title: "Pengaturan Akun",
        subtitle: "Password, Bahasa, Notifikasi",
        color: Colors.blue,
        onTap: (){
          Navigator.push(
            context,
            _createSmoothTransition(
              const AccountSettingsScreen(),
            ),
          );
        },
      ),

      const SizedBox(height:15),

      _buildActionCard(
        icon: Icons.logout,
        title: "Keluar Akun",
        subtitle: "Logout dari aplikasi",
        color: Colors.red,
        onTap: () async{

          await FirebaseAuth.instance.signOut();

        },
      ),

      const SizedBox(height:100),

    ],
  ),
),

],
),
),
),
);
}

  Widget _buildStat(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 48,
      width: 1,
      color: Colors.grey.withValues(alpha: .15),
    );
  }
  
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentGreen.withValues(alpha: .12),
            child: Icon(icon, color: AppColors.accentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}