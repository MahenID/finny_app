import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/category_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/constants/api_constants.dart';
import '../transaction/add_transaction.dart';
import '../transaction/category_detail_screen.dart';
import '../transaction/recent_activity.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  String _aiText =
      "Tekan tombol 'Analisa Baru' untuk mendapatkan rangkuman finansial pintar dari Finny AI.";
  bool _isLoadingAi = false;
  bool _isBalanceVisible = true;

  // 🔥 AI FUNCTION (Gemini API)
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

      final prompt = """
Kamu adalah AI financial advisor untuk aplikasi Finny.

Analisa data transaksi berikut:
$transactions

Berikan insight singkat (1-2 kalimat), ramah, memotivasi, dan solutif ala financial coach modern.
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

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode != 200) {
        return "AI sedang sibuk sejenak (${response.statusCode}). Coba lagi nanti ya!";
      }

      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "AI tidak memberikan respon";
    } catch (e) {
      debugPrint("ERROR GEMINI: $e");
      return "AI gagal membaca data transaksi kamu 😅";
    }
  }

  Future<void> _analyzeLatest(List docs) async {
    if (docs.isEmpty) {
      setState(() {
        _aiText = "Belum ada transaksi untuk dianalisa. Yuk catat pengeluaran atau pemasukanmu!";
      });
      return;
    }

    setState(() {
      _isLoadingAi = true;
      _aiText = "Finny AI sedang menganalisa keuanganmu...";
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

  String _formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    final String hourStr = date.hour.toString().padLeft(2, '0');
    final String minuteStr = date.minute.toString().padLeft(2, '0');
    final String timeStr = "$hourStr:$minuteStr";

    if (difference.inDays == 0 && now.day == date.day) {
      return "Hari ini, $timeStr";
    } else if (difference.inDays <= 1 && now.day - date.day == 1) {
      return "Kemarin, $timeStr";
    } else {
      const monthNames = [
        "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
        "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
      ];
      return "${date.day} ${monthNames[date.month - 1]} ${date.year}, $timeStr";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User belum login"));
    }

    // Nama panggilan user yang ramah
    final userName = user.displayName?.isNotEmpty == true
        ? user.displayName!.split(' ').first
        : (user.email != null && user.email!.contains('@')
            ? user.email!.split('@').first
            : "Sobat");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        int totalBalance = 0;
        int totalIncome = 0;
        int totalExpense = 0;
        Map<String, int> categoryTotals = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0) as int;
          final type = data['type'];
          final category = data['category'] ?? 'Lainnya';

          if (type == 'income') {
            totalBalance += amount;
            totalIncome += amount;
          } else {
            totalBalance -= amount;
            totalExpense += amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }
        }

        return SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP APP BAR / GREETING
                _buildTopGreeting(userName, context),

                const SizedBox(height: 18),

                // 2. HERO CARD SALDO (FINTECH STYLE)
                _buildHeroBalanceCard(totalBalance, totalIncome, totalExpense),

                const SizedBox(height: 16),

                // 3. QUICK ACTION BAR
                _buildQuickActionBar(context),

                const SizedBox(height: 22),

                // 4. AI FINANCIAL INSIGHT WIDGET
                _buildAiInsightCard(docs),

                const SizedBox(height: 24),

                // 5. KANTONG ANGGARAN (BUDGET POCKETS)
                _buildPocketSection(categoryTotals),

                const SizedBox(height: 24),

                // 6. AKTIVITAS TERAKHIR (RECENT ACTIVITY)
                _buildRecentActivitySection(docs, context),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET KOMPONEN ---

  Widget _buildTopGreeting(String userName, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Halo, $userName!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Text("👋", style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              "Kelola keuanganmu dengan bijak hari ini",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
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
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
              child: const Icon(
                Icons.person,
                color: AppColors.accentGreen,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBalanceCard(int balance, int income, int expense) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Sleek deep slate
            Color(0xFF1E293B), // Midnight slate
            Color(0xFF0E382F), // Emerald tint
          ],
          stops: [0.0, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative ambient circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -35,
            bottom: -35,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris atas: Label Saldo & Toggle Privacy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white70,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Total Saldo Aktif",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isBalanceVisible ? "Sembunyikan" : "Tampilkan",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Angka Saldo Utama
                Text(
                  _isBalanceVisible ? CurrencyHelper.format(balance) : "••••••••••",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 18),

                // Garis pembatas halus
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),

                const SizedBox(height: 14),

                // Ringkasan Pemasukan & Pengeluaran
                Row(
                  children: [
                    // Pemasukan
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.incomeGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.incomeGreen,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Pemasukan",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isBalanceVisible
                                      ? CurrencyHelper.format(income)
                                      : "••••••",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 12),

                    // Pengeluaran
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.expenseRed.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: AppColors.expenseRed,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Pengeluaran",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isBalanceVisible
                                      ? CurrencyHelper.format(expense)
                                      : "••••••",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(
            icon: Icons.add_circle_rounded,
            color: AppColors.accentGreen,
            label: "Catat",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          _buildQuickActionButton(
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.pocketBlue,
            label: "Kantong",
            onTap: () => widget.onNavigate?.call(1),
          ),
          _buildQuickActionButton(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.purpleInsight,
            label: "Tanya AI",
            onTap: () => widget.onNavigate?.call(2),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard(List docs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withValues(alpha: 0.08),
            AppColors.purpleInsight.withValues(alpha: 0.04),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.accentGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Finny AI Advisor",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Insight Cerdas",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoadingAi ? null : () => _analyzeLatest(docs),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isLoadingAi
                          ? Colors.grey.shade400
                          : AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isLoadingAi
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingAi)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _isLoadingAi ? "Menganalisa..." : "Analisa Baru",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Text(
              _aiText,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.primaryText,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPocketSection(Map<String, int> categoryTotals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Kantong Anggaran",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            InkWell(
              onTap: () => widget.onNavigate?.call(1),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      "Lihat Semua",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.accentGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (categoryTotals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text("📁", style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Belum ada pengeluaran per kantong. Transaksimu akan otomatis dikelompokkan di sini!",
                    style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: categoryTotals.entries.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final color = CategoryHelper.getColor(category);
                final emoji = CategoryHelper.getEmoji(category);

                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _buildModernPocketCard(
                    emoji: emoji,
                    title: category,
                    amount: CurrencyHelper.format(amount),
                    color: color,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailScreen(
                            title: category,
                            emoji: emoji,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildModernPocketCard({
    required String emoji,
    required String title,
    required String amount,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Pengeluaran",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(List docs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Aktivitas Terakhir",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            if (docs.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecentActivityScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.accentGreen,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.accentGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Belum Ada Transaksi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Mulai catat transaksi pertamamu sekarang!",
                  style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Catat Sekarang"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          ...docs.take(5).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0) as int;
            final note = data['note'] as String?;
            final type = data['type'] ?? 'expense';
            final category = data['category'] ?? 'Lainnya';

            DateTime date = DateTime.now();
            if (data["createdAt"] != null) {
              date = (data["createdAt"] as Timestamp).toDate();
            } else if (data["date"] != null) {
              date = (data["date"] as Timestamp).toDate();
            }

            final isExpense = type == 'expense';
            final categoryColor = CategoryHelper.getColor(category);
            final categoryIcon = CategoryHelper.getIcon(category);
            final title = (note != null && note.trim().isNotEmpty) ? note : category;

            return _buildModernTransactionItem(
              icon: categoryIcon,
              categoryColor: categoryColor,
              title: title,
              subtitle: "$category • ${_formatFriendlyDate(date)}",
              amountStr: "${isExpense ? '-' : '+'}${CurrencyHelper.format(amount)}",
              isExpense: isExpense,
            );
          }),
      ],
    );
  }

  Widget _buildModernTransactionItem({
    required IconData icon,
    required Color categoryColor,
    required String title,
    required String subtitle,
    required String amountStr,
    required bool isExpense,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
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
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountStr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
            ),
          ),
        ],
      ),
    );
  }
}
