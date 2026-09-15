import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/api_constants.dart';

class ChatScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ChatScreen({super.key, this.onNavigate});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Color chatThemeColor = AppColors.accentGreen;

  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> messages = [
    {"isUser": false, "text": "Halo! Saya Finny, Asisten AI keuangan kamu."},
  ];

  // 🔥 API Key Gemini diambil dari ApiConstants (dapat diset via --dart-define=GEMINI_API_KEY=your_key)
  final String apiKey = ApiConstants.geminiApiKey;

  // 🔥 FUNCTION GEMINI API
  Future<String> askAI(String prompt) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "Silakan login terlebih dahulu.";
    }

    final snapshot = await FirebaseFirestore.instance
        .collection("transactions")
        .where("userId", isEqualTo: user.uid)
        .get();

    List<Map<String, dynamic>> transaksi = [];

    for (var doc in snapshot.docs) {
      transaksi.add(doc.data());
    }

    try {
      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      """
Kamu adalah Finny AI.

ATURAN YANG HARUS DIIKUTI:

1. Kamu HANYA boleh menjawab pertanyaan mengenai:
- transaksi pengguna
- pemasukan
- pengeluaran
- kategori
- budget
- tabungan
- laporan keuangan
- fitur aplikasi Finny

2. Jangan menjawab pertanyaan umum.

Jika pengguna bertanya di luar aplikasi keuangan, jawab:

"Maaf, saya hanya dapat membantu mengenai transaksi dan pengelolaan keuangan pada aplikasi Finny."

3. Gunakan data transaksi berikut sebagai SATU-SATUNYA sumber informasi.

DATA FIRESTORE:

$transaksi

PERTANYAAN USER:

$prompt

Jawablah hanya berdasarkan data di atas.
""",
                },
              ],
            },
          ],
        }),
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["candidates"] != null &&
          data["candidates"].isNotEmpty) {
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "❌ Error: ${data["error"]?["message"] ?? response.body}";
      }
    } catch (e) {
      return "❌ Exception: $e";
    }
  }

  void sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"isUser": true, "text": text});
    });

    _controller.clear();

    setState(() {
      messages.add({"isUser": false, "text": "Mengetik..."});
    });

    String aiResponse = await askAI(text);

    setState(() {
      messages.removeLast();
      messages.add({"isUser": false, "text": aiResponse});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: chatThemeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome, color: chatThemeColor),
                  ),
                  const SizedBox(width: 12),
                  const Text("Asisten AI ✨"),
                ],
              ),
            ),

            // CHAT AREA
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  if (msg["isUser"]) {
                    return Column(
                      children: [
                        _buildUserMessage(msg["text"]),
                        const SizedBox(height: 16),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildAiMessage(msg["text"]),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                },
              ),
            ),

            // INPUT
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Tanya Finny...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: chatThemeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(String text) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: chatThemeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
