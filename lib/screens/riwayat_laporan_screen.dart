import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import '../db/database_helper.dart';
import '../models/laporan.dart';
import 'detail_laporan_screen.dart';

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});

  @override
  State<RiwayatLaporanScreen> createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Laporan>> _laporanFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _laporanFuture = _dbHelper.getAllLaporan();
    });
  }

  Future<void> _hapusLaporan(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
            ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.surface,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await _dbHelper.deleteLaporan(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Laporan berhasil dihapus'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.surface),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            tooltip: 'Muat Ulang',
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder<List<Laporan>>(
        future: _laporanFuture,
        builder: (context, snapshot) {
          // ── Loading State ──────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── Error State ────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat data:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final daftarLaporan = snapshot.data ?? [];

          // ── Empty State ────────────────────────────────────────────
          if (daftarLaporan.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 72,
                    color: Color.fromRGBO(156, 163, 175, 0.8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada laporan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buat laporan pertama Anda\ndi halaman sebelumnya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Laporan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── List State ─────────────────────────────────────────────
          return Column(
            children: [
              // Header statistik
              _buildStatsHeader(daftarLaporan.length),

              // ListView laporan
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: daftarLaporan.length,
                  itemBuilder: (context, index) {
                    final laporan = daftarLaporan[index];
                    return _buildLaporanCard(laporan, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(int total) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Total $total Laporan Tersimpan',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanCard(Laporan laporan, int index) {
    final hasFoto = laporan.fotoPath != null && laporan.fotoPath!.isNotEmpty;
    final fotoExists = hasFoto && File(laporan.fotoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.08),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLaporanScreen(laporan: laporan),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail foto atau placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: fotoExists
                      ? Image.file(File(laporan.fotoPath!), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info laporan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nomor & judul
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${laporan.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            laporan.judul,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Deskripsi singkat
                    Text(
                      laporan.deskripsi,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // GPS & Tanggal
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${laporan.latitude.toStringAsFixed(4)}, ${laporan.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 12, color: AppColors.placeholder),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            laporan.tanggal,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.placeholder,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol hapus
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                onPressed: () => _hapusLaporan(laporan.id!),
                tooltip: 'Hapus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
