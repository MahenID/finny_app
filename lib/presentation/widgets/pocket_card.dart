import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../screens/transaction/category_detail_screen.dart';

class PocketCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sisa;
  final String terpakai;
  final String alokasi;
  final double progress;
  final Color color;

  const PocketCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.sisa,
    required this.terpakai,
    required this.alokasi,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // BARU: Dibungkus dengan GestureDetector agar card bisa diklik
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman CategoryDetailScreen saat card diklik
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryDetailScreen(title: title, emoji: emoji, color: color),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Label untuk Alokasi (Biru) - DIPINDAH KE PALING ATAS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Alokasi: $alokasi",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10), // Sedikit jarak dari Alokasi ke Emoji
            // Indikator Melingkar (DIPINDAH KE POSISI KE-DUA)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 10),

            // Judul Kategori (DIPINDAH KE POSISI KE-TIGA)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10), // Jarak sebelum kelompok badge bawah
            // Label untuk Sisa Budget (Hijau) - TETAP DI BAWAH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Sisa: $sisa",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.accentGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4), // Jarak kecil antar badge bawah
            // Label untuk Budget Terpakai (Merah) - TETAP DI BAWAH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.pocketRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Pakai: $terpakai",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.pocketRed,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
