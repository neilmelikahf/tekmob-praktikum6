class Laporan {
  final int? id;
  final String judul;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final String? fotoPath;
  final String tanggal;

  Laporan({
    this.id,
    required this.judul,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    required this.tanggal,
  });

  /// Mengubah objek Laporan menjadi Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'foto_path': fotoPath,
      'tanggal': tanggal,
    };
  }

  /// Membuat objek Laporan dari Map hasil query SQLite
  factory Laporan.fromMap(Map<String, dynamic> map) {
    return Laporan(
      id: map['id'],
      judul: map['judul'],
      deskripsi: map['deskripsi'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      fotoPath: map['foto_path'],
      tanggal: map['tanggal'],
    );
  }

  @override
  String toString() {
    return 'Laporan{id: $id, judul: $judul, lat: $latitude, lng: $longitude}';
  }
}
