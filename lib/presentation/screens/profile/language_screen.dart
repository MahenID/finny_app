import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LanguageScreen extends StatefulWidget {
  final String
  currentLanguageCode; // Menerima bahasa yang sedang aktif (misal: 'id' atau 'en')

  const LanguageScreen({super.key, required this.currentLanguageCode});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLangCode;

  @override
  void initState() {
    super.initState();
    // Set pilihan awal sesuai bahasa yang sedang aktif
    _selectedLangCode = widget.currentLanguageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    "Pilih Bahasa",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // --- KONTEN PILIHAN BAHASA ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pilih bahasa aplikasi",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Opsi Bahasa Indonesia
                    _buildLanguageOption(
                      title: "Bahasa Indonesia",
                      langCode: 'id',
                    ),
                    const SizedBox(height: 16),

                    // Opsi English
                    _buildLanguageOption(title: "English", langCode: 'en'),
                  ],
                ),
              ),
            ),

            // --- TOMBOL SIMPAN ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Kembali ke halaman pengaturan membawa kode bahasa yang dipilih
                    Navigator.pop(context, _selectedLangCode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Simpan Bahasa",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN: Kotak Opsi Bahasa
  Widget _buildLanguageOption({
    required String title,
    required String langCode,
  }) {
    bool isSelected = _selectedLangCode == langCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLangCode = langCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentGreen : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.accentGreen : Colors.grey.shade300,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
