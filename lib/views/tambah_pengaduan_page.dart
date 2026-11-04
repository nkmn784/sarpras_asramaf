import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/pengaduan.dart';

class TambahPengaduanPage extends StatefulWidget {
  const TambahPengaduanPage({super.key});

  @override
  State<TambahPengaduanPage> createState() => _TambahPengaduanPageState();
}

class _TambahPengaduanPageState extends State<TambahPengaduanPage> {
  final _pelaporController = TextEditingController();
  final _fasilitasController = TextEditingController();

  Future<void> _simpanPengaduan() async {
    const uuid = Uuid();
    final pengaduanBaru = Pengaduan(
      id: uuid.v4(),
      namaPelapor: _pelaporController.text,
      fasilitasRusak: _fasilitasController.text,
      tanggalLapor: DateTime.now().toString().substring(0, 10),
      isSynced: 0,
    );

    await DatabaseHelper.instance.insertPengaduan(pengaduanBaru);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Kerusakan'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _pelaporController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelapor (Santri/Wali)',
              ),
            ),
            TextField(
              controller: _fasilitasController,
              decoration: const InputDecoration(
                labelText:
                    'Deskripsi Kerusakan (Misal: Keran air asrama F bocor)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _simpanPengaduan,
              child: const Text('Simpan Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}
