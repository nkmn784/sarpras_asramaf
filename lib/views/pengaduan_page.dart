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
    setState(() {
      daftarPengaduan = data.map((e) => Pengaduan.fromMap(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan Kerusakan'),
        backgroundColor: Colors.orange,
      ),
      drawer: AppDrawer(onSyncComplete: _refreshData),
      body: daftarPengaduan.isEmpty
          ? const Center(child: Text('Belum ada laporan kerusakan.'))
          : ListView.builder(
              itemCount: daftarPengaduan.length,
              itemBuilder: (context, index) {
                final p = daftarPengaduan[index];
                final isSelesai = p.status == 'Selesai';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 40,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.fasilitasRusak,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(
                          p.isSynced == 1 ? Icons.cloud_done : Icons.cloud_off,
                          color: p.isSynced == 1 ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Tgl: ${p.tanggalLapor}\nPelapor: ${p.namaPelapor}',
                    ),
                    trailing: isSelesai
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () async {
                              await DatabaseHelper.instance
                                  .updateStatusPengaduan(p.id!, 'Selesai');
                              _refreshData();
                            },
                            child: const Text('Tandai Selesai'),
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
