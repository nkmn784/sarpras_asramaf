import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import 'app_drawer.dart';
import 'isi_ruangan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lokasi> daftarLokasi = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllLokasi();
    setState(() {
      daftarLokasi = data.map((e) => Lokasi.fromMap(e)).toList();
    });
  }

  void _tambahLokasi() {
    TextEditingController namaController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Ruangan/Lokasi'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(
            hintText: 'Contoh: Masjid, Kamar 1, Gudang',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.isNotEmpty) {
                final lokasiBaru = Lokasi(
                  id: const Uuid().v4(),
                  namaLokasi: namaController.text,
                );
                await DatabaseHelper.instance.insertLokasi(lokasiBaru.toMap());
                if (context.mounted) Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Inventaris Asrama'),
        backgroundColor: Colors.green,
      ),
      drawer: AppDrawer(onSyncComplete: _refreshData),
      body: daftarLokasi.isEmpty
          ? const Center(
              child: Text('Belum ada lokasi. Tekan + untuk menambah ruangan.'),
            )
          : ListView.builder(
              itemCount: daftarLokasi.length,
              itemBuilder: (context, index) {
                final lokasi = daftarLokasi[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.meeting_room,
                      color: Colors.green,
                      size: 40,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lokasi.namaLokasi,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Icon(
                          lokasi.isSynced == 1
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: lokasi.isSynced == 1
                              ? Colors.green
                              : Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteLokasi(
                              lokasi.id!,
                            );
                            _refreshData();
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IsiRuanganPage(lokasi: lokasi),
                        ),
                      );
                      _refreshData();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _tambahLokasi,
        child: const Icon(Icons.add),
      ),
    );
  }
}
