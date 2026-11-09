import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';

class TambahPengaduanPage extends StatefulWidget {
  const TambahPengaduanPage({super.key});

  @override
  State<TambahPengaduanPage> createState() => _TambahPengaduanPageState();
}

class _TambahPengaduanPageState extends State<TambahPengaduanPage> {
  final _namaPelaporController = TextEditingController();
  final _fasilitasRusakController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Kerusakan'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaPelaporController,
              decoration: const InputDecoration(labelText: 'Nama Pelapor'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fasilitasRusakController,
              decoration: const InputDecoration(
                labelText: 'Fasilitas yang Rusak (Deskripsikan)',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                if (_namaPelaporController.text.isNotEmpty &&
                    _fasilitasRusakController.text.isNotEmpty) {
                  final data = {
                    'id': const Uuid().v4(),
                    'nama_pelapor': _namaPelaporController.text,
                    'fasilitas_rusak': _fasilitasRusakController.text,
                    'tanggal_lapor': DateTime.now().toString().split(' ')[0],
                    'status': 'Dilaporkan',
                    'is_synced': 0,
                  };
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('pengaduan', data);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                'Kirim Laporan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
