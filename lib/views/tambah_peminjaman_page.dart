import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';

class TambahPeminjamanPage extends StatefulWidget {
  const TambahPeminjamanPage({super.key});

  @override
  State<TambahPeminjamanPage> createState() => _TambahPeminjamanPageState();
}

class _TambahPeminjamanPageState extends State<TambahPeminjamanPage> {
  final _namaSantriController = TextEditingController();
  final _namaBarangController = TextEditingController();
  File? _fotoEkp;

  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _fotoEkp = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Peminjaman'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _namaSantriController,
                decoration: const InputDecoration(
                  labelText: 'Nama Santri Peminjam',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _namaBarangController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang yang Dipinjam',
                ),
              ),
              const SizedBox(height: 20),
              _fotoEkp == null
                  ? const Text('Belum ada foto jaminan EKP')
                  : Image.file(_fotoEkp!, height: 150),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _ambilFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Foto EKP Jaminan'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () async {
                  if (_namaSantriController.text.isNotEmpty &&
                      _namaBarangController.text.isNotEmpty &&
                      _fotoEkp != null) {
                    final data = {
                      'id': const Uuid().v4(),
                      'nama_santri': _namaSantriController.text,
                      'nama_barang': _namaBarangController.text,
                      'tanggal_pinjam': DateTime.now().toString().split(' ')[0],
                      'jaminan_ekp': _fotoEkp!.path,
                      'status': 'Dipinjam',
                      'is_synced': 0,
                    };
                    final db = await DatabaseHelper.instance.database;
                    await db.insert('peminjaman', data);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Simpan Peminjaman',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
