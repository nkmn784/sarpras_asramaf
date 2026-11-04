import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/ceklis.dart';
import 'app_drawer.dart';
import 'tambah_ceklis_page.dart';

class CeklisPage extends StatefulWidget {
  const CeklisPage({super.key});

  @override
  State<CeklisPage> createState() => _CeklisPageState();
}

class _CeklisPageState extends State<CeklisPage> {
  List<Ceklis> daftarCeklis = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllCeklis();
    setState(() => daftarCeklis = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patroli Ceklis Harian'),
        backgroundColor: Colors.purple,
      ),
      drawer: const AppDrawer(),
      body: daftarCeklis.isEmpty
          ? const Center(child: Text('Belum ada data patroli hari ini.'))
          : ListView.builder(
              itemCount: daftarCeklis.length,
              itemBuilder: (context, index) {
                final c = daftarCeklis[index];
                final isBerfungsi =
                    c.kondisi == 1; // 1 = Berfungsi, 0 = Bermasalah

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isBerfungsi ? Icons.check_circle : Icons.cancel,
                      color: isBerfungsi ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    title: Text(
                      c.namaFasilitas,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Petugas: ${c.petugas} | Tgl: ${c.tanggal}'),
                    trailing: Text(
                      isBerfungsi ? "Berfungsi" : "Bermasalah",
                      style: TextStyle(
                        color: isBerfungsi ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahCeklisPage()),
          );
          _refreshData();
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
