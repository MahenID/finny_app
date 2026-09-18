import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 0: Pengeluaran, 1: Pendapatan
  int _selectedTypeIndex = 0;
  String _selectedCategory = 'Makan';
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

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

  Color get _activeThemeColor =>
      _selectedTypeIndex == 0 ? AppColors.expenseRed : AppColors.accentGreen;

  void _addQuickAmount(int value) {
    final currentAmount = int.tryParse(_amountController.text) ?? 0;
    final newAmount = currentAmount + value;
    setState(() {
      _amountController.text = newAmount.toString();
    });
  }

  void _clearAmount() {
    setState(() {
      _amountController.clear();
    });
  }

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
              primary: _activeThemeColor,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _activeThemeColor,
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

  String _getFormattedDate() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return "Hari ini";
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return "${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}";
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nominal transaksi wajib diisi"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int? amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nominal harus berupa angka lebih dari 0"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan login terlebih dahulu"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestore.collection('transactions').add({
        "userId": user.uid,
        "type": _selectedTypeIndex == 0 ? "expense" : "income",
        "amount": amount,
        "category": _selectedCategory,
        "note": _noteController.text.trim().isEmpty
            ? "-"
            : _noteController.text.trim(),
        "date": Timestamp.fromDate(_selectedDate),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                "${_selectedTypeIndex == 0 ? 'Pengeluaran' : 'Pendapatan'} berhasil disimpan!",
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("ERROR FIRESTORE: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan transaksi: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories =
        _selectedTypeIndex == 0 ? _expenseCategories : _incomeCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP APP BAR
            _buildAppBar(context),

            // 2. SCROLLABLE FORM
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. TYPE SWITCHER (Pengeluaran vs Pendapatan)
                    _buildTypeSwitcher(),

                    const SizedBox(height: 20),

                    // B. HERO NOMINAL CARD
                    _buildNominalCard(),

                    const SizedBox(height: 12),

                    // C. QUICK AMOUNT CHIPS
                    _buildQuickAmountChips(),

                    const SizedBox(height: 24),

                    // D. KATEGORI SELECTOR
                    _buildCategorySection(currentCategories),

                    const SizedBox(height: 24),

                    // E. DETAIL INPUTS (Tanggal & Catatan)
                    _buildDetailInputs(context),

                    const SizedBox(height: 32),

                    // F. TOMBOL SIMPAN
                    _buildSubmitButton(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

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
            "Tambah Transaksi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 36), // Seimbang dengan tombol back
        ],
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tab Pengeluaran
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTypeIndex = 0;
                  _selectedCategory = _expenseCategories[0]['title'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTypeIndex == 0
                      ? AppColors.expenseRed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedTypeIndex == 0
                      ? [
                          BoxShadow(
                            color: AppColors.expenseRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 17,
                      color: _selectedTypeIndex == 0
                          ? Colors.white
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Pengeluaran",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _selectedTypeIndex == 0
                            ? Colors.white
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Pendapatan
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTypeIndex = 1;
                  _selectedCategory = _incomeCategories[0]['title'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTypeIndex == 1
                      ? AppColors.accentGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedTypeIndex == 1
                      ? [
                          BoxShadow(
                            color: AppColors.accentGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 17,
                      color: _selectedTypeIndex == 1
                          ? Colors.white
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Pendapatan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _selectedTypeIndex == 1
                            ? Colors.white
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _activeThemeColor.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _activeThemeColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Jumlah ${_selectedTypeIndex == 0 ? 'Pengeluaran' : 'Pendapatan'}",
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Rp",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _activeThemeColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "0",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w800,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChipItem("+10 rb", () => _addQuickAmount(10000)),
        _buildChipItem("+20 rb", () => _addQuickAmount(20000)),
        _buildChipItem("+50 rb", () => _addQuickAmount(50000)),
        _buildChipItem("+100 rb", () => _addQuickAmount(100000)),
        _buildChipItem("Reset", _clearAmount, isReset: true),
      ],
    );
  }

  Widget _buildChipItem(String label, VoidCallback onTap, {bool isReset = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isReset ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReset
                ? Colors.transparent
                : _activeThemeColor.withValues(alpha: 0.2),
          ),
          boxShadow: isReset
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isReset ? Colors.grey.shade600 : _activeThemeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<Map<String, dynamic>> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pilih Kategori",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              "Dipilih: $_selectedCategory",
              style: TextStyle(
                fontSize: 12,
                color: _activeThemeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final String title = category['title'];
              final bool isSelected = _selectedCategory == title;
              final Color categoryColor = CategoryHelper.getColor(title);
              final String emoji = CategoryHelper.getEmoji(title);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = title;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 88,
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _activeThemeColor : Colors.black.withValues(alpha: 0.04),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _activeThemeColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailInputs(BuildContext context) {
    return Column(
      children: [
        // Input Tanggal Card
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tanggal Transaksi",
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Ubah",
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Input Catatan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: Colors.orange.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Catatan Tambahan",
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: "Contoh: Makan siang bersama teman",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 6, bottom: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _activeThemeColor,
          disabledBackgroundColor: _activeThemeColor.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          shadowColor: _activeThemeColor.withValues(alpha: 0.4),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedTypeIndex == 0
                        ? "Simpan Pengeluaran"
                        : "Simpan Pendapatan",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
