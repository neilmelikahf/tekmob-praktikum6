import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/laporan.dart';

class DatabaseHelper {
  // Singleton pattern agar hanya ada satu instance DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Getter database: inisialisasi jika belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Menginisialisasi dan membuka koneksi ke database SQLite
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'laporan_lapangan.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Callback onCreate: membuat tabel saat database pertama kali dibuat
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laporan (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        judul     TEXT    NOT NULL,
        deskripsi TEXT    NOT NULL,
        latitude  REAL    NOT NULL,
        longitude REAL    NOT NULL,
        foto_path TEXT,
        tanggal   TEXT    NOT NULL
      )
    ''');
  }

  // ───────────────────────── CRUD Operations ──────────────────────────

  /// Menyimpan laporan baru ke database.
  /// Mengembalikan ID baris yang baru dibuat.
  Future<int> insertLaporan(Laporan laporan) async {
    final db = await database;
    return await db.insert(
      'laporan',
      laporan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua laporan, diurutkan dari yang terbaru (id DESC).
  Future<List<Laporan>> getAllLaporan() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'laporan',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Laporan.fromMap(maps[i]));
  }

  /// Menghapus laporan berdasarkan ID.
  Future<int> deleteLaporan(int id) async {
    final db = await database;
    return await db.delete(
      'laporan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menutup koneksi database (opsional, biasanya dipanggil saat dispose).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
