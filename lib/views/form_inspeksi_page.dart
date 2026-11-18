import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import '../models/item_inventaris.dart';

class FormInspeksiPage extends StatefulWidget {
  const FormInspeksiPage({super.key});

  @override
  State<FormInspeksiPage> createState() => _FormInspeksiPageState();
}

class _FormInspeksiPageState extends State<FormInspeksiPage> {
  List<Lokasi> daftarLokasi = [];
  Lokasi? lokasiTerpilih;
  List<ItemInventaris> daftarBarangRuangan = [];

  final petugasController = TextEditingController();
  final catatanRuanganController = TextEditingController();
  String kondisiRuangan = 'Bersih & Baik';

  final Map<String, String> hasilKondisiItem = {};
  final Map<String, TextEditingController> catatanItemControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _muatDaftarLokasi();
  }

  Future<void> _muatDaftarLokasi() async {
    final raw = await DatabaseHelper.instance.getAllLokasi();
    if (!mounted) return;
    setState(() {
      daftarLokasi = raw.map((e) => Lokasi.fromMap(e)).toList();
    });
  }

  Future<void> _pilihLokasi(Lokasi lokasi) async {
    final rawItems = await DatabaseHelper.instance.getItemsByLokasi(lokasi.id!);
    if (!mounted) return;

    for (var c in catatanItemControllers.values) {
      c.dispose();
    }
    hasilKondisiItem.clear();
    catatanItemControllers.clear();

    final items = rawItems.map((e) => ItemInventaris.fromMap(e)).toList();
    for (var item in items) {
      hasilKondisiItem[item.id!] = item.kondisi;
      catatanItemControllers[item.id!] = TextEditingController();
    }

    setState(() {
      lokasiTerpilih = lokasi;
      daftarBarangRuangan = items;
    });
  }

  String _tanggalHariIni() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  Future<void> _simpanInspeksi() async {
    if (lokasiTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih ruangan yang akan diperiksa.')),
      );
      return;
    }
    if (petugasController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama petugas inspeksi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final idInspeksi = const Uuid().v4();
    final header = {
      'id': idInspeksi,
      'id_lokasi': lokasiTerpilih!.id!,
      'nama_lokasi':
          "${lokasiTerpilih!.kodeRuangan} - ${lokasiTerpilih!.namaLokasi}",
      'tanggal': _tanggalHariIni(),
      'petugas': petugasController.text.trim(),
      'kondisi_ruangan': kondisiRuangan,
      'catatan': catatanRuanganController.text.trim(),
      'is_synced': 0,
    };

    final List<BarisData> detailList = daftarBarangRuangan.map((item) {
      return {
        'id': const Uuid().v4(),
        'id_inspeksi': idInspeksi,
        'id_item': item.id!,
        'kode_unik': item.kodeUnik,
        'nama_barang': item.namaBarang,
        'kondisi_hasil': hasilKondisiItem[item.id!] ?? item.kondisi,
        'catatan': catatanItemControllers[item.id!]?.text.trim() ?? '',
      };
    }).toList();

    await DatabaseHelper.instance.simpanInspeksiLengkap(
      headerInspeksi: header,
      daftarDetail: detailList,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    petugasController.dispose();
    catatanRuanganController.dispose();
    for (var c in catatanItemControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mulai Inspeksi Ruangan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Data Umum Ruangan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Lokasi>(
                  value: lokasiTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Ruangan / Area',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: daftarLokasi.map((lok) {
                    return DropdownMenuItem(
                      value: lok,
                      child: Text("${lok.kodeRuangan} - ${lok.namaLokasi}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _pilihLokasi(val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: petugasController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Petugas Piket / Sarpras',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kondisiRuangan,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Fisik & Kebersihan Ruangan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  items:
                      [
                            'Bersih & Baik',
                            'Kurang Rapi / Kotor',
                            'Perlu Perbaikan Fisik',
                          ]
                          .map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => kondisiRuangan = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanRuanganController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Umum Ruangan (Opsional)',
                    hintText: 'Misal: Lampu teras redup, kunci pintu seret',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (lokasiTerpilih != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Pengecekan Barang di Ruangan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "${daftarBarangRuangan.length} Item",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (daftarBarangRuangan.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Belum ada barang terdaftar di ruangan ini. Anda tetap bisa menyimpan hasil pengecekan fisik ruangan.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              )
            else
              ...daftarBarangRuangan.map((item) {
                final statusDipilih = hasilKondisiItem[item.id!] ?? 'Baik';
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                                color: const Color(0x1A0F766E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.kodeUnik,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${item.namaBarang} (${item.jumlah} unit)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['Baik', 'Rusak Ringan', 'Rusak Berat'].map(
                            (opsi) {
                              final terpilih = statusDipilih == opsi;
                              Color warnaAktif = const Color(0xFF0F766E);
                              if (opsi == 'Rusak Ringan') {
                                warnaAktif = const Color(0xFFD97706);
                              } else if (opsi == 'Rusak Berat') {
                                warnaAktif = const Color(0xFFDC2626);
                              }
                              return ChoiceChip(
                                label: Text(opsi),
                                selected: terpilih,
                                selectedColor: warnaAktif,
                                labelStyle: TextStyle(
                                  color: terpilih
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    hasilKondisiItem[item.id!] = opsi;
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),
                        if (statusDipilih != 'Baik') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: catatanItemControllers[item.id!],
                            decoration: const InputDecoration(
                              hintText: 'Keterangan kerusakan barang ini...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isSaving ? null : _simpanInspeksi,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Hasil Inspeksi',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
