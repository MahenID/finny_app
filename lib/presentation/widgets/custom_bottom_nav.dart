import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: _buildNavItem(Icons.home_filled, "Beranda", 0),
              ),
            ),

            Expanded(
              child: Center(child: _buildNavItem(Icons.wallet, "Kantong", 1)),
            ),

            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => onTap(4),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.incomeGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: _buildNavItem(Icons.auto_awesome, "Asisten", 2),
              ),
            ),

            Expanded(
              child: Center(
                child: _buildNavItem(Icons.person_outline, "Profil", 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.accentGreen : AppColors.secondaryText,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? AppColors.accentGreen
                  : AppColors.secondaryText,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
