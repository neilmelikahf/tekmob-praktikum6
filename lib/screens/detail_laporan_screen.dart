import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

import '../models/laporan.dart';

class DetailLaporanScreen extends StatelessWidget {
  final Laporan laporan;

  const DetailLaporanScreen({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    final hasFoto = laporan.fotoPath != null && laporan.fotoPath!.isNotEmpty;
    final fotoExists = hasFoto && File(laporan.fotoPath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Laporan #${laporan.id}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.surface),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Foto Bukti ─────────────────────────────────────────────
            fotoExists
                ? Hero(
                    tag: 'foto_${laporan.id}',
                    child: Image.file(
                      File(laporan.fotoPath!),
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined,
                              size: 56, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text(
                            'File foto tidak ditemukan',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),

            // ── Konten Detail ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & tanggal
                  Text(
                    laporan.judul,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.placeholder),
                      const SizedBox(width: 4),
                      Text(
                        laporan.tanggal,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Kartu GPS
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Koordinat GPS',
                    color: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Latitude', laporan.latitude.toStringAsFixed(6)),
                        const SizedBox(height: 6),
                        _infoRow('Longitude', laporan.longitude.toStringAsFixed(6)),
                        const SizedBox(height: 10),
                        // Link Google Maps
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _openGoogleMaps(context, laporan.latitude, laporan.longitude),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.map_outlined,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'maps.google.com/?q=${laporan.latitude},${laporan.longitude}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kartu Deskripsi
                  _buildInfoCard(
                    icon: Icons.description_outlined,
                    title: 'Deskripsi Kejadian',
                    color: AppColors.primary,
                    child: Text(
                      laporan.deskripsi,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kartu path foto
                  if (hasFoto)
                    _buildInfoCard(
                      icon: Icons.folder_outlined,
                      title: 'Lokasi File Foto',
                      color: AppColors.primary,
                      child: Text(
                        laporan.fotoPath ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontFamily: 'monospace',
                        ),
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

  static Future<void> _openGoogleMaps(BuildContext context, double latitude, double longitude) async {
    final googleNavUri = Uri.parse('google.navigation:q=$latitude,$longitude');
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    final iosGoogleMapsUri = Uri.parse('comgooglemaps://?q=$latitude,$longitude');
    final webMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    final candidates = [googleNavUri, geoUri, iosGoogleMapsUri, webMapsUri];

    try {
      for (final uri in candidates) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      throw Exception('Tidak ada aplikasi yang dapat membuka peta');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka Google Maps: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.placeholder),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
