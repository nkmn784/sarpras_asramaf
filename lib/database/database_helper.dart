import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sarpras_asrama.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lokasi (
        id TEXT PRIMARY KEY,
        nama_lokasi TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE item_inventaris (
        id TEXT PRIMARY KEY,
        id_lokasi TEXT NOT NULL,
        nama_barang TEXT NOT NULL,
        kategori TEXT NOT NULL,
        jumlah INTEGER NOT NULL DEFAULT 1,
        kondisi TEXT NOT NULL,
        keterangan TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_lokasi) REFERENCES lokasi (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE peminjaman (
        id TEXT PRIMARY KEY,
        nama_santri TEXT NOT NULL,
        nama_barang TEXT NOT NULL,
        tanggal_pinjam TEXT NOT NULL,
        jaminan_ekp TEXT NOT NULL,
        status TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE pengaduan (
        id TEXT PRIMARY KEY,
        nama_pelapor TEXT NOT NULL,
        fasilitas_rusak TEXT NOT NULL,
        tanggal_lapor TEXT NOT NULL,
        status TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ceklis (
        id TEXT PRIMARY KEY,
        tanggal TEXT NOT NULL,
        petugas TEXT NOT NULL,
        nama_fasilitas TEXT NOT NULL,
        kondisi TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS inventaris');
      await _createDB(db, newVersion);
    }
  }

  // ================= CRUD LOKASI =================
  Future<int> insertLokasi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('lokasi', row);
  }

  Future<List> getAllLokasi() async {
    final db = await instance.database;
    final result = await db.query('lokasi', orderBy: 'nama_lokasi ASC');
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> deleteLokasi(String id) async {
    final db = await instance.database;
    await db.delete('item_inventaris', where: 'id_lokasi = ?', whereArgs: [id]);
    return await db.delete('lokasi', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD ITEM INVENTARIS =================
  Future<int> insertItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('item_inventaris', row);
  }

  Future<List> getItemByLokasiAndKategori(
    String idLokasi,
    String kategori,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'item_inventaris',
      where: 'id_lokasi = ? AND kategori = ?',
      whereArgs: [idLokasi, kategori],
      orderBy: 'nama_barang ASC',
    );
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> updateItem(String id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'item_inventaris',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(String id) async {
    final db = await instance.database;
    return await db.delete('item_inventaris', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD PEMINJAMAN =================
  Future<List> getAllPeminjaman() async {
    final db = await instance.database;
    final result = await db.query('peminjaman', orderBy: 'tanggal_pinjam DESC');
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> updateStatusPeminjaman(String id, String statusBaru) async {
    final db = await instance.database;
    return await db.update(
      'peminjaman',
      {'status': statusBaru, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= CRUD PENGADUAN =================
  Future<List> getAllPengaduan() async {
    final db = await instance.database;
    final result = await db.query('pengaduan', orderBy: 'tanggal_lapor DESC');
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<int> updateStatusPengaduan(String id, String statusBaru) async {
    final db = await instance.database;
    return await db.update(
      'pengaduan',
      {'status': statusBaru, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= CRUD CEKLIS =================
  Future<List> getAllCeklis() async {
    final db = await instance.database;
    final result = await db.query('ceklis', orderBy: 'tanggal DESC');
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
