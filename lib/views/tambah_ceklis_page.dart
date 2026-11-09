import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';

class TambahCeklisPage extends StatefulWidget {
  const TambahCeklisPage({super.key});

  @override
  State<TambahCeklisPage> createState() => _TambahCeklisPageState();
}

class _TambahCeklisPageState extends State<TambahCeklisPage> {
  final _petugasController = TextEditingController();
  final _namaFasilitasController = TextEditingController();
  String _kondisiTerpilih = 'Baik';

  final List<String> daftarKondisi = ['Baik', 'Rusak Ringan', 'Rusak Berat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Ceklis Baru'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _petugasController,
              decoration: const InputDecoration(
                labelText: 'Nama Petugas Piket',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _namaFasilitasController,
              decoration: const InputDecoration(
                labelText: 'Fasilitas yang Diperiksa (cth: Kamar Mandi A)',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _kondisiTerpilih,
              items: daftarKondisi.map((kondisi) {
                return DropdownMenuItem(value: kondisi, child: Text(kondisi));
              }).toList(),
              onChanged: (val) {
                setState(() => _kondisiTerpilih = val!);
              },
              decoration: const InputDecoration(labelText: 'Kondisi Saat Ini'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                if (_petugasController.text.isNotEmpty &&
                    _namaFasilitasController.text.isNotEmpty) {
                  final data = {
                    'id': const Uuid().v4(),
                    'tanggal': DateTime.now().toString().split(' ')[0],
                    'petugas': _petugasController.text,
                    'nama_fasilitas': _namaFasilitasController.text,
                    'kondisi': _kondisiTerpilih,
                    'is_synced': 0,
                  };
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('ceklis', data);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                'Simpan Ceklis',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
