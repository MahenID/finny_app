import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/category_helper.dart';
import '../../../../core/constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  String _aiText =
      "Tekan tombol 'Analisa Terbaru' untuk mendapatkan analisa AI.";
  bool _isLoadingAi = false;

  // 🔥 AI FUNCTION (GPT)
  Future<String> _getAiInsight(List docs) async {
    try {
      List<Map<String, dynamic>> transactions = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "category": data["category"],
          "amount": data["amount"],
          "type": data["type"],
        };
      }).toList();

      final prompt =
          """
Kamu adalah AI financial advisor.

Analisa data transaksi berikut:
$transactions

Berikan insight singkat (1-2 kalimat), santai seperti aplikasi keuangan.
""";

      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${ApiConstants.geminiApiKey}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      // 🔥 DEBUG
      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode != 200) {
        return "AI error: ${response.statusCode}";
      }

      final data = jsonDecode(response.body);

      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "AI tidak memberikan respon";
    } catch (e) {
      debugPrint("ERROR GEMINI: $e");
      return "AI gagal membaca data 😅";
    }
  }

  Future<void> _analyzeLatest(List docs) async {
    if (docs.isEmpty) {
      setState(() {
        _aiText = "Belum ada transaksi 😄";
      });
      return;
    }

    setState(() {
      _isLoadingAi = true;
      _aiText = "AI sedang menganalisa...";
    });

    final result = await _getAiInsight(docs);

    if (!mounted) return;

    setState(() {
      _aiText = result;
      _isLoadingAi = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User belum login"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid) // 🔥 FILTER USER
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // 🔥 AI dipanggil ulang jika data berubah

        int totalBalance = 0;
        Map<String, int> categoryTotals = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0) as int;
          final type = data['type'];
          final category = data['category'] ?? 'Lainnya';

          if (type == 'income') {
            totalBalance += amount;
          } else {
            totalBalance -= amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Halo, Bro! 👋",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text("Total Saldo Kamu"),
                          const SizedBox(height: 4),
                          Text(
                            "Rp $totalBalance",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔥 AI INSIGHT
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.accentGreen,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "AI Financial Insight",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isLoadingAi
                                ? null
                                : () => _analyzeLatest(docs),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Analisa Terbaru"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _isLoadingAi
                          ? const Center(child: CircularProgressIndicator())
                          : Text(_aiText, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 🔥 POCKET
                const Text(
                  "Kantong Anggaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categoryTotals.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildPocketCard(
                          CategoryHelper.getEmoji(entry.key),
                          entry.key,
                          "Rp ${entry.value}",
                          CategoryHelper.getColor(entry.key),
                          0.5,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔥 RECENT ACTIVITY
                const Text(
                  "Aktivitas Terakhir",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ...docs.take(5).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = data['amount'];
                  final note = data['note'];
                  final type = data['type'];
                  DateTime date = DateTime.now();

                  if (data["createdAt"] != null) {
                    date = (data["createdAt"] as Timestamp).toDate();
                  } else if (data["date"] != null) {
                    date = (data["date"] as Timestamp).toDate();
                  }

                  return _buildTransactionTile(
                    Icons.account_balance_wallet,
                    note ?? "-",
                    "${date.day}/${date.month}/${date.year}",
                    "${type == 'expense' ? '-' : '+'}Rp $amount",
                    type == 'expense' ? Colors.red : Colors.green,
                  );
                }),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPocketCard(
    String emoji,
    String title,
    String balance,
    Color color,
    double progressValue,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(balance),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    IconData icon,
    String title,
    String time,
    String amount,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(time),
              ],
            ),
          ),
          Text(amount),
        ],
      ),
    );
  }
}
