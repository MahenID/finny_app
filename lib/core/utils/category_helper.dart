import 'package:flutter/material.dart';

class CategoryHelper {
  static String getEmoji(String category) {
    switch (category.toLowerCase()) {
      case "makan":
        return "🍔";

      case "minuman":
        return "🥤";

      case "jajan":
        return "🍩";

      case "transport":
        return "🚗";

      case "belanja":
        return "🛍️";

      case "tagihan":
        return "💡";

      case "kesehatan":
        return "💊";

      case "pendidikan":
        return "📚";

      case "hiburan":
        return "🎮";

      case "olahraga":
        return "⚽";

      case "donasi":
        return "🤝";

      case "gaji":
        return "💰";

      case "bonus":
        return "🎉";

      case "freelance":
        return "💻";

      case "investasi":
        return "📈";

      case "hadiah":
        return "🎁";

      case "penjualan":
        return "🛒";

      case "cashback":
        return "💸";

      default:
        return "📦";
    }
  }

  static IconData getIcon(String category) {
    switch (category.toLowerCase()) {
      case "makan":
        return Icons.restaurant;

      case "minuman":
        return Icons.local_drink;

      case "jajan":
        return Icons.fastfood;

      case "transport":
        return Icons.directions_car;

      case "belanja":
        return Icons.shopping_bag;

      case "tagihan":
        return Icons.receipt_long;

      case "kesehatan":
        return Icons.medical_services;

      case "pendidikan":
        return Icons.school;

      case "hiburan":
        return Icons.sports_esports;

      case "olahraga":
        return Icons.sports_soccer;

      case "donasi":
        return Icons.volunteer_activism;

      case "gaji":
        return Icons.payments;

      case "bonus":
        return Icons.card_giftcard;

      case "freelance":
        return Icons.computer;

      case "investasi":
        return Icons.trending_up;

      case "hadiah":
        return Icons.redeem;

      case "penjualan":
        return Icons.storefront;

      case "cashback":
        return Icons.savings;

      default:
        return Icons.account_balance_wallet;
    }
  }

  static Color getColor(String category) {
    switch (category.toLowerCase()) {
      case "makan":
        return Colors.orange;

      case "minuman":
        return Colors.lightBlue;

      case "jajan":
        return Colors.pink;

      case "transport":
        return Colors.blue;

      case "belanja":
        return Colors.purple;

      case "tagihan":
        return Colors.amber;

      case "kesehatan":
        return Colors.red;

      case "pendidikan":
        return Colors.indigo;

      case "hiburan":
        return Colors.deepPurple;

      case "olahraga":
        return Colors.green;

      case "donasi":
        return Colors.teal;

      case "gaji":
        return Colors.green;

      case "bonus":
        return Colors.orange;

      case "freelance":
        return Colors.blue;

      case "investasi":
        return Colors.indigo;

      case "hadiah":
        return Colors.pink;

      case "penjualan":
        return Colors.deepOrange;

      case "cashback":
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }
}
