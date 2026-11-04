import 'dart:io'; // Tambahan wajib untuk membaca file foto dari memori HP

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/peminjaman.dart';
import 'app_drawer.dart';
import 'tambah_peminjaman_page.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  List<Peminjaman> daftarPinjam = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllPeminjaman();
    setState(() => daftarPinjam = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Peminjaman'),
        backgroundColor: Colors.blue,
      ),
      drawer: const AppDrawer(),
      body: daftarPinjam.isEmpty
          ? const Center(child: Text('Belum ada data peminjaman alat.'))
          : ListView.builder(
              itemCount: daftarPinjam.length,
              itemBuilder: (context, index) {
                final p = daftarPinjam[index];
                final isDikembalikan = p.status == 'Dikembalikan';

                // Mengecek apakah datanya berupa path lokasi foto (mengandung tanda miring '/')
                bool isFoto = p.jaminanEkp.contains('/');

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    // === BAGIAN FOTO KECIL (THUMBNAIL) ===
                    leading: isFoto
                        ? GestureDetector(
                            onTap: () {
                              // Memunculkan Pop-up foto ukuran besar saat thumbnail diklik
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: Image.file(
                                    File(p.jaminanEkp),
                                  ), // Memanggil wujud asli foto
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.file(
                                File(p.jaminanEkp),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.credit_card,
                            size: 40,
                          ), // Jika data lama masih teks

                    title: Text(
                      '${p.namaSantri} - ${p.namaBarang}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Tgl: ${p.tanggalPinjam}'),

                    trailing: isDikembalikan
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () async {
                              await DatabaseHelper.instance
                                  .updateStatusPeminjaman(
                                    p.id!,
                                    'Dikembalikan',
                                  );
                              _refreshData();
                            },
                            child: const Text('Kembalikan'),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TambahPeminjamanPage(),
            ),
          );
          _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
