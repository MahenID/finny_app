import 'package:finance1/presentation/screens/transaction/category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/category_helper.dart';

class PocketScreen extends StatelessWidget {
  final Function(int)? onNavigate;

  const PocketScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔥 jika belum login
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            //================ HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff16A34A), Color(0xff22C55E)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 18),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kantong Anggaran",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Pantau semua kategori pengeluaranmu",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔥 STREAM FIRESTORE FIX
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('userId', isEqualTo: user.uid) // 🔥 FIX UTAMA
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // 🔥 loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 🔥 error
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // 🔥 jika kosong
                  if (docs.isEmpty) {
                    return const Center(child: Text("Belum ada transaksi"));
                  }

                  int totalIncome = 0;
                  int totalExpense = 0;

                  Map<String, int> categoryExpense = {};
                  Map<String, int> transactionCount = {};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;

                    int amount = (data['amount'] ?? 0) as int;
                    String type = data['type'] ?? 'expense';
                    String category = data['category'] ?? 'Lainnya';

                    if (type == 'income') {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;

                      categoryExpense[category] =
                          (categoryExpense[category] ?? 0) + amount;
                      transactionCount[category] =
                          (transactionCount[category] ?? 0) + 1;
                    }
                  }

                  int totalSaldo = totalIncome - totalExpense;

                  final categories = categoryExpense.keys.toList();

                  // Urutkan kategori berdasarkan nominal terbesar
                  categories.sort(
                    (a, b) =>
                        categoryExpense[b]!.compareTo(categoryExpense[a]!),
                  );

                  int totalTransaction = docs.length;

                  double averageExpense = totalExpense == 0
                      ? 0
                      : totalExpense / totalTransaction;

                  String biggestCategory = categories.isEmpty
                      ? "-"
                      : categories.first;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 🔥 SUMMARY CARD
                        //================ SUMMARY CARD =================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Total Saldo Saat Ini",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Rp $totalSaldo",
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),

                              const SizedBox(height: 25),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryBox(
                                      title: "Pemasukan",
                                      amount: totalIncome,
                                      color: Colors.green,
                                      icon: Icons.arrow_downward,
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  Expanded(
                                    child: _buildSummaryBox(
                                      title: "Pengeluaran",
                                      amount: totalExpense,
                                      color: Colors.red,
                                      icon: Icons.arrow_upward,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Statistik",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatisticCard(
                                Icons.receipt_long,
                                Colors.blue,
                                "$totalTransaction",
                                "Transaksi",
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildStatisticCard(
                                Icons.grid_view_rounded,
                                Colors.orange,
                                "${categories.length}",
                                "Kategori",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatisticCard(
                                Icons.trending_up,
                                Colors.green,
                                "Rp ${averageExpense.toStringAsFixed(0)}",
                                "Rata-rata",
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildStatisticCard(
                                Icons.emoji_events,
                                Colors.amber,
                                biggestCategory,
                                "Terbesar",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Kategori Pengeluaran",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 🔥 GRID KATEGORI
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final amount = categoryExpense[category]!;

                            final percent = totalExpense == 0
                                ? 0.0
                                : amount / totalExpense;

                            return InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryDetailScreen(
                                      title: category,
                                      emoji: CategoryHelper.getEmoji(category),
                                      color: CategoryHelper.getColor(category),
                                    ),
                                  ),
                                );
                              },
                              child: _buildPocketCard(
                                category,
                                amount,
                                transactionCount[category]!,
                                percent,
                                category == biggestCategory,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: .15),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),

          const SizedBox(height: 5),

          Text(
            "Rp $amount",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard(
    IconData icon,
    Color color,
    String value,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          const SizedBox(height: 4),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPocketCard(
    String category,
    int amount,
    int trx,
    double progress,
    bool isBiggest,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBiggest ? Colors.amber : Colors.grey.shade100,
          width: isBiggest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //================ ICON =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CategoryHelper.getColor(category).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  CategoryHelper.getIcon(category),
                  color: CategoryHelper.getColor(category),
                  size: 24,
                ),
              ),

              if (isBiggest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.orange,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "TOP",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          //================ KATEGORI =================
          Text(
            category,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          //================ NOMINAL =================
          Text(
            "Rp ${amount.toString()}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CategoryHelper.getColor(category),
            ),
          ),

          const Spacer(),

          //================ PROGRESS =================
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: CategoryHelper.getColor(category),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$trx transaksi",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: CategoryHelper.getColor(category),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
