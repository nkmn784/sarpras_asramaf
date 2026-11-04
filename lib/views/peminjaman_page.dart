import 'dart:io';

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
      drawer: AppDrawer(
        onSyncComplete: () {
          _refreshData(); // Me-refresh layar otomatis saat sinkronisasi selesai
        },
      ),
      body: daftarPinjam.isEmpty
          ? const Center(child: Text('Belum ada data peminjaman alat.'))
          : ListView.builder(
              itemCount: daftarPinjam.length,
              itemBuilder: (context, index) {
                final p = daftarPinjam[index];
                final isDikembalikan = p.status == 'Dikembalikan';

                // LOGIKA BARU: Cek apakah foto ini URL online atau File lokal
                bool isOnlineUrl = p.jaminanEkp.startsWith('http');
                bool isLocalFile = p.jaminanEkp.contains('/') && !isOnlineUrl;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    // === BAGIAN FOTO (Pintar membaca status online/offline) ===
                    leading: (isOnlineUrl || isLocalFile)
                        ? GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  // Menampilkan wujud asli di pop-up
                                  child: isOnlineUrl
                                      ? Image.network(p.jaminanEkp)
                                      : Image.file(File(p.jaminanEkp)),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              // Menampilkan thumbnail
                              child: isOnlineUrl
                                  ? Image.network(
                                      p.jaminanEkp,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(p.jaminanEkp),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          )
                        : const Icon(Icons.credit_card, size: 40),

                    // === BAGIAN JUDUL & IKON AWAN ===
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${p.namaSantri} - ${p.namaBarang}',
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
