import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/database_helper.dart';
import 'cloudinary_service.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final dbHelper = DatabaseHelper.instance;

  static Future<void> syncSemuaData() async {
    final db = await dbHelper.database;

    // 1. SYNC LOKASI
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
        print('Gagal sync Lokasi: $e');
      }
    }

    // 2. SYNC ITEM INVENTARIS
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
        print('Gagal sync Item Inventaris: $e');
      }
    }

    // 3. SYNC INSPEKSI RUANGAN & DETAIL BARANG
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
        print('Gagal sync Inspeksi: $e');
      }
    }

    // 4. SYNC BUKU PEMINJAMAN
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
            File(jaminan),
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
        print('Gagal sync Peminjaman: $e');
      }
    }

    // 5. SYNC LAPORAN KERUSAKAN & USULAN WARGA
    final unsyncedLaporan = await db.query(
      'laporan_warga',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedLaporan) {
      try {
        String foto = (map['foto_bukti'] ?? '').toString();
        if (foto.contains('/') && !foto.startsWith('http')) {
          final urlCloudinary = await CloudinaryService.uploadFoto(File(foto));
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
        print('Gagal sync Laporan Warga: $e');
      }
    }
  }
}
