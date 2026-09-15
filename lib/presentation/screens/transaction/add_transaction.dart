import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // BARU: Diperlukan untuk FilteringTextInputFormatter
import '../../../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/category_helper.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // State untuk melacak tipe transaksi (0: Pengeluaran, 1: Pendapatan)
  int _selectedTypeIndex = 0;

  // State untuk melacak kategori yang dipilih
  String _selectedCategory = 'Makan';

  // BARU: State untuk melacak tanggal yang dipilih
  DateTime _selectedDate = DateTime.now();

  // BARU: Controllers untuk input teks
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _expenseCategories = [
    {'title': 'Makan'},
    {'title': 'Minuman'},
    {'title': 'Jajan'},
    {'title': 'Transport'},
    {'title': 'Belanja'},
    {'title': 'Tagihan'},
    {'title': 'Kesehatan'},
    {'title': 'Pendidikan'},
    {'title': 'Hiburan'},
    {'title': 'Olahraga'},
    {'title': 'Donasi'},
    {'title': 'Lainnya'},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'title': 'Gaji'},
    {'title': 'Bonus'},
    {'title': 'Freelance'},
    {'title': 'Investasi'},
    {'title': 'Hadiah'},
    {'title': 'Penjualan'},
    {'title': 'Cashback'},
    {'title': 'Lainnya'},
  ];
  // BARU: Fungsi untuk memunculkan Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedTypeIndex == 0
                  ? AppColors.pocketRed
                  : AppColors.accentGreen, // Warna header kalender
              onPrimary: Colors.white, // Warna teks di atas header
              onSurface: AppColors.primaryText, // Warna angka tanggal
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _selectedTypeIndex == 0
                    ? AppColors.pocketRed
                    : AppColors.accentGreen, // Warna tombol Cancel/OK
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // BARU: Fungsi untuk memformat tanggal menjadi teks yang mudah dibaca
  String _getFormattedDate() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return "Hari ini";
    }
    // Format sederhana (Anda bisa menggunakan package 'intl' untuk format yang lebih kompleks)
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return "${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories = _selectedTypeIndex == 0
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Tambah Transaksi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // 2. KONTEN SCROLL
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOGGLE PENGELUARAN / PENDAPATAN ---
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTypeIndex = 0;
                                  _selectedCategory =
                                      _expenseCategories[0]['title'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTypeIndex == 0
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedTypeIndex == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  "Pengeluaran",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTypeIndex == 0
                                        ? AppColors.pocketRed
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTypeIndex = 1;
                                  _selectedCategory =
                                      _incomeCategories[0]['title'];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTypeIndex == 1
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedTypeIndex == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  "Pendapatan",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTypeIndex == 1
                                        ? AppColors.accentGreen
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- INPUT NOMINAL ---
                    const Center(
                      child: Text(
                        "Nominal",
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "Rp",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _selectedTypeIndex == 0
                                  ? AppColors.pocketRed
                                  : AppColors.accentGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              // DIEDIT: Hanya menerima input angka
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                              decoration: InputDecoration(
                                hintText: "0",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade300,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 200,
                        height: 1,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.only(top: 8),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- KATEGORI GRID ---
                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentCategories.length,
                        itemBuilder: (context, index) {
                          final category = currentCategories[index];
                          final isSelected =
                              _selectedCategory == category['title'];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedCategory = category['title'],
                            ),
                            child: Container(
                              width: 85,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? (_selectedTypeIndex == 0
                                            ? AppColors.pocketRed
                                            : AppColors.accentGreen)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              (_selectedTypeIndex == 0
                                                      ? AppColors.pocketRed
                                                      : AppColors.accentGreen)
                                                  .withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: CategoryHelper.getColor(
                                        category['title'],
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CategoryHelper.getIcon(category['title']),
                                      color: CategoryHelper.getColor(
                                        category['title'],
                                      ),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['title'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- INPUT TANGGAL ---
                    _buildInputCard(
                      icon: Icons.calendar_today_outlined,
                      iconBgColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      label: "Tanggal",
                      // Menampilkan tanggal yang diformat
                      value: _getFormattedDate(),
                      actionWidget: GestureDetector(
                        onTap: () => _selectDate(
                          context,
                        ), // Memanggil fungsi Date Picker
                        child: const Text(
                          "Ubah",
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- INPUT CATATAN ---
                    // Menggunakan TextField khusus untuk catatan
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.sticky_note_2_outlined,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Catatan (Opsional)",
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                                // TextField tanpa border agar terlihat menyatu
                                TextField(
                                  controller: _noteController,
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Tulis catatan di sini...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Nominal wajib diisi"),
                              ),
                            );
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User belum login")),
                            );
                            return;
                          }

                          try {
                            await _firestore.collection('transactions').add({
                              "userId":
                                  user.uid, // 🔥 INI KUNCI UTAMA (WAJIB ADA)
                              "type": _selectedTypeIndex == 0
                                  ? "expense"
                                  : "income",
                              "amount": int.parse(_amountController.text),
                              "category": _selectedCategory,
                              "note": _noteController.text.isEmpty
                                  ? "-"
                                  : _noteController.text,
                              "date": Timestamp.fromDate(_selectedDate),
                              "createdAt": FieldValue.serverTimestamp(),
                            });

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Transaksi berhasil disimpan"),
                              ),
                            );

                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          } catch (e) {
                            debugPrint("ERROR FIRESTORE: $e");

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Gagal simpan: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTypeIndex == 0
                              ? AppColors.pocketRed
                              : AppColors.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _selectedTypeIndex == 0
                              ? "Simpan Pengeluaran"
                              : "Simpan Pendapatan",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN (Hanya digunakan untuk Tanggal sekarang)
  Widget _buildInputCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    Color valueColor = AppColors.primaryText,
    bool isTextValueNormal = false,
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: isTextValueNormal
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ?actionWidget,
        ],
      ),
    );
  }
}
