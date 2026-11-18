import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'form_inspeksi_page.dart';

class InspeksiPage extends StatefulWidget {
  const InspeksiPage({super.key});

  @override
  State<InspeksiPage> createState() => _InspeksiPageState();
}

class _InspeksiPageState extends State<InspeksiPage> {
  List<BarisData> riwayatInspeksi = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllInspeksi();
    if (!mounted) return;
    setState(() {
      riwayatInspeksi = data;
    });
  }

  Future<void> _lihatDetailInspeksi(BarisData inspeksi) async {
    final detailList = await DatabaseHelper.instance.getDetailInspeksi(
      inspeksi['id'] as String,
    );
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inspeksi['nama_lokasi'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Tanggal: ${inspeksi['tanggal']} • Petugas: ${inspeksi['petugas']}",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              "Kondisi Ruangan: ${inspeksi['kondisi_ruangan']}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if ((inspeksi['catatan'] ?? '').toString().isNotEmpty)
              Text(
                "Catatan: ${inspeksi['catatan']}",
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            const Divider(height: 24),
            const Text(
              'Hasil Pengecekan Barang:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (detailList.isEmpty)
              const Text(
                'Tidak ada item barang saat inspeksi dilakukan.',
                style: TextStyle(color: Color(0xFF64748B)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: detailList.length,
                  itemBuilder: (context, idx) {
                    final d = detailList[idx];
                    final kondisi = d['kondisi_hasil'] ?? 'Baik';
                    final isRusak = kondisi != 'Baik';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${d['kode_unik']} - ${d['nama_barang']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: (d['catatan'] ?? '').toString().isNotEmpty
                          ? Text(d['catatan'])
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isRusak
                              ? const Color(0x1FDC2626)
                              : const Color(0x1F0F766E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kondisi,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRusak
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inspeksi Rutin Ruangan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Pemeriksaan berkala kamar, masjid & fasilitas',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: riwayatInspeksi.isEmpty
          ? const Center(
              child: Text(
                'Belum ada riwayat inspeksi.\nTekan tombol + Mulai Inspeksi di bawah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: riwayatInspeksi.length,
              itemBuilder: (context, index) {
                final item = riwayatInspeksi[index];
                final kondisi = item['kondisi_ruangan'] ?? 'Bersih & Baik';
                final isBaik = kondisi == 'Bersih & Baik';

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isBaik
                          ? const Color(0x1A0F766E)
                          : const Color(0x1AD97706),
                      child: Icon(
                        isBaik ? Icons.verified_rounded : Icons.warning_rounded,
                        color: isBaik
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['nama_lokasi'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Tgl: ${item['tanggal']} • Petugas: ${item['petugas']}\nStatus: $kondisi",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onTap: () => _lihatDetailInspeksi(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: () async {
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormInspeksiPage()),
          );
          if (hasil == true) _refreshData();
        },
        icon: const Icon(Icons.fact_check_rounded),
        label: const Text('Mulai Inspeksi'),
      ),
    );
  }
}
