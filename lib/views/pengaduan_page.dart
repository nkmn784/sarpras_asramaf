import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'tambah_pengaduan_page.dart';

class PengaduanPage extends StatefulWidget {
  final bool isAdminSarpras;
  const PengaduanPage({super.key, this.isAdminSarpras = true});

  @override
  State<PengaduanPage> createState() => _PengaduanPageState();
}

class _PengaduanPageState extends State<PengaduanPage> {
  List<BarisData> daftarLaporan = [];
  String _filterJenis = 'Semua';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllLaporanWarga();
    if (!mounted) return;
    setState(() {
      daftarLaporan = data;
    });
  }

  void _tindakLanjutDialog(BarisData item) {
    String statusDipilih = item['status'] ?? 'Menunggu';
    final tanggapanController = TextEditingController(
      text: (item['tanggapan_sarpras'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Tindak Lanjut Sarpras'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: statusDipilih,
                decoration: const InputDecoration(
                  labelText: 'Status Penanganan',
                  border: OutlineInputBorder(),
                ),
                items: ['Menunggu', 'Diproses', 'Selesai', 'Ditolak']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => statusDipilih = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tanggapanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Tanggapan ke Pelapor',
                  hintText: 'Misal: Teknisi dijadwalkan besok pagi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
              ),
              onPressed: () async {
                await DatabaseHelper.instance.updateTindakLanjutLaporan(
                  item['id'] as String,
                  statusDipilih,
                  tanggapanController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
                _refreshData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _lihatFoto(String pathFoto) {
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
                  : Image.file(File(pathFoto), fit: BoxFit.contain),
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

  Color _warnaStatus(String status) {
    if (status == 'Selesai') return const Color(0xFF0F766E);
    if (status == 'Diproses') return const Color(0xFF2563EB);
    if (status == 'Ditolak') return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  Color _bgStatus(String status) {
    if (status == 'Selesai') return const Color(0x1F0F766E);
    if (status == 'Diproses') return const Color(0x1F2563EB);
    if (status == 'Ditolak') return const Color(0x1FDC2626);
    return const Color(0x1FD97706);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = daftarLaporan.where((item) {
      if (_filterJenis == 'Semua') return true;
      return item['jenis_laporan'] == _filterJenis;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdminSarpras
                  ? 'Laporan & Usulan Warga'
                  : 'Lapor Kerusakan & Usul',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Aduan fasilitas & kebutuhan barang asrama',
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
              children: ['Semua', 'Laporan Kerusakan', 'Usulan Barang'].map((
                kategori,
              ) {
                final aktif = _filterJenis == kategori;
                final labelPendek = kategori == 'Laporan Kerusakan'
                    ? 'Kerusakan'
                    : (kategori == 'Usulan Barang' ? 'Usulan' : 'Semua');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labelPendek),
                    selected: aktif,
                    selectedColor: const Color(0x260F766E),
                    onSelected: (_) => setState(() => _filterJenis = kategori),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada laporan atau usulan.\nTekan tombol + Buat Laporan di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final jenis =
                          item['jenis_laporan'] ?? 'Laporan Kerusakan';
                      final isUsulan = jenis == 'Usulan Barang';
                      final status = item['status'] ?? 'Menunggu';
                      final foto = (item['foto_bukti'] ?? '').toString();
                      final tanggapan = (item['tanggapan_sarpras'] ?? '')
                          .toString();

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
                                      color: isUsulan
                                          ? const Color(0x1F2563EB)
                                          : const Color(0x1FDC2626),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isUsulan ? 'Usulan Barang' : 'Kerusakan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUsulan
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _bgStatus(status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _warnaStatus(status),
                                      ),
                                    ),
                                  ),
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
                                isUsulan
                                    ? "${item['nama_barang']} (${item['jumlah']} unit)"
                                    : "${item['nama_barang']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Lokasi: ${item['nama_lokasi']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['deskripsi'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Oleh: ${item['nama_pelapor']} (${item['peran_pelapor']}) • ${item['tanggal_lapor']}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (tanggapan.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Respon Sarpras: $tanggapan",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                              if (foto.isNotEmpty || widget.isAdminSarpras) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (foto.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () => _lihatFoto(foto),
                                        icon: const Icon(
                                          Icons.image_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Foto Bukti'),
                                      ),
                                    const Spacer(),
                                    if (widget.isAdminSarpras)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0F766E,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _tindakLanjutDialog(item),
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Tindak Lanjuti'),
                                      ),
                                  ],
                                ),
                              ],
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
            MaterialPageRoute(builder: (_) => const TambahPengaduanPage()),
          );
          if (hasil == true) _refreshData();
        },
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Buat Laporan / Usul'),
      ),
    );
  }
}
