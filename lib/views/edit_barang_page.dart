import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/barang.dart';

class EditBarangPage extends StatefulWidget {
  final Barang barang; // Menerima data barang yang akan diedit

  const EditBarangPage({super.key, required this.barang});

  @override
  State<EditBarangPage> createState() => _EditBarangPageState();
}

class _EditBarangPageState extends State<EditBarangPage> {
  late TextEditingController _namaController;
  late TextEditingController _jumlahController;
  late TextEditingController _baikController;
  late TextEditingController _rusakController;

  @override
  void initState() {
    super.initState();
    // Mengisi kolom otomatis dengan data barang yang sudah ada
    _namaController = TextEditingController(text: widget.barang.namaBarang);
    _jumlahController = TextEditingController(
      text: widget.barang.jumlah.toString(),
    );
    _baikController = TextEditingController(
      text: widget.barang.kondisiBaik.toString(),
    );
    _rusakController = TextEditingController(
      text: widget.barang.kondisiTidak.toString(),
    );
  }

  Future<void> _updateKeLokal() async {
    final barangDiedit = Barang(
      id: widget.barang.id, // ID tetap sama agar menimpa data yang lama
      namaBarang: _namaController.text,
      jumlah: int.tryParse(_jumlahController.text) ?? 0,
      kondisiBaik: int.tryParse(_baikController.text) ?? 0,
      kondisiTidak: int.tryParse(_rusakController.text) ?? 0,
      isSynced: 0, // Ubah ke 0 lagi agar sistem tahu ada update lokal yang perlu dikirim ke cloud nanti
    );

    await DatabaseHelper.instance.updateBarang(barangDiedit);

    if (mounted) {
      Navigator.pop(context); // Kembali ke halaman utama setelah edit selesai
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inventaris'),
        backgroundColor:
            Colors.orange, // Beda warna untuk membedakan dengan halaman tambah
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Barang'),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _updateKeLokal,
              child: const Text('Perbarui Barang'),
            ),
          ],
        ),
      ),
    );
  }
}
