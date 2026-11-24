import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'cloudinary_service.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final dbHelper = DatabaseHelper.instance;

  static Future<void> syncSemuaData() async {
    if (kIsWeb) return;
    final db = await dbHelper.database;
    await _syncUp(db);
    await _syncDown(db);
  }

  static Future<void> hapusDokumenCloud(String koleksi, String id) async {
    try {
      await _firestore.collection(koleksi).doc(id).delete();
    } catch (e) {
      print('Gagal hapus dokumen Cloud ($koleksi): $e');
    }
  }

  // ================= 1. KIRIM DATA LOKAL KE CLOUD (SYNC UP) =================
  static Future<void> _syncUp(Database db) async {
    // 1. LOKASI
    final unsyncedLokasi = await db.query(
      'lokasi',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedLokasi) {
      try {
        await _firestore.collection('lokasi').doc(map['id'] as String).set({
          'kode_ruangan': map['kode_ruangan'],
          'nama_lokasi': map['nama_lokasi'],
          'penanggung_jawab': map['penanggung_jawab'],
          'terakhir_update': FieldValue.serverTimestamp(),
        });
        await db.update(
          'lokasi',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync up Lokasi: $e');
      }
    }

    // 2. ITEM INVENTARIS
    final unsyncedItem = await db.query(
      'item_inventaris',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedItem) {
      try {
        await _firestore
            .collection('item_inventaris')
            .doc(map['id'] as String)
            .set({
              'id_lokasi': map['id_lokasi'],
              'kode_unik': map['kode_unik'],
              'nama_barang': map['nama_barang'],
              'kategori': map['kategori'],
              'merek': map['merek'],
              'jumlah': map['jumlah'],
              'kondisi': map['kondisi'],
              'keterangan': map['keterangan'],
              'terakhir_update': FieldValue.serverTimestamp(),
            });
        await db.update(
          'item_inventaris',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync up Item Inventaris: $e');
      }
    }

    // 3. INSPEKSI RUANGAN & DETAIL BARANG
    final unsyncedInspeksi = await db.query(
      'inspeksi',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedInspeksi) {
      try {
        final detailList = await db.query(
          'inspeksi_detail',
          where: 'id_inspeksi = ?',
          whereArgs: [map['id']],
        );
        await _firestore.collection('inspeksi').doc(map['id'] as String).set({
          'id_lokasi': map['id_lokasi'],
          'nama_lokasi': map['nama_lokasi'],
          'tanggal': map['tanggal'],
          'petugas': map['petugas'],
          'kondisi_ruangan': map['kondisi_ruangan'],
          'catatan': map['catatan'],
          'detail_barang': detailList,
          'terakhir_update': FieldValue.serverTimestamp(),
        });
        await db.update(
          'inspeksi',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync up Inspeksi: $e');
      }
    }

    // 4. BUKU PEMINJAMAN
    final unsyncedPinjam = await db.query(
      'peminjaman',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedPinjam) {
      try {
        String jaminan = (map['jaminan_ekp'] ?? '').toString();
        if (jaminan.contains('/') && !jaminan.startsWith('http')) {
          final urlCloudinary = await CloudinaryService.uploadFoto(
            XFile(jaminan),
          );
          if (urlCloudinary != null) jaminan = urlCloudinary;
        }

        await _firestore.collection('peminjaman').doc(map['id'] as String).set({
          'nama_santri': map['nama_santri'],
          'kamar_santri': map['kamar_santri'],
          'kode_unik': map['kode_unik'],
          'nama_barang': map['nama_barang'],
          'tanggal_pinjam': map['tanggal_pinjam'],
          'batas_kembali': map['batas_kembali'],
          'jaminan_ekp': jaminan,
          'status': map['status'],
          'terakhir_update': FieldValue.serverTimestamp(),
        });

        await db.update(
          'peminjaman',
          {'is_synced': 1, 'jaminan_ekp': jaminan},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync up Peminjaman: $e');
      }
    }

    // 5. LAPORAN KERUSAKAN & USULAN WARGA
    final unsyncedLaporan = await db.query(
      'laporan_warga',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedLaporan) {
      try {
        String foto = (map['foto_bukti'] ?? '').toString();
        if (foto.contains('/') && !foto.startsWith('http')) {
          final urlCloudinary = await CloudinaryService.uploadFoto(XFile(foto));
          if (urlCloudinary != null) foto = urlCloudinary;
        }

        await _firestore
            .collection('laporan_warga')
            .doc(map['id'] as String)
            .set({
              'jenis_laporan': map['jenis_laporan'],
              'nama_pelapor': map['nama_pelapor'],
              'peran_pelapor': map['peran_pelapor'],
              'nama_lokasi': map['nama_lokasi'],
              'nama_barang': map['nama_barang'],
              'jumlah': map['jumlah'],
              'deskripsi': map['deskripsi'],
              'foto_bukti': foto,
              'tanggal_lapor': map['tanggal_lapor'],
              'status': map['status'],
              'tanggapan_sarpras': map['tanggapan_sarpras'],
              'terakhir_update': FieldValue.serverTimestamp(),
            });

        await db.update(
          'laporan_warga',
          {'is_synced': 1, 'foto_bukti': foto},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync up Laporan Warga: $e');
      }
    }
  }

  // ================= 2. TARIK DATA CLOUD KE LOKAL (SYNC DOWN) =================
  static Future<bool> _punyaPerubahanLokal(
    Database db,
    String tabel,
    String id,
  ) async {
    final cek = await db.query(
      tabel,
      columns: ['is_synced'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (cek.isEmpty) return false;
    return (cek.first['is_synced'] as int?) == 0;
  }

  static Future<void> _syncDown(Database db) async {
    // 1. TARIK LOKASI
    try {
      final snapLokasi = await _firestore.collection('lokasi').get();
      for (var doc in snapLokasi.docs) {
        if (await _punyaPerubahanLokal(db, 'lokasi', doc.id)) continue;
        final d = doc.data();
        await db.insert('lokasi', {
          'id': doc.id,
          'kode_ruangan': (d['kode_ruangan'] ?? 'RNG-00').toString(),
          'nama_lokasi': (d['nama_lokasi'] ?? '').toString(),
          'penanggung_jawab': d['penanggung_jawab']?.toString(),
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Gagal sync down Lokasi: $e');
    }

    // 2. TARIK ITEM INVENTARIS
    try {
      final snapItem = await _firestore.collection('item_inventaris').get();
      for (var doc in snapItem.docs) {
        if (await _punyaPerubahanLokal(db, 'item_inventaris', doc.id)) continue;
        final d = doc.data();
        await db.insert('item_inventaris', {
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
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Gagal sync down Item Inventaris: $e');
    }

    // 3. TARIK INSPEKSI & DETAIL
    try {
      final snapInspeksi = await _firestore.collection('inspeksi').get();
      for (var doc in snapInspeksi.docs) {
        if (await _punyaPerubahanLokal(db, 'inspeksi', doc.id)) continue;
        final d = doc.data();
        await db.insert('inspeksi', {
          'id': doc.id,
          'id_lokasi': (d['id_lokasi'] ?? '').toString(),
          'nama_lokasi': (d['nama_lokasi'] ?? '').toString(),
          'tanggal': (d['tanggal'] ?? '').toString(),
          'petugas': (d['petugas'] ?? '').toString(),
          'kondisi_ruangan': (d['kondisi_ruangan'] ?? 'Bersih & Baik')
              .toString(),
          'catatan': d['catatan']?.toString(),
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final rawDetails = d['detail_barang'];
        if (rawDetails is List) {
          for (var item in rawDetails) {
            if (item is Map) {
              await db.insert('inspeksi_detail', {
                'id': (item['id'] ?? '').toString(),
                'id_inspeksi': doc.id,
                'id_item': (item['id_item'] ?? '').toString(),
                'kode_unik': (item['kode_unik'] ?? '').toString(),
                'nama_barang': (item['nama_barang'] ?? '').toString(),
                'kondisi_hasil': (item['kondisi_hasil'] ?? 'Baik').toString(),
                'catatan': item['catatan']?.toString(),
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }
    } catch (e) {
      print('Gagal sync down Inspeksi: $e');
    }

    // 4. TARIK PEMINJAMAN
    try {
      final snapPinjam = await _firestore.collection('peminjaman').get();
      for (var doc in snapPinjam.docs) {
        if (await _punyaPerubahanLokal(db, 'peminjaman', doc.id)) continue;
        final d = doc.data();
        await db.insert('peminjaman', {
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
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Gagal sync down Peminjaman: $e');
    }

    // 5. TARIK LAPORAN WARGA
    try {
      final snapLaporan = await _firestore.collection('laporan_warga').get();
      for (var doc in snapLaporan.docs) {
        if (await _punyaPerubahanLokal(db, 'laporan_warga', doc.id)) continue;
        final d = doc.data();
        await db.insert('laporan_warga', {
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
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Gagal sync down Laporan Warga: $e');
    }
  }
}
