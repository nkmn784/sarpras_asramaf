import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/barang.dart';
import '../models/peminjaman.dart';
import '../models/pengaduan.dart';
import '../models/ceklis.dart';

class DatabaseHelper {
  // Membuat Singleton agar aplikasi hanya menggunakan satu koneksi database yang sama
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sarpras_asramaf.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Mencari lokasi memori internal perangkat yang aman untuk menyimpan file .db
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Membuka database, jika belum ada maka akan menjalankan fungsi _createDB
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Membuat tabel inventaris (yang sudah ada)
    await db.execute('''
    CREATE TABLE inventaris (
      id TEXT PRIMARY KEY,
      nama_barang TEXT NOT NULL,
      jumlah INTEGER NOT NULL,
      kondisi_baik INTEGER NOT NULL,
      kondisi_tidak INTEGER NOT NULL,
      is_synced INTEGER NOT NULL
    )
    ''');

    // MENGAPLIKASIKAN TABEL BARU: Membuat tabel peminjaman
    await db.execute('''
    CREATE TABLE peminjaman (
      id TEXT PRIMARY KEY,
      nama_santri TEXT NOT NULL,
      nama_barang TEXT NOT NULL,
      tanggal_pinjam TEXT NOT NULL,
      jaminan_ekp TEXT NOT NULL,
      status TEXT NOT NULL,
      is_synced INTEGER NOT NULL
    )
    ''');
    // MENGAPLIKASIKAN TABEL BARU: Membuat tabel pengaduan
    await db.execute('''
    CREATE TABLE pengaduan (
      id TEXT PRIMARY KEY,
      nama_pelapor TEXT NOT NULL,
      fasilitas_rusak TEXT NOT NULL,
      tanggal_lapor TEXT NOT NULL,
      status TEXT NOT NULL,
      is_synced INTEGER NOT NULL
    )
    ''');
    // MENGAPLIKASIKAN TABEL BARU: Membuat tabel ceklis harian
    await db.execute('''
    CREATE TABLE ceklis (
      id TEXT PRIMARY KEY,
      tanggal TEXT NOT NULL,
      petugas TEXT NOT NULL,
      nama_fasilitas TEXT NOT NULL,
      kondisi INTEGER NOT NULL,
      is_synced INTEGER NOT NULL
    )
    ''');
  }

  // Fungsi untuk menambah data barang ke database (CREATE)
  Future<void> insertBarang(Barang barang) async {
    final db = await instance.database;
    await db.insert(
      'inventaris',
      barang.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Menimpa data jika ada ID yang sama
    );
  }

  // Fungsi untuk menarik seluruh data barang dari database (READ)
  Future<List<Barang>> getAllBarang() async {
    final db = await instance.database;
    final result = await db.query(
      'inventaris',
    ); // Memanggil isi tabel inventaris

    // Mengubah data mentah dari database kembali menjadi List<Barang>
    return result.map((map) => Barang.fromMap(map)).toList();
  }

  // Fungsi untuk mengedit data barang (UPDATE)
  Future<void> updateBarang(Barang barang) async {
    final db = await instance.database;
    await db.update(
      'inventaris',
      barang.toMap(),
      where: 'id = ?', // Mencari barang berdasarkan ID-nya
      whereArgs: [barang.id],
    );
  }

  // Fungsi untuk menghapus data barang (DELETE)
  Future<void> deleteBarang(String id) async {
    final db = await instance.database;
    await db.delete('inventaris', where: 'id = ?', whereArgs: [id]);
  }
  // ================= BAGIAN PEMINJAMAN =================

  // 1. Simpan data peminjaman baru
  Future<void> insertPeminjaman(Peminjaman peminjaman) async {
    final db = await instance.database;
    await db.insert(
      'peminjaman',
      peminjaman.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Tampilkan semua riwayat peminjaman
  Future<List<Peminjaman>> getAllPeminjaman() async {
    final db = await instance.database;
    final result = await db.query('peminjaman', orderBy: 'tanggal_pinjam DESC');
    return result.map((map) => Peminjaman.fromMap(map)).toList();
  }

  // 3. Update status peminjaman (Misal saat santri mengembalikan barang)
  Future<void> updateStatusPeminjaman(String id, String statusBaru) async {
    final db = await instance.database;
    await db.update(
      'peminjaman',
      {
        'status': statusBaru,
        'is_synced': 0,
      }, // is_synced 0 agar disinkronkan lagi ke cloud
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // ================= BAGIAN PENGADUAN =================

  Future<void> insertPengaduan(Pengaduan pengaduan) async {
    final db = await instance.database;
    await db.insert(
      'pengaduan',
      pengaduan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Pengaduan>> getAllPengaduan() async {
    final db = await instance.database;
    final result = await db.query('pengaduan', orderBy: 'tanggal_lapor DESC');
    return result.map((map) => Pengaduan.fromMap(map)).toList();
  }

  Future<void> updateStatusPengaduan(String id, String statusBaru) async {
    final db = await instance.database;
    await db.update(
      'pengaduan',
      {'status': statusBaru, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // ================= BAGIAN CEKLIS HARIAN =================

  Future<void> insertCeklis(Ceklis ceklis) async {
    final db = await instance.database;
    await db.insert(
      'ceklis',
      ceklis.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Ceklis>> getAllCeklis() async {
    final db = await instance.database;
    // Mengurutkan dari tanggal pengecekan terbaru
    final result = await db.query('ceklis', orderBy: 'tanggal DESC');
    return result.map((map) => Ceklis.fromMap(map)).toList();
  }
}
