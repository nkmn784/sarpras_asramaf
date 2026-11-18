import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef BarisData = Map<String, dynamic>;
typedef StatistikData = Map<String, int>;

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(
      "CREATE TABLE lokasi ("
      "id TEXT PRIMARY KEY, "
      "kode_ruangan TEXT NOT NULL DEFAULT 'RNG-00', "
      "nama_lokasi TEXT NOT NULL, "
      "penanggung_jawab TEXT, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );

    await db.execute(
      "CREATE TABLE item_inventaris ("
      "id TEXT PRIMARY KEY, "
      "id_lokasi TEXT NOT NULL, "
      "kode_unik TEXT NOT NULL DEFAULT 'ITM-000', "
      "nama_barang TEXT NOT NULL, "
      "kategori TEXT NOT NULL, "
      "merek TEXT, "
      "jumlah INTEGER NOT NULL DEFAULT 1, "
      "kondisi TEXT NOT NULL, "
      "keterangan TEXT, "
      "is_synced INTEGER NOT NULL DEFAULT 0, "
      "FOREIGN KEY (id_lokasi) REFERENCES lokasi (id) ON DELETE CASCADE"
      ")",
    );

    await db.execute(
      "CREATE TABLE inspeksi ("
      "id TEXT PRIMARY KEY, "
      "id_lokasi TEXT NOT NULL, "
      "nama_lokasi TEXT NOT NULL, "
      "tanggal TEXT NOT NULL, "
      "petugas TEXT NOT NULL, "
      "kondisi_ruangan TEXT NOT NULL, "
      "catatan TEXT, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );

    await db.execute(
      "CREATE TABLE inspeksi_detail ("
      "id TEXT PRIMARY KEY, "
      "id_inspeksi TEXT NOT NULL, "
      "id_item TEXT NOT NULL, "
      "kode_unik TEXT NOT NULL, "
      "nama_barang TEXT NOT NULL, "
      "kondisi_hasil TEXT NOT NULL, "
      "catatan TEXT"
      ")",
    );

    await db.execute(
      "CREATE TABLE peminjaman ("
      "id TEXT PRIMARY KEY, "
      "nama_santri TEXT NOT NULL, "
      "kamar_santri TEXT, "
      "kode_unik TEXT, "
      "nama_barang TEXT NOT NULL, "
      "tanggal_pinjam TEXT NOT NULL, "
      "batas_kembali TEXT, "
      "jaminan_ekp TEXT NOT NULL, "
      "status TEXT NOT NULL, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );

    await db.execute(
      "CREATE TABLE laporan_warga ("
      "id TEXT PRIMARY KEY, "
      "jenis_laporan TEXT NOT NULL, "
      "nama_pelapor TEXT NOT NULL, "
      "peran_pelapor TEXT NOT NULL, "
      "nama_lokasi TEXT NOT NULL, "
      "nama_barang TEXT NOT NULL, "
      "jumlah INTEGER NOT NULL DEFAULT 1, "
      "deskripsi TEXT NOT NULL, "
      "foto_bukti TEXT, "
      "tanggal_lapor TEXT NOT NULL, "
      "status TEXT NOT NULL, "
      "tanggapan_sarpras TEXT, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );

    await db.execute(
      "CREATE TABLE pengaduan ("
      "id TEXT PRIMARY KEY, "
      "nama_pelapor TEXT NOT NULL, "
      "fasilitas_rusak TEXT NOT NULL, "
      "tanggal_lapor TEXT NOT NULL, "
      "status TEXT NOT NULL, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );

    await db.execute(
      "CREATE TABLE ceklis ("
      "id TEXT PRIMARY KEY, "
      "tanggal TEXT NOT NULL, "
      "petugas TEXT NOT NULL, "
      "nama_fasilitas TEXT NOT NULL, "
      "kondisi TEXT NOT NULL, "
      "is_synced INTEGER NOT NULL DEFAULT 0"
      ")",
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("DROP TABLE IF EXISTS inventaris");
      await _createDB(db, newVersion);
      return;
    }

    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE lokasi ADD COLUMN kode_ruangan TEXT NOT NULL DEFAULT 'RNG-01'",
      );
      await db.execute("ALTER TABLE lokasi ADD COLUMN penanggung_jawab TEXT");
      await db.execute(
        "ALTER TABLE item_inventaris ADD COLUMN kode_unik TEXT NOT NULL DEFAULT 'ITM-001'",
      );
      await db.execute("ALTER TABLE item_inventaris ADD COLUMN merek TEXT");
      await db.execute("ALTER TABLE peminjaman ADD COLUMN kamar_santri TEXT");
      await db.execute("ALTER TABLE peminjaman ADD COLUMN kode_unik TEXT");
      await db.execute("ALTER TABLE peminjaman ADD COLUMN batas_kembali TEXT");

      await db.execute(
        "CREATE TABLE IF NOT EXISTS inspeksi ("
        "id TEXT PRIMARY KEY, "
        "id_lokasi TEXT NOT NULL, "
        "nama_lokasi TEXT NOT NULL, "
        "tanggal TEXT NOT NULL, "
        "petugas TEXT NOT NULL, "
        "kondisi_ruangan TEXT NOT NULL, "
        "catatan TEXT, "
        "is_synced INTEGER NOT NULL DEFAULT 0"
        ")",
      );

      await db.execute(
        "CREATE TABLE IF NOT EXISTS inspeksi_detail ("
        "id TEXT PRIMARY KEY, "
        "id_inspeksi TEXT NOT NULL, "
        "id_item TEXT NOT NULL, "
        "kode_unik TEXT NOT NULL, "
        "nama_barang TEXT NOT NULL, "
        "kondisi_hasil TEXT NOT NULL, "
        "catatan TEXT"
        ")",
      );

      await db.execute(
        "CREATE TABLE IF NOT EXISTS laporan_warga ("
        "id TEXT PRIMARY KEY, "
        "jenis_laporan TEXT NOT NULL, "
        "nama_pelapor TEXT NOT NULL, "
        "peran_pelapor TEXT NOT NULL, "
        "nama_lokasi TEXT NOT NULL, "
        "nama_barang TEXT NOT NULL, "
        "jumlah INTEGER NOT NULL DEFAULT 1, "
        "deskripsi TEXT NOT NULL, "
        "foto_bukti TEXT, "
        "tanggal_lapor TEXT NOT NULL, "
        "status TEXT NOT NULL, "
        "tanggapan_sarpras TEXT, "
        "is_synced INTEGER NOT NULL DEFAULT 0"
        ")",
      );
    }
  }

  // ================= CRUD LOKASI =================
  Future<int> insertLokasi(BarisData row) async {
    final db = await instance.database;
    return await db.insert('lokasi', row);
  }

  Future<List<BarisData>> getAllLokasi() async {
    final db = await instance.database;
    final result = await db.query('lokasi', orderBy: 'kode_ruangan ASC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> deleteLokasi(String id) async {
    final db = await instance.database;
    await db.delete('item_inventaris', where: 'id_lokasi = ?', whereArgs: [id]);
    return await db.delete('lokasi', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD ITEM INVENTARIS =================
  Future<int> insertItem(BarisData row) async {
    final db = await instance.database;
    return await db.insert('item_inventaris', row);
  }

  Future<List<BarisData>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query('item_inventaris', orderBy: 'kode_unik ASC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<List<BarisData>> getItemsByLokasi(String idLokasi) async {
    final db = await instance.database;
    final result = await db.query(
      'item_inventaris',
      where: 'id_lokasi = ?',
      whereArgs: [idLokasi],
      orderBy: 'kode_unik ASC',
    );
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<List<BarisData>> getItemByLokasiAndKategori(
    String idLokasi,
    String kategori,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'item_inventaris',
      where: 'id_lokasi = ? AND kategori = ?',
      whereArgs: [idLokasi, kategori],
      orderBy: 'kode_unik ASC',
    );
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> updateItem(String id, BarisData row) async {
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

  // ================= STATISTIK DASHBOARD =================
  Future<StatistikData> getRingkasanSarpras() async {
    final db = await instance.database;
    final lokasiList = await db.query('lokasi');
    final itemList = await db.query('item_inventaris');
    final pinjamAktif = await db.query(
      'peminjaman',
      where: 'status = ?',
      whereArgs: ['Dipinjam'],
    );
    final laporanMenunggu = await db.query(
      'laporan_warga',
      where: 'status = ?',
      whereArgs: ['Menunggu'],
    );

    int totalUnit = 0;
    int unitRusak = 0;
    for (var item in itemList) {
      final qty = (item['jumlah'] as int?) ?? 1;
      totalUnit += qty;
      if (item['kondisi'] != 'Baik') {
        unitRusak += qty;
      }
    }

    return {
      'totalRuangan': lokasiList.length,
      'totalUnit': totalUnit,
      'unitRusak': unitRusak,
      'pinjamAktif': pinjamAktif.length,
      'laporanMenunggu': laporanMenunggu.length,
    };
  }

  // ================= CRUD PEMINJAMAN =================
  Future<List<BarisData>> getAllPeminjaman() async {
    final db = await instance.database;
    final result = await db.query('peminjaman', orderBy: 'tanggal_pinjam DESC');
    return result.map((e) => BarisData.from(e)).toList();
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

  // ================= CRUD PENGADUAN & CEKLIS =================
  Future<List<BarisData>> getAllPengaduan() async {
    final db = await instance.database;
    final result = await db.query('pengaduan', orderBy: 'tanggal_lapor DESC');
    return result.map((e) => BarisData.from(e)).toList();
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

  Future<List<BarisData>> getAllCeklis() async {
    final db = await instance.database;
    final result = await db.query('ceklis', orderBy: 'tanggal DESC');
    return result.map((e) => BarisData.from(e)).toList();
  }
}
