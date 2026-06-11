import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

import '../db/database_helper.dart';
import '../models/laporan.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/preference_service.dart';
import 'riwayat_laporan_screen.dart';

class TambahLaporanScreen extends StatefulWidget {
  const TambahLaporanScreen({super.key});

  @override
  State<TambahLaporanScreen> createState() => _TambahLaporanScreenState();
}

class _TambahLaporanScreenState extends State<TambahLaporanScreen> {
  // ─── Controllers & Services ───────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  final _cameraService = CameraService();
  final _locationService = LocationService();
  final _dbHelper = DatabaseHelper();
  final _preferenceService = PreferenceService();

  // ─── State Variables ──────────────────────────────────────────────────
  File? _fotoFile;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // ─── Shared Preferences ─────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final draft = await _preferenceService.loadDraft();
    final judul = draft['judul'];
    final deskripsi = draft['deskripsi'];

    if (judul != null && judul.isNotEmpty) {
      _judulController.text = judul;
    }
    if (deskripsi != null && deskripsi.isNotEmpty) {
      _deskripsiController.text = deskripsi;
    }
  }

  Future<void> _saveDraft() async {
    await _preferenceService.saveDraft(
      judul: _judulController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
    );
  }

  Future<void> _clearDraft() async {
    await _preferenceService.clearDraft();
  }

  // ─── Handlers ─────────────────────────────────────────────────────────

  /// Mengambil foto dari kamera dan sekaligus menarik GPS
  Future<void> _ambilFotoDanLokasi() async {
    // 1. Ambil foto dari kamera
    try {
      final foto = await _cameraService.takePicture();
      if (foto == null) return; // Dibatalkan pengguna
      setState(() => _fotoFile = foto);
    } catch (e) {
      _showSnackBar('Kamera: $e', isError: true);
      return;
    }

    // 2. Secara otomatis ambil koordinat GPS
    await _ambilLokasi();
  }

  /// Mengambil koordinat GPS terkini
  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() => _currentPosition = position);
      _showSnackBar('Lokasi berhasil didapatkan ✓');
    } catch (e) {
      _showSnackBar('GPS: $e', isError: true);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Memilih foto dari galeri (alternatif kamera)
  Future<void> _pilihDariGaleri() async {
    try {
      final foto = await _cameraService.pickFromGallery();
      if (foto == null) return;
      setState(() => _fotoFile = foto);
    } catch (e) {
      _showSnackBar('Galeri: $e', isError: true);
    }
  }

  /// Menyimpan laporan ke database SQLite
  Future<void> _submitLaporan() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    if (_fotoFile == null) {
      _showSnackBar('Mohon ambil foto bukti terlebih dahulu.', isError: true);
      return;
    }
    if (_currentPosition == null) {
      _showSnackBar('Mohon aktifkan GPS dan ambil koordinat lokasi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final laporan = Laporan(
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        fotoPath: _fotoFile!.path,
        tanggal: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
      );

      final id = await _dbHelper.insertLaporan(laporan);

      if (mounted) {
        _showSnackBar('Laporan #$id berhasil disimpan ✓');
        await _clearDraft();
        _resetForm();
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Mereset semua field ke kondisi awal
  void _resetForm() {
    _judulController.clear();
    _deskripsiController.clear();
    setState(() {
      _fotoFile = null;
      _currentPosition = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Buat Laporan',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.surface),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.surface),
            tooltip: 'Riwayat Laporan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RiwayatLaporanScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Banner ──────────────────────────────────────
              _buildHeaderBanner(),
              const SizedBox(height: 20),

              // ── Seksi Foto ─────────────────────────────────────────
              _buildSectionLabel('📷  Bukti Foto'),
              const SizedBox(height: 8),
              _buildFotoSection(),
              const SizedBox(height: 20),

              // ── Seksi GPS ──────────────────────────────────────────
              _buildSectionLabel('📍  Koordinat Lokasi'),
              const SizedBox(height: 8),
              _buildLokasiSection(),
              const SizedBox(height: 20),

              // ── Form Input ─────────────────────────────────────────
              _buildSectionLabel('📝  Detail Laporan'),
              const SizedBox(height: 8),
              _buildFormCard(),
              const SizedBox(height: 24),

              // ── Tombol Submit ──────────────────────────────────────
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment_outlined, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelaporan Lapangan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dokumentasi kejadian dengan foto & GPS',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildFotoSection() {
    return Container(
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
        children: [
          // Preview foto
          if (_fotoFile != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                _fotoFile!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.placeholderBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.placeholder),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: AppColors.placeholder, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Tombol aksi foto
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _ambilFotoDanLokasi,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Kamera + GPS'),
                      style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pilihDariGaleri,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiSection() {
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
      child: Row(
        children: [
          // Info koordinat
          Expanded(
            child: _currentPosition != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Koordinat Berhasil Diambil',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 6),
                      _coordRow('Latitude', _currentPosition!.latitude.toStringAsFixed(6)),
                      _coordRow('Longitude', _currentPosition!.longitude.toStringAsFixed(6)),
                      _coordRow('Akurasi', '±${_currentPosition!.accuracy.toStringAsFixed(1)} m'),
                    ],
                  )
                : const Text(
                      'Koordinat GPS belum diambil.\nTekan "Kamera + GPS" atau tombol di samping.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
          ),
          const SizedBox(width: 12),
          // Tombol refresh lokasi
          _isLoadingLocation
              ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        )
              : IconButton(
                  onPressed: _ambilLokasi,
                  icon: const Icon(Icons.my_location),
                    color: AppColors.primary,
                  tooltip: 'Perbarui Lokasi',
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _coordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          Text(
            ': $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
        children: [
          // Field Judul
          TextFormField(
            controller: _judulController,
            decoration: _inputDecoration(
              label: 'Judul Laporan',
              hint: '',
              icon: Icons.title,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _saveDraft(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Judul laporan tidak boleh kosong';
              }
              if (value.trim().length < 5) {
                return 'Judul minimal 5 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Field Deskripsi
          TextFormField(
            controller: _deskripsiController,
            decoration: _inputDecoration(
              label: 'Deskripsi Kejadian',
              hint: 'Jelaskan kondisi, situasi, atau kejadian yang dilaporkan...',
              icon: Icons.description_outlined,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _saveDraft(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Deskripsi kejadian tidak boleh kosong';
              }
              if (value.trim().length < 10) {
                return 'Deskripsi minimal 10 karakter';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      filled: true,
          fillColor: AppColors.surface,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitLaporan,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded, size: 22),
        label: Text(
          _isSubmitting ? 'Menyimpan...' : 'Kirim Laporan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.placeholder,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }
}
