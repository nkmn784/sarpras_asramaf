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
          'nama_lokasi': map['nama_lokasi'],
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
              'nama_barang': map['nama_barang'],
              'kategori': map['kategori'],
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

    // 3. SYNC BUKU PEMINJAMAN (FOTO TO CLOUDINARY)
    final unsyncedPinjam = await db.query(
      'peminjaman',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedPinjam) {
      try {
        String jaminan = map['jaminan_ekp'] as String;
        if (jaminan.contains('/') && !jaminan.startsWith('http')) {
          final urlCloudinary = await CloudinaryService.uploadFoto(
            File(jaminan),
          );
          if (urlCloudinary != null) jaminan = urlCloudinary;
        }

        await _firestore.collection('peminjaman').doc(map['id'] as String).set({
          'nama_santri': map['nama_santri'],
          'nama_barang': map['nama_barang'],
          'tanggal_pinjam': map['tanggal_pinjam'],
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

    // 4. SYNC PENGADUAN
    final unsyncedAduan = await db.query(
      'pengaduan',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedAduan) {
      try {
        await _firestore.collection('pengaduan').doc(map['id'] as String).set({
          'nama_pelapor': map['nama_pelapor'],
          'fasilitas_rusak': map['fasilitas_rusak'],
          'tanggal_lapor': map['tanggal_lapor'],
          'status': map['status'],
          'terakhir_update': FieldValue.serverTimestamp(),
        });
        await db.update(
          'pengaduan',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync Pengaduan: $e');
      }
    }

    // 5. SYNC CEKLIS
    final unsyncedCeklis = await db.query(
      'ceklis',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedCeklis) {
      try {
        await _firestore.collection('ceklis').doc(map['id'] as String).set({
          'tanggal': map['tanggal'],
          'petugas': map['petugas'],
          'nama_fasilitas': map['nama_fasilitas'],
          'kondisi': map['kondisi'],
          'terakhir_update': FieldValue.serverTimestamp(),
        });
        await db.update(
          'ceklis',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      } catch (e) {
        print('Gagal sync Ceklis: $e');
      }
    }
  }
}
