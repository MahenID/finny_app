import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DummyData {
  static const List<Map<String, dynamic>> pockets = [
    {
      'alokasi': 'Rp 750.000',
      'emoji': '🍔',
      'title': 'Makan',
      'sisa': 'Rp 500.000',
      'progress': 0.75,
      'color': AppColors.pocketRed,
      'terpakai':
          'Rp 250.000', // BARU: Menambahkan data terpakai untuk kategori Makan
    },
    {
      'alokasi': 'Rp 300.000',
      'emoji': '🚗',
      'title': 'Transport',
      'sisa': 'Rp 200.000',
      'progress': 0.60,
      'color': AppColors.pocketBlue,
      'terpakai':
          'Rp 120.000', // BARU: Menambahkan data terpakai untuk kategori Transport
    },
    {
      'alokasi': 'Rp 100.000',
      'emoji': '🧋',
      'title': 'Jajan',
      'sisa': 'Rp 50.000',
      'progress': 0.90,
      'color': AppColors.accentGreen,
      'terpakai':
          'Rp 45.000', // BARU: Menambahkan data terpakai untuk kategori Jajan
    },
    {
      'alokasi': 'Rp 1.000.000',
      'emoji': '🛍️',
      'title': 'Belanja',
      'sisa': 'Rp 1.000.000',
      'progress': 0.0,
      'color': AppColors.purpleInsight,
      'terpakai':
          'Rp 0', // BARU: Menambahkan data terpakai untuk kategori Belanja
    },
  ];

  static const List<Map<String, dynamic>> transactions = [
    {
      'icon': Icons.coffee,
      'title': 'Kopi Kenangan',
      'time': 'Hari ini, 09:00',
      'amount': '-Rp 45.000',
      'color': Colors.green,
    },
    {
      'icon': Icons.restaurant,
      'title': 'Makan Siang Nasi Padang',
      'time': 'Hari ini, 12:30',
      'amount': '-Rp 35.000',
      'color': Colors.red,
    },
    {
      'icon': Icons.directions_bus,
      'title': 'GoRide ke Kantor',
      'time': 'Kemarin, 08:00',
      'amount': '-Rp 20.000',
      'color': Colors.blue,
    },
  ];
}
