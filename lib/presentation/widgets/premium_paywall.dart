import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PremiumPaywallWidget extends StatelessWidget {
  const PremiumPaywallWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Container, bukan Scaffold, karena ini Modal
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F5FF), // Latar ungu sangat muda
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        // Gunakan Stack untuk tombol tutup "X"
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Handle bar kecil di atas modal
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),

                // Mascot Placeholder (Gambar Robot 3D)
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.smart_toy,
                    size: 60,
                    color: AppColors.purpleInsight,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Level Up Cara\nNgatur Duit Kamu! 🚀",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Mulai ngerasa ribet nyatet manual? Upgrade ke Premium, biar AI kita yang kerja lembur, kamu tinggal santai.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Fitur Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.mic,
                        "Voice Input Cepat",
                        AppColors.purpleInsight,
                      ),
                      const Divider(height: 32),
                      _buildFeatureItem(
                        Icons.camera_alt,
                        "Scan Struk Otomatis",
                        AppColors.pocketRed,
                      ),
                      const Divider(height: 32),
                      _buildFeatureItem(
                        Icons.all_inclusive,
                        "Unlimited Pockets",
                        AppColors.accentGreen,
                      ),
                      const Divider(height: 32),
                      // Update Teks di Gambar 14
                      _buildFeatureItem(
                        Icons.smart_toy,
                        "Asisten AI 24/7 (Saran Kompleks)",
                        Colors.blue,
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        "CUMA BAYAR",
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Rp 29.000",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            TextSpan(
                              text: " / bln",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                // CTA Buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "✨ Coba Gratis 7 Hari Sekarang! ✨",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Tutup modal
                  child: const Text(
                    "Nanti aja deh",
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Tombol tutup "X" di pojok kanan atas (Gambar 14)
          Positioned(
            right: 16,
            top: 25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: AppColors.accentGreen),
      ],
    );
  }
}
