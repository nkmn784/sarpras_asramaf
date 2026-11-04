import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/pengaduan.dart';
import 'app_drawer.dart';
import 'tambah_pengaduan_page.dart';

class PengaduanPage extends StatefulWidget {
  const PengaduanPage({super.key});

  @override
  State<PengaduanPage> createState() => _PengaduanPageState();
}

class _PengaduanPageState extends State<PengaduanPage> {
  List<Pengaduan> daftarPengaduan = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllPengaduan();
    setState(() => daftarPengaduan = data);
  }

  // Fungsi untuk mengubah status lewat Pop-up
  Future<void> _ubahStatus(Pengaduan p) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Penanganan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Dikerjakan Biro Asrama'),
              onTap: () async {
                await DatabaseHelper.instance.updateStatusPengaduan(
                  p.id!,
                  'Dikerjakan Biro',
                );
                Navigator.pop(context);
                _refreshData();
              },
            ),
            ListTile(
              title: const Text('Diserahkan ke Pusat'),
              onTap: () async {
                await DatabaseHelper.instance.updateStatusPengaduan(
                  p.id!,
                  'Diserahkan Pusat',
                );
                Navigator.pop(context);
                _refreshData();
              },
            ),
            ListTile(
              title: const Text('Selesai Diperbaiki'),
              onTap: () async {
                await DatabaseHelper.instance.updateStatusPengaduan(
                  p.id!,
                  'Selesai',
                );
                Navigator.pop(context);
                _refreshData();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pengaduan'),
        backgroundColor: Colors.orange,
      ),
      drawer: const AppDrawer(),
      body: daftarPengaduan.isEmpty
          ? const Center(child: Text('Belum ada laporan kerusakan.'))
          : ListView.builder(
              itemCount: daftarPengaduan.length,
              itemBuilder: (context, index) {
                final p = daftarPengaduan[index];
                // Menentukan warna badge berdasarkan status
                Color statusColor = Colors.grey;
                if (p.status == 'Dikerjakan Biro') statusColor = Colors.blue;
                if (p.status == 'Diserahkan Pusat') statusColor = Colors.red;
                if (p.status == 'Selesai') statusColor = Colors.green;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      p.fasilitasRusak,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pelapor: ${p.namaPelapor}\nTgl: ${p.tanggalLapor}',
                    ),
                    trailing: InkWell(
                      onTap: () => _ubahStatus(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TambahPengaduanPage(),
            ),
          );
          _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
