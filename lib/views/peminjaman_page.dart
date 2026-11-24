import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import 'tambah_peminjaman_page.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  List<BarisData> daftarPinjam = [];
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllPeminjaman();
    if (!mounted) return;
    setState(() {
      daftarPinjam = data;
    });
  }

  Map<String, dynamic> _infoTenggat(BarisData item) {
    final status = item['status'] ?? 'Dipinjam';
    if (status == 'Dikembalikan') {
      return {
        'label': 'Sudah Kembali',
        'color': const Color(0xFF0F766E),
        'bg': const Color(0x1F0F766E),
      };
    }

    final batasStr = (item['batas_kembali'] ?? '').toString();
    final batasDt = DateTime.tryParse(batasStr.replaceAll(' ', 'T'));
    if (batasDt != null) {
      final selisih = batasDt.difference(DateTime.now());
      if (selisih.isNegative) {
        return {
          'label': 'Terlambat Kembali',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0x1FDC2626),
        };
      }
      if (selisih.inHours <= 24) {
        return {
          'label': 'Jatuh Tempo Segera',
          'color': const Color(0xFFD97706),
          'bg': const Color(0x1FD97706),
        };
      }
    }

    return {
      'label': 'Sedang Dipinjam',
      'color': const Color(0xFF2563EB),
      'bg': const Color(0x1F2563EB),
    };
  }

  void _lihatJaminan(String pathFoto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: pathFoto.startsWith('http')
                  ? Image.network(pathFoto, fit: BoxFit.contain)
                  : FutureBuilder<Uint8List>(
                      future: XFile(pathFoto).readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                          );
                        }
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = daftarPinjam.where((item) {
      if (_filterStatus == 'Semua') return true;
      return item['status'] == _filterStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peminjaman Alat Santri',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Pantau barang keluar & jadwal pengembalian',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: ['Semua', 'Dipinjam', 'Dikembalikan'].map((st) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(st),
                    selected: _filterStatus == st,
                    selectedColor: const Color(0x260F766E),
                    onSelected: (_) => setState(() => _filterStatus = st),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data peminjaman.\nTekan tombol + Catat Pinjam di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final info = _infoTenggat(item);
                      final kodeUnik = (item['kode_unik'] ?? '').toString();
                      final jaminan = (item['jaminan_ekp'] ?? '').toString();
                      final punyaFoto =
                          jaminan.contains('/') || jaminan.startsWith('http');
                      final masihDipinjam = item['status'] == 'Dipinjam';

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: info['bg'] as Color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      info['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: info['color'] as Color,
                                      ),
                                    ),
                                  ),
                                  if (kodeUnik.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A0F766E),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        kodeUnik,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Icon(
                                    item['is_synced'] == 1
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    size: 18,
                                    color: item['is_synced'] == 1
                                        ? Colors.teal
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['nama_barang'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Peminjam: ${item['nama_santri']} (${item['kamar_santri'] ?? '-'})",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Pinjam: ${item['tanggal_pinjam']}\nWajib Kembali: ${item['batas_kembali'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (punyaFoto)
                                    OutlinedButton.icon(
                                      onPressed: () => _lihatJaminan(jaminan),
                                      icon: const Icon(
                                        Icons.badge_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Foto EKP'),
                                    ),
                                  const Spacer(),
                                  if (masihDipinjam)
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F766E,
                                        ),
                                      ),
                                      onPressed: () async {
                                        await DatabaseHelper.instance
                                            .updateStatusPeminjaman(
                                              item['id'] as String,
                                              'Dikembalikan',
                                            );
                                        _refreshData();
                                      },
                                      icon: const Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Kembalikan'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: () async {
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahPeminjamanPage()),
          );
          if (hasil == true) _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Pinjam'),
      ),
    );
  }
}
