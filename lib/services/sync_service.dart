import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/database_helper.dart';
import 'cloudinary_service.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final dbHelper = DatabaseHelper.instance;

  // Fungsi utama untuk menyinkronkan semua data
  static Future<void> syncSemuaData() async {
    final db = await dbHelper.database;

    // ================= 1. SYNC BUKU PEMINJAMAN (DENGAN FOTO) =================
    final unsyncedPinjam = await db.query(
      'peminjaman',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    for (var map in unsyncedPinjam) {
      try {
        String jaminan = map['jaminan_ekp'] as String;

        // Mengecek apakah foto masih berupa path lokal (belum jadi link Cloudinary)
        if (jaminan.contains('/') && !jaminan.startsWith('http')) {
          final urlCloudinary = await CloudinaryService.uploadFoto(
            File(jaminan),
          );
          if (urlCloudinary != null) {
            jaminan =
                urlCloudinary; // Mengganti path lokal dengan URL Cloudinary
          }
        }

        // Melempar data ke Firebase Firestore
        await _firestore.collection('peminjaman').doc(map['id'] as String).set({
          'nama_santri': map['nama_santri'],
          'nama_barang': map['nama_barang'],
          'tanggal_pinjam': map['tanggal_pinjam'],
          'jaminan_ekp': jaminan, // Sekarang isinya URL online
          'status': map['status'],
          'terakhir_update': FieldValue.serverTimestamp(),
        });

        // Menandai data di HP bahwa sudah berhasil terkirim (is_synced = 1)
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

    // ================= 2. SYNC PENGADUAN KERUSAKAN =================
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

    // ================= 3. SYNC CEKLIS HARIAN =================
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
