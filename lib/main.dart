import 'package:flutter/material.dart';
import 'screens/tambah_laporan_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaporanLapanganApp());
}

class LaporanLapanganApp extends StatelessWidget {
  const LaporanLapanganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laporan Lapangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const TambahLaporanScreen(),
    );
  }
}
