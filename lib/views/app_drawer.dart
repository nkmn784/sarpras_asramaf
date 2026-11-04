import 'package:flutter/material.dart';

import 'home_page.dart';
import 'peminjaman_page.dart';
import 'pengaduan_page.dart';
import 'ceklis_page.dart';
import '../services/sync_service.dart';

class AppDrawer extends StatelessWidget {
  // Menambahkan fungsi callback (penyambung) untuk me-refresh halaman utama
  final VoidCallback? onSyncComplete;

  const AppDrawer({super.key, this.onSyncComplete});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              'Biro Sarpras\nAsrama F',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.green),
            title: const Text('Inventaris Asrama'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: const Text('Buku Peminjaman'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PeminjamanPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.orange),
            title: const Text('Pengaduan Kerusakan'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PengaduanPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist, color: Colors.purple),
            title: const Text('Ceklis Patroli Harian'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CeklisPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.blueGrey),
            title: const Text('Sinkronisasi ke Cloud'),
            onTap: () async {
              // 1. Tutup Drawer-nya agar layar tidak tertutup menu
              Navigator.pop(context);

              // 2. Tampilkan notifikasi loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menyinkronkan data... mohon tunggu.'),
                ),
              );

              // 3. Jalankan mesin sinkronisasi
              await SyncService.syncSemuaData();

              // 4. Setelah selesai, tampilkan notifikasi berhasil
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sinkronisasi selesai!'),
                    backgroundColor: Colors.green,
                  ),
                );

                // 5. Memicu halaman tempat Anda berada untuk REFRESH
                if (onSyncComplete != null) {
                  onSyncComplete!();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
