import 'package:flutter/material.dart';

import 'home_page.dart';
import 'ceklis_page.dart';
import 'peminjaman_page.dart';
import 'pengaduan_page.dart';

class MainNavigationPage extends StatefulWidget {
  final bool isAdminSarpras;
  const MainNavigationPage({super.key, required this.isAdminSarpras});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = widget.isAdminSarpras
        ? const [
            HomePage(isAdminSarpras: true),
            CeklisPage(),
            PeminjamanPage(),
            PengaduanPage(),
          ]
        : const [HomePage(isAdminSarpras: false), PengaduanPage()];

    final List<NavigationDestination> destinations = widget.isAdminSarpras
        ? const [
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room_rounded),
              label: 'Ruangan',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Inspeksi',
            ),
            NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake_rounded),
              label: 'Pinjam Alat',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Laporan',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment_rounded),
              label: 'Fasilitas Asrama',
            ),
            NavigationDestination(
              icon: Icon(Icons.report_problem_outlined),
              selectedIcon: Icon(Icons.report_problem_rounded),
              label: 'Lapor & Usul',
            ),
          ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: const Color(0x260F766E),
        destinations: destinations,
      ),
    );
  }
}
