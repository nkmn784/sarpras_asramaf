import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import '../services/sync_service.dart';
import 'isi_ruangan_page.dart';
import 'role_selection_page.dart';

class HomePage extends StatefulWidget {
  final bool isAdminSarpras;
  const HomePage({super.key, this.isAdminSarpras = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Lokasi> daftarLokasi = [];
  Map<String, int> ringkasan = {
    'totalRuangan': 0,
    'totalUnit': 0,
    'unitRusak': 0,
    'pinjamAktif': 0,
  };
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _jalankanSync(senyap: true);
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getAllLokasi();
    final stats = await DatabaseHelper.instance.getRingkasanSarpras();
    if (!mounted) return;
    setState(() {
      daftarLokasi = data.map((e) => Lokasi.fromMap(e)).toList();
      ringkasan = stats;
    });
  }

  Future<void> _jalankanSync({bool senyap = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await SyncService.syncSemuaData();
    await _refreshData();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    if (!senyap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil disinkronkan dengan Cloud!'),
        ),
      );
    }
  }

  void _tambahLokasi() {
    final namaController = TextEditingController();
    final pjController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Ruangan / Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Ruangan / Area',
                hintText: 'Contoh: Kamar 1, Masjid, Aula, Gudang',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pjController,
              decoration: const InputDecoration(
                labelText: 'Ketua Kamar / Penanggung Jawab',
                hintText: 'Contoh: Ust. Ahmad / Santri Zaid',
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
              if (namaController.text.trim().isNotEmpty) {
                final kodeOtomatis = Lokasi.buatKodeRuangan(
                  namaController.text.trim(),
                  daftarLokasi.length + 1,
                );
                final lokasiBaru = Lokasi(
                  id: const Uuid().v4(),
                  kodeRuangan: kodeOtomatis,
                  namaLokasi: namaController.text.trim(),
                  penanggungJawab: pjController.text.trim().isEmpty
                      ? 'Belum ditentukan'
                      : pjController.text.trim(),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sarpras Asrama F',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.isAdminSarpras
                  ? 'Mode: Pengurus Sarpras'
                  : 'Mode: Walisantri / Ketua Kamar',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sinkronisasi Cloud',
            onPressed: _isSyncing ? null : () => _jalankanSync(senyap: false),
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.cloud_sync_rounded,
                    color: Color(0xFF0F766E),
                  ),
          ),
          IconButton(
            tooltip: 'Ganti Peran',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _jalankanSync(senyap: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Ruangan',
                    value: '${ringkasan['totalRuangan']}',
                    icon: Icons.meeting_room,
                  ),
                  _StatItem(
                    label: 'Total Unit',
                    value: '${ringkasan['totalUnit']}',
                    icon: Icons.inventory_2,
                  ),
                  _StatItem(
                    label: 'Perlu Servis',
                    value: '${ringkasan['unitRusak']}',
                    icon: Icons.build_circle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Ruangan & Area',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${daftarLokasi.length} Lokasi',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (daftarLokasi.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.domain_add_rounded,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isAdminSarpras
                          ? 'Belum ada data ruangan.\nTekan tombol + Tambah Ruangan atau tarik layar ke bawah untuk Sync.'
                          : 'Belum ada data ruangan.\nTekan ikon awan di kanan atas untuk memuat data terbaru.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ...daftarLokasi.map((lokasi) {
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1A0F766E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lokasi.kodeRuangan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lokasi.namaLokasi,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (widget.isAdminSarpras)
                          Icon(
                            lokasi.isSynced == 1
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: lokasi.isSynced == 1
                                ? Colors.teal
                                : Colors.grey,
                            size: 18,
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'PJ: ${lokasi.penanggungJawab ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    trailing: widget.isAdminSarpras
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final idHapus = lokasi.id!;
                                  await DatabaseHelper.instance.deleteLokasi(
                                    idHapus,
                                  );
                                  await SyncService.hapusDokumenCloud(
                                    'lokasi',
                                    idHapus,
                                  );
                                  _refreshData();
                                },
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IsiRuanganPage(
                            lokasi: lokasi,
                            isAdminSarpras: widget.isAdminSarpras,
                          ),
                        ),
                      );
                      _refreshData();
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: widget.isAdminSarpras
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              onPressed: _tambahLokasi,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Ruangan'),
            )
          : null,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
