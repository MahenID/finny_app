import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../screens/transaction/add_transaction_screen.dart';

class TransactionDetailModal {
  static void show({
    required BuildContext context,
    required String id,
    required int amount,
    required String type,
    required String category,
    required String note,
    required DateTime date,
    required IconData icon,
    required Color color,
  }) {
    final bool isExpense = type == 'expense';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // Category Icon
              CircleAvatar(
                radius: 34,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 14),

              // Amount
              Text(
                "${isExpense ? '-' : '+'}${CurrencyHelper.format(amount)}",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isExpense ? AppColors.expenseRed : AppColors.accentGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Title / Note
              Text(
                note,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildRow("Kategori", category),
                    const Divider(height: 18),
                    _buildRow("Jenis", isExpense ? "Pengeluaran" : "Pendapatan"),
                    const Divider(height: 18),
                    _buildRow(
                      "Tanggal",
                      "${date.day} ${_monthName(date.month)} ${date.year}",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Edit & Hapus
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      label: const Text(
                        "Hapus",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              transactionId: id,
                              initialAmount: amount,
                              initialType: type,
                              initialCategory: category,
                              initialNote: note,
                              initialDate: date,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  static void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Hapus Transaksi?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Transaksi ini akan dihapus secara permanen. Apakah kamu yakin?",
          style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Batal", style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await FirebaseFirestore.instance.collection('transactions').doc(id).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Transaksi berhasil dihapus"),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menghapus transaksi: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
}
