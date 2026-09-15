import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../transaction/add_transaction.dart';

import 'home_screen.dart';
import '../transaction/pocket_screen.dart';
import '../ai/chat_screen.dart';
import '../profile/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // DIHAPUS: _previousIndex tidak lagi diperlukan untuk efek fade murni

  void _changeTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index; // Cukup update index baru
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _changeTab),
      PocketScreen(onNavigate: _changeTab),
      const ChatScreen(),
      ProfileScreen(onNavigate: _changeTab),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,

      // DIEDIT TOTAL: Animasi Memudar (Fade) yang Smooth dan Ringan
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20), // 🔥 TAMBAHKAN DI SINI
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return FadeTransition(opacity: curvedAnimation, child: child);
          },
          child: SizedBox(
            key: ValueKey<int>(_currentIndex),
            child: screens[_currentIndex],
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          } else {
            _changeTab(index);
          }
        },
      ),
    );
  }

  
}
