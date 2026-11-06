import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/category_helper.dart';
import '../../../../core/utils/currency_helper.dart';
class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;

  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .where("userId", isEqualTo: user.uid)
            .where("category", isEqualTo: title)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final docs = List.from(snapshot.data?.docs ?? []);
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = (dataA['date'] is Timestamp)
                ? (dataA['date'] as Timestamp).millisecondsSinceEpoch
                : ((dataA['createdAt'] is Timestamp)
                    ? (dataA['createdAt'] as Timestamp).millisecondsSinceEpoch
                    : 0);
            final timeB = (dataB['date'] is Timestamp)
                ? (dataB['date'] as Timestamp).millisecondsSinceEpoch
                : ((dataB['createdAt'] is Timestamp)
                    ? (dataB['createdAt'] as Timestamp).millisecondsSinceEpoch
                    : 0);
            return timeB.compareTo(timeA);
          });

          int total = 0;
          for (var d in docs) {
            total += ((d.data() as Map<String, dynamic>)["amount"] as num?)?.toInt() ?? 0;
          }

          final average = docs.isEmpty ? 0 : (total ~/ docs.length);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                backgroundColor: color,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: .7)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 45),
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: Icon(
                            CategoryHelper.getIcon(title),
                            size: 40,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          CurrencyHelper.format(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${docs.length} transaksi",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _info(
                              Icons.receipt_long,
                              "Transaksi",
                              "${docs.length}",
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _info(
                              Icons.calculate,
                              "Rata-rata",
                              CurrencyHelper.format(average),
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Riwayat Transaksi",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (docs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text("Belum ada transaksi"),
                        ),
                      ...docs.map((e) {
                        final data = e.data() as Map<String, dynamic>;
                        final amount = (data["amount"] as num?)?.toInt() ?? 0;
                        final note = (data["note"] != null && data["note"].toString().trim().isNotEmpty)
                            ? data["note"].toString()
                            : title;
                        final type = data["type"] ?? "expense";
                        DateTime date = DateTime.now();
                        if (data["date"] is Timestamp) {
                          date = (data["date"] as Timestamp).toDate();
                        } else if (data["createdAt"] is Timestamp) {
                          date = (data["createdAt"] as Timestamp).toDate();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: color.withValues(alpha: .12),
                                child: Icon(
                                  CategoryHelper.getIcon(title),
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${date.day}/${date.month}/${date.year}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${type == "expense" ? "-" : "+"}${CurrencyHelper.format(amount)}",
                                style: TextStyle(
                                  color: type == "expense"
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
