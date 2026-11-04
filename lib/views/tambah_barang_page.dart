import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/barang.dart';

class TambahBarangPage extends StatefulWidget {
  const TambahBarangPage({super.key});

  @override
  State<TambahBarangPage> createState() => _TambahBarangPageState();
}

class _TambahBarangPageState extends State<TambahBarangPage> {
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _baikController = TextEditingController();
  final _rusakController = TextEditingController();

  Future<void> _simpanKeLokal() async {
    // 1. Membuat ID Acak yang aman untuk sinkronisasi
    const uuid = Uuid();
    String idBaru = uuid.v4();

    // 2. Membungkus inputan ke dalam cetakan Barang
    final barangBaru = Barang(
      id: idBaru,
      namaBarang: _namaController.text,
      jumlah: int.tryParse(_jumlahController.text) ?? 0,
      kondisiBaik: int.tryParse(_baikController.text) ?? 0,
      kondisiTidak: int.tryParse(_rusakController.text) ?? 0,
      isSynced: 0, // Status 0 = Data masih di HP, belum naik ke Cloud
    );

    // 3. Menyimpan ke database SQLite
    await DatabaseHelper.instance.insertBarang(barangBaru);

    // 4. Kembali ke halaman utama
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Inventaris'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang (Contoh: Gergaji Kayu)',
              ),
            ),
            TextField(
              controller: _jumlahController,
              decoration: const InputDecoration(labelText: 'Jumlah Total'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _baikController,
              decoration: const InputDecoration(labelText: 'Kondisi Baik'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _rusakController,
              decoration: const InputDecoration(labelText: 'Kondisi Rusak'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _simpanKeLokal,
              child: const Text('Simpan Barang'),
            ),
          ],
        ),
      ),
    );
  }
}
