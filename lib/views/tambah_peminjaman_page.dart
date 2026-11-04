import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../models/peminjaman.dart';

class TambahPeminjamanPage extends StatefulWidget {
  const TambahPeminjamanPage({super.key});

  @override
  State<TambahPeminjamanPage> createState() => _TambahPeminjamanPageState();
}

class _TambahPeminjamanPageState extends State<TambahPeminjamanPage> {
  final _namaController = TextEditingController();
  final _barangController = TextEditingController();

  File? _fotoEkp; // Variabel untuk menyimpan file foto sementara
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk membuka kamera HP
  Future<void> _bukaKamera() async {
    // Membuka kamera dengan kualitas 50% agar ukuran file tidak membebani memori HP
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (foto != null) {
      setState(() {
        _fotoEkp = File(foto.path); // Menyimpan lokasi path foto ke variabel
      });
    }
  }

  Future<void> _simpanPinjaman() async {
    if (_fotoEkp == null) {
      // Peringatan jika pengurus lupa memfoto EKP
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto EKP santri wajib disertakan!')),
      );
      return;
    }

    const uuid = Uuid();
    final pinjamanBaru = Peminjaman(
      id: uuid.v4(),
      namaSantri: _namaController.text,
      namaBarang: _barangController.text,
      tanggalPinjam: DateTime.now().toString().substring(0, 10),
      jaminanEkp:
          _fotoEkp!.path, // Yang disimpan ke SQLite adalah path lokasi fotonya
      status: 'Dipinjam',
      isSynced: 0,
    );

    await DatabaseHelper.instance.insertPeminjaman(pinjamanBaru);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Peminjaman'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Santri'),
            ),
            TextField(
              controller: _barangController,
              decoration: const InputDecoration(
                labelText: 'Barang yang Dipinjam',
              ),
            ),
            const SizedBox(height: 20),

            // Area Foto EKP
            const Text(
              'Foto Jaminan EKP:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _fotoEkp != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _fotoEkp!,
                        fit: BoxFit.cover,
                      ), // Menampilkan foto jika ada
                    )
                  : const Center(child: Text('Belum ada foto EKP')),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Buka Kamera'),
              onPressed: _bukaKamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: _simpanPinjaman,
              child: const Text('Simpan Peminjaman'),
            ),
          ],
        ),
      ),
    );
  }
}
