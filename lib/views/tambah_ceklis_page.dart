import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/ceklis.dart';

class TambahCeklisPage extends StatefulWidget {
  const TambahCeklisPage({super.key});

  @override
  State<TambahCeklisPage> createState() => _TambahCeklisPageState();
}

class _TambahCeklisPageState extends State<TambahCeklisPage> {
  final _fasilitasController = TextEditingController();
  final _petugasController = TextEditingController();
  bool _isBerfungsi = true; // Default nilai: true (berfungsi/ceklis)

  Future<void> _simpanCeklis() async {
    const uuid = Uuid();
    final ceklisBaru = Ceklis(
      id: uuid.v4(),
      tanggal: DateTime.now().toString().substring(0, 10),
      petugas: _petugasController.text,
      namaFasilitas: _fasilitasController.text,
      kondisi: _isBerfungsi
          ? 1
          : 0, // Mengubah boolean menjadi integer 1 atau 0
      isSynced: 0,
    );

    await DatabaseHelper.instance.insertCeklis(ceklisBaru);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Pengecekan'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _petugasController,
              decoration: const InputDecoration(
                labelText: 'Nama Petugas Piket',
              ),
            ),
            TextField(
              controller: _fasilitasController,
              decoration: const InputDecoration(
                labelText: 'Fasilitas (Misal: Lampu Kamar Mandi)',
              ),
            ),
            const SizedBox(height: 20),
            // Tombol interaktif untuk memilih Ceklis (Berfungsi) atau Silang (Bermasalah)
            SwitchListTile(
              title: Text(
                _isBerfungsi
                    ? 'Status: BERFUNGSI (Ceklis)'
                    : 'Status: BERMASALAH (Silang)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isBerfungsi ? Colors.green : Colors.red,
                ),
              ),
              value: _isBerfungsi,
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.shade200,
              onChanged: (bool value) {
                setState(() {
                  _isBerfungsi = value;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: _simpanCeklis,
              child: const Text('Simpan Ceklis'),
            ),
          ],
        ),
      ),
    );
  }
}
