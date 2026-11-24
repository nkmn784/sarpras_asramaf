import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

typedef BarisData = Map<String, dynamic>;
typedef StatistikData = Map<String, int>;
typedef DokumenFirestore = QueryDocumentSnapshot<BarisData>;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

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

  BarisData _mapItemDoc(DokumenFirestore doc) {
    final d = doc.data();
    return {
      'id': doc.id,
      'id_lokasi': (d['id_lokasi'] ?? '').toString(),
      'kode_unik': (d['kode_unik'] ?? 'ITM-000').toString(),
      'nama_barang': (d['nama_barang'] ?? '').toString(),
      'kategori': (d['kategori'] ?? 'Peralatan').toString(),
      'merek': d['merek']?.toString(),
      'jumlah': (d['jumlah'] as num?)?.toInt() ?? 1,
      'kondisi': (d['kondisi'] ?? 'Baik').toString(),
      'keterangan': d['keterangan']?.toString(),
      'is_synced': 1,
    };
  }

  // ================= CRUD LOKASI =================
  Future<int> insertLokasi(BarisData row) async {
    if (kIsWeb) {
      await _firestore.collection('lokasi').doc(row['id'] as String).set({
        'kode_ruangan': row['kode_ruangan'],
        'nama_lokasi': row['nama_lokasi'],
        'penanggung_jawab': row['penanggung_jawab'],
        'terakhir_update': FieldValue.serverTimestamp(),
      });
      return 1;
    }
    final db = await instance.database;
    return await db.insert('lokasi', row);
  }

  Future<List<BarisData>> getAllLokasi() async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('lokasi')
          .orderBy('kode_ruangan')
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'kode_ruangan': (d['kode_ruangan'] ?? 'RNG-00').toString(),
          'nama_lokasi': (d['nama_lokasi'] ?? '').toString(),
          'penanggung_jawab': d['penanggung_jawab']?.toString(),
          'is_synced': 1,
        };
      }).toList();
    }
    final db = await instance.database;
    final result = await db.query('lokasi', orderBy: 'kode_ruangan ASC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> deleteLokasi(String id) async {
    if (kIsWeb) {
      final itemsSnap = await _firestore
          .collection('item_inventaris')
          .where('id_lokasi', isEqualTo: id)
          .get();
      for (var doc in itemsSnap.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('lokasi').doc(id).delete();
      return 1;
    }
    final db = await instance.database;
    await db.delete('item_inventaris', where: 'id_lokasi = ?', whereArgs: [id]);
    return await db.delete('lokasi', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD ITEM INVENTARIS =================
  Future<int> insertItem(BarisData row) async {
    if (kIsWeb) {
      await _firestore
          .collection('item_inventaris')
          .doc(row['id'] as String)
          .set({
            'id_lokasi': row['id_lokasi'],
            'kode_unik': row['kode_unik'],
            'nama_barang': row['nama_barang'],
            'kategori': row['kategori'],
            'merek': row['merek'],
            'jumlah': row['jumlah'],
            'kondisi': row['kondisi'],
            'keterangan': row['keterangan'],
            'terakhir_update': FieldValue.serverTimestamp(),
          });
      return 1;
    }
    final db = await instance.database;
    return await db.insert('item_inventaris', row);
  }

  Future<List<BarisData>> getAllItems() async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('item_inventaris')
          .orderBy('kode_unik')
          .get();
      return snap.docs.map(_mapItemDoc).toList();
    }
    final db = await instance.database;
    final result = await db.query('item_inventaris', orderBy: 'kode_unik ASC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<List<BarisData>> getItemsByLokasi(String idLokasi) async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('item_inventaris')
          .where('id_lokasi', isEqualTo: idLokasi)
          .get();
      final list = snap.docs.map(_mapItemDoc).toList();
      list.sort(
        (a, b) =>
            (a['kode_unik'] as String).compareTo(b['kode_unik'] as String),
      );
      return list;
    }
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
    if (kIsWeb) {
      final snap = await _firestore
          .collection('item_inventaris')
          .where('id_lokasi', isEqualTo: idLokasi)
          .where('kategori', isEqualTo: kategori)
          .get();
      final list = snap.docs.map(_mapItemDoc).toList();
      list.sort(
        (a, b) =>
            (a['kode_unik'] as String).compareTo(b['kode_unik'] as String),
      );
      return list;
    }
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
    if (kIsWeb) {
      final dataUpdate = BarisData.from(row);
      dataUpdate.remove('id');
      dataUpdate.remove('is_synced');
      dataUpdate['terakhir_update'] = FieldValue.serverTimestamp();
      await _firestore.collection('item_inventaris').doc(id).update(dataUpdate);
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'item_inventaris',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(String id) async {
    if (kIsWeb) {
      await _firestore.collection('item_inventaris').doc(id).delete();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('item_inventaris', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD INSPEKSI RUANGAN =================
  Future<void> simpanInspeksiLengkap({
    required BarisData headerInspeksi,
    required List<BarisData> daftarDetail,
  }) async {
    if (kIsWeb) {
      final idInspeksi = headerInspeksi['id'] as String;
      await _firestore.collection('inspeksi').doc(idInspeksi).set({
        'id_lokasi': headerInspeksi['id_lokasi'],
        'nama_lokasi': headerInspeksi['nama_lokasi'],
        'tanggal': headerInspeksi['tanggal'],
        'petugas': headerInspeksi['petugas'],
        'kondisi_ruangan': headerInspeksi['kondisi_ruangan'],
        'catatan': headerInspeksi['catatan'],
        'detail_barang': daftarDetail,
        'terakhir_update': FieldValue.serverTimestamp(),
      });
      for (var detail in daftarDetail) {
        await _firestore
            .collection('item_inventaris')
            .doc(detail['id_item'] as String)
            .update({
              'kondisi': detail['kondisi_hasil'],
              'terakhir_update': FieldValue.serverTimestamp(),
            });
      }
      return;
    }

    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('inspeksi', headerInspeksi);

      for (var detail in daftarDetail) {
        await txn.insert('inspeksi_detail', detail);
        await txn.update(
          'item_inventaris',
          {'kondisi': detail['kondisi_hasil'], 'is_synced': 0},
          where: 'id = ?',
          whereArgs: [detail['id_item']],
        );
      }
    });
  }

  Future<List<BarisData>> getAllInspeksi() async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('inspeksi')
          .orderBy('tanggal', descending: true)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'id_lokasi': (d['id_lokasi'] ?? '').toString(),
          'nama_lokasi': (d['nama_lokasi'] ?? '').toString(),
          'tanggal': (d['tanggal'] ?? '').toString(),
          'petugas': (d['petugas'] ?? '').toString(),
          'kondisi_ruangan': (d['kondisi_ruangan'] ?? 'Bersih & Baik')
              .toString(),
          'catatan': d['catatan']?.toString(),
          'is_synced': 1,
        };
      }).toList();
    }
    final db = await instance.database;
    final result = await db.query('inspeksi', orderBy: 'tanggal DESC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<List<BarisData>> getDetailInspeksi(String idInspeksi) async {
    if (kIsWeb) {
      final doc = await _firestore.collection('inspeksi').doc(idInspeksi).get();
      final rawDetails = doc.data()?['detail_barang'];
      if (rawDetails is List) {
        final list = rawDetails
            .whereType()
            .map((e) => BarisData.from(e))
            .toList();
        list.sort(
          (a, b) => (a['kode_unik'] ?? '').toString().compareTo(
            (b['kode_unik'] ?? '').toString(),
          ),
        );
        return list;
      }
      return [];
    }
    final db = await instance.database;
    final result = await db.query(
      'inspeksi_detail',
      where: 'id_inspeksi = ?',
      whereArgs: [idInspeksi],
      orderBy: 'kode_unik ASC',
    );
    return result.map((e) => BarisData.from(e)).toList();
  }

  // ================= CRUD LAPORAN KERUSAKAN & USULAN WARGA =================
  Future<int> insertLaporanWarga(BarisData row) async {
    if (kIsWeb) {
      await _firestore.collection('laporan_warga').doc(row['id'] as String).set(
        {
          'jenis_laporan': row['jenis_laporan'],
          'nama_pelapor': row['nama_pelapor'],
          'peran_pelapor': row['peran_pelapor'],
          'nama_lokasi': row['nama_lokasi'],
          'nama_barang': row['nama_barang'],
          'jumlah': row['jumlah'],
          'deskripsi': row['deskripsi'],
          'foto_bukti': row['foto_bukti'],
          'tanggal_lapor': row['tanggal_lapor'],
          'status': row['status'],
          'tanggapan_sarpras': row['tanggapan_sarpras'],
          'terakhir_update': FieldValue.serverTimestamp(),
        },
      );
      return 1;
    }
    final db = await instance.database;
    return await db.insert('laporan_warga', row);
  }

  Future<List<BarisData>> getAllLaporanWarga() async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('laporan_warga')
          .orderBy('tanggal_lapor', descending: true)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'jenis_laporan': (d['jenis_laporan'] ?? 'Laporan Kerusakan')
              .toString(),
          'nama_pelapor': (d['nama_pelapor'] ?? '').toString(),
          'peran_pelapor': (d['peran_pelapor'] ?? '').toString(),
          'nama_lokasi': (d['nama_lokasi'] ?? '').toString(),
          'nama_barang': (d['nama_barang'] ?? '').toString(),
          'jumlah': (d['jumlah'] as num?)?.toInt() ?? 1,
          'deskripsi': (d['deskripsi'] ?? '').toString(),
          'foto_bukti': d['foto_bukti']?.toString(),
          'tanggal_lapor': (d['tanggal_lapor'] ?? '').toString(),
          'status': (d['status'] ?? 'Menunggu').toString(),
          'tanggapan_sarpras': d['tanggapan_sarpras']?.toString(),
          'is_synced': 1,
        };
      }).toList();
    }
    final db = await instance.database;
    final result = await db.query(
      'laporan_warga',
      orderBy: 'tanggal_lapor DESC',
    );
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> updateTindakLanjutLaporan(
    String id,
    String statusBaru,
    String tanggapan,
  ) async {
    if (kIsWeb) {
      await _firestore.collection('laporan_warga').doc(id).update({
        'status': statusBaru,
        'tanggapan_sarpras': tanggapan,
        'terakhir_update': FieldValue.serverTimestamp(),
      });
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'laporan_warga',
      {'status': statusBaru, 'tanggapan_sarpras': tanggapan, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLaporanWarga(String id) async {
    if (kIsWeb) {
      await _firestore.collection('laporan_warga').doc(id).delete();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('laporan_warga', where: 'id = ?', whereArgs: [id]);
  }

  // ================= STATISTIK DASHBOARD =================
  Future<StatistikData> getRingkasanSarpras() async {
    if (kIsWeb) {
      final lokasiSnap = await _firestore.collection('lokasi').get();
      final itemSnap = await _firestore.collection('item_inventaris').get();
      final pinjamSnap = await _firestore
          .collection('peminjaman')
          .where('status', isEqualTo: 'Dipinjam')
          .get();
      final laporanSnap = await _firestore
          .collection('laporan_warga')
          .where('status', isEqualTo: 'Menunggu')
          .get();

      int totalUnit = 0;
      int unitRusak = 0;
      for (var doc in itemSnap.docs) {
        final d = doc.data();
        final qty = (d['jumlah'] as num?)?.toInt() ?? 1;
        totalUnit += qty;
        if (d['kondisi'] != 'Baik') {
          unitRusak += qty;
        }
      }

      return {
        'totalRuangan': lokasiSnap.docs.length,
        'totalUnit': totalUnit,
        'unitRusak': unitRusak,
        'pinjamAktif': pinjamSnap.docs.length,
        'laporanMenunggu': laporanSnap.docs.length,
      };
    }

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
  Future<int> insertPeminjaman(BarisData row) async {
    if (kIsWeb) {
      await _firestore.collection('peminjaman').doc(row['id'] as String).set({
        'nama_santri': row['nama_santri'],
        'kamar_santri': row['kamar_santri'],
        'kode_unik': row['kode_unik'],
        'nama_barang': row['nama_barang'],
        'tanggal_pinjam': row['tanggal_pinjam'],
        'batas_kembali': row['batas_kembali'],
        'jaminan_ekp': row['jaminan_ekp'],
        'status': row['status'],
        'terakhir_update': FieldValue.serverTimestamp(),
      });
      return 1;
    }
    final db = await instance.database;
    return await db.insert('peminjaman', row);
  }

  Future<List<BarisData>> getAllPeminjaman() async {
    if (kIsWeb) {
      final snap = await _firestore
          .collection('peminjaman')
          .orderBy('tanggal_pinjam', descending: true)
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'nama_santri': (d['nama_santri'] ?? '').toString(),
          'kamar_santri': d['kamar_santri']?.toString(),
          'kode_unik': d['kode_unik']?.toString(),
          'nama_barang': (d['nama_barang'] ?? '').toString(),
          'tanggal_pinjam': (d['tanggal_pinjam'] ?? '').toString(),
          'batas_kembali': d['batas_kembali']?.toString(),
          'jaminan_ekp': (d['jaminan_ekp'] ?? '').toString(),
          'status': (d['status'] ?? 'Dipinjam').toString(),
          'is_synced': 1,
        };
      }).toList();
    }
    final db = await instance.database;
    final result = await db.query('peminjaman', orderBy: 'tanggal_pinjam DESC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> updateStatusPeminjaman(String id, String statusBaru) async {
    if (kIsWeb) {
      await _firestore.collection('peminjaman').doc(id).update({
        'status': statusBaru,
        'terakhir_update': FieldValue.serverTimestamp(),
      });
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'peminjaman',
      {'status': statusBaru, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePeminjaman(String id) async {
    if (kIsWeb) {
      await _firestore.collection('peminjaman').doc(id).delete();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('peminjaman', where: 'id = ?', whereArgs: [id]);
  }

  // ================= CRUD PENGADUAN & CEKLIS LEGACY =================
  Future<List<BarisData>> getAllPengaduan() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    final result = await db.query('pengaduan', orderBy: 'tanggal_lapor DESC');
    return result.map((e) => BarisData.from(e)).toList();
  }

  Future<int> updateStatusPengaduan(String id, String statusBaru) async {
    if (kIsWeb) return 1;
    final db = await instance.database;
    return await db.update(
      'pengaduan',
      {'status': statusBaru, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BarisData>> getAllCeklis() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    final result = await db.query('ceklis', orderBy: 'tanggal DESC');
    return result.map((e) => BarisData.from(e)).toList();
  }
}
