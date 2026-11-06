import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../widgets/transaction_detail_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        title: const Text(
          "Aktivitas Terakhir",
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid) // 🔥 WAJIB
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada transaksi"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final num rawAmount = data['amount'] is num
                  ? (data['amount'] as num)
                  : (num.tryParse(data['amount']?.toString() ?? '0') ?? 0);
              final int amount = rawAmount.toInt();
              final String category = data['category'] ?? 'Lainnya';
              final String note = (data['note'] != null && data['note'].toString().trim().isNotEmpty)
                  ? data['note'].toString()
                  : category;
              final String type = data['type'] ?? 'expense';

              DateTime date = DateTime.now();
              if (data['date'] is Timestamp) {
                date = (data['date'] as Timestamp).toDate();
              } else if (data['createdAt'] is Timestamp) {
                date = (data['createdAt'] as Timestamp).toDate();
              }

              final isExpense = type == 'expense';
              final icon = CategoryHelper.getIcon(category);
              final color = CategoryHelper.getColor(category);

              return _buildTransactionTile(
                icon,
                note,
                "${date.day}/${date.month}/${date.year}",
                "${isExpense ? '-' : '+'}${CurrencyHelper.format(amount)}",
                color,
                onTap: () {
                  TransactionDetailModal.show(
                    context: context,
                    id: docs[index].id,
                    amount: amount,
                    type: type,
                    category: category,
                    note: note,
                    date: date,
                    icon: icon,
                    color: color,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(
    IconData icon,
    String title,
    String time,
    String amount,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
