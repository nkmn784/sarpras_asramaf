import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/barang.dart';
import 'tambah_barang_page.dart';
import 'edit_barang_page.dart';
import 'app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Barang> daftarBarang = [];

  @override
  void initState() {
    super.initState();
    _refreshData(); // Memanggil data dari SQLite saat aplikasi dibuka
  }

  // Fungsi untuk menarik data dari database lokal
  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllBarang();
    setState(() {
      daftarBarang = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris Asrama F'),
        backgroundColor: Colors.green,
      ),
      drawer: const AppDrawer(),
      body: daftarBarang.isEmpty
          ? const Center(child: Text('Belum ada data barang. Silakan tambah.'))
          : ListView.builder(
              itemCount: daftarBarang.length,
              itemBuilder: (context, index) {
                final barang = daftarBarang[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      barang.namaBarang,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total: ${barang.jumlah} | Baik: ${barang.kondisiBaik} | Rusak: ${barang.kondisiTidak}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon Status Sinkronisasi
                        Icon(
                          barang.isSynced == 1
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: barang.isSynced == 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                        // Tombol Edit
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditBarangPage(barang: barang),
                              ),
                            );
                            _refreshData(); // Refresh data setelah diedit
                          },
                        ),
                        // Tombol Hapus
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Konfirmasi dialog sebelum menghapus
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Barang?'),
                                content: Text(
                                  'Yakin ingin menghapus ${barang.namaBarang}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await DatabaseHelper.instance
                                          .deleteBarang(barang.id!);
                                      Navigator.pop(context);
                                      _refreshData(); // Refresh layar setelah dihapus
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          // Pindah ke halaman tambah barang
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahBarangPage()),
          );
          _refreshData(); // Refresh daftar setelah selesai menambah barang
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
