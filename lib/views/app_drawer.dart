import 'package:flutter/material.dart';

import 'home_page.dart';
import 'peminjaman_page.dart';
import 'pengaduan_page.dart';
import 'ceklis_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
        ],
      ),
    );
  }
}
