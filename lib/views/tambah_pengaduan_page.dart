import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import '../models/item_inventaris.dart';

class TambahPengaduanPage extends StatefulWidget {
  const TambahPengaduanPage({super.key});

  @override
  State<TambahPengaduanPage> createState() => _TambahPengaduanPageState();
}

class _TambahPengaduanPageState extends State<TambahPengaduanPage> {
  String jenisLaporan = 'Laporan Kerusakan';
  String peranPelapor = 'Ketua Kamar';

  final namaPelaporController = TextEditingController();
  final namaBarangController = TextEditingController();
  final jumlahController = TextEditingController(text: '1');
  final deskripsiController = TextEditingController();

  List<Lokasi> daftarLokasi = [];
  Lokasi? lokasiTerpilih;
  List<ItemInventaris> daftarBarangLokasi = [];
  ItemInventaris? barangTerpilih;

  File? _fotoBukti;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _muatLokasi();
  }

  Future<void> _muatLokasi() async {
    final raw = await DatabaseHelper.instance.getAllLokasi();
    if (!mounted) return;
    setState(() {
      daftarLokasi = raw.map((e) => Lokasi.fromMap(e)).toList();
    });
  }

  Future<void> _pilihLokasi(Lokasi? lok) async {
    setState(() {
      lokasiTerpilih = lok;
      barangTerpilih = null;
      daftarBarangLokasi = [];
    });
    if (lok != null && lok.id != null) {
      final rawItems = await DatabaseHelper.instance.getItemsByLokasi(lok.id!);
      if (!mounted) return;
      setState(() {
        daftarBarangLokasi = rawItems
            .map((e) => ItemInventaris.fromMap(e))
            .toList();
      });
    }
  }

  Future<void> _ambilFoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null && mounted) {
      setState(() {
        _fotoBukti = File(picked.path);
      });
    }
  }

  String _waktuSekarang() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $jam:$menit";
  }

  Future<void> _simpanLaporan() async {
    if (namaPelaporController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama Anda terlebih dahulu.')),
      );
      return;
    }
    if (namaBarangController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama barang atau fasilitas.')),
      );
      return;
    }
    if (deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jelaskan detail kerusakan atau kebutuhan.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final namaLokasiFinal = lokasiTerpilih != null
        ? "${lokasiTerpilih!.kodeRuangan} - ${lokasiTerpilih!.namaLokasi}"
        : 'Area Umum Asrama';

    final row = {
      'id': const Uuid().v4(),
      'jenis_laporan': jenisLaporan,
      'nama_pelapor': namaPelaporController.text.trim(),
      'peran_pelapor': peranPelapor,
      'nama_lokasi': namaLokasiFinal,
      'nama_barang': namaBarangController.text.trim(),
      'jumlah': int.tryParse(jumlahController.text.trim()) ?? 1,
      'deskripsi': deskripsiController.text.trim(),
      'foto_bukti': _fotoBukti?.path ?? '',
      'tanggal_lapor': _waktuSekarang(),
      'status': 'Menunggu',
      'tanggapan_sarpras': '',
      'is_synced': 0,
    };

    await DatabaseHelper.instance.insertLaporanWarga(row);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    namaPelaporController.dispose();
    namaBarangController.dispose();
    jumlahController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKerusakan = jenisLaporan == 'Laporan Kerusakan';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Laporan / Usulan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pemilih Jenis Formulir
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Lapor Kerusakan')),
                  selected: isKerusakan,
                  selectedColor: const Color(0xFFDC2626),
                  labelStyle: TextStyle(
                    color: isKerusakan ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() => jenisLaporan = 'Laporan Kerusakan');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Usulan Barang')),
                  selected: !isKerusakan,
                  selectedColor: const Color(0xFF0F766E),
                  labelStyle: TextStyle(
                    color: !isKerusakan ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() => jenisLaporan = 'Usulan Barang');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                TextField(
                  controller: namaPelaporController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelapor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: peranPelapor,
                  decoration: const InputDecoration(
                    labelText: 'Peran / Jabatan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items:
                      ['Ketua Kamar', 'Walisantri', 'Pengurus Asrama', 'Santri']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => peranPelapor = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Lokasi>(
                  value: lokasiTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Ruangan / Area',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: daftarLokasi.map((lok) {
                    return DropdownMenuItem(
                      value: lok,
                      child: Text("${lok.kodeRuangan} - ${lok.namaLokasi}"),
                    );
                  }).toList(),
                  onChanged: _pilihLokasi,
                ),
                if (isKerusakan && daftarBarangLokasi.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ItemInventaris>(
                    value: barangTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Barang Terdaftar (Opsional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                    items: daftarBarangLokasi.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text("${item.kodeUnik} - ${item.namaBarang}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        barangTerpilih = val;
                        if (val != null) {
                          namaBarangController.text =
                              "${val.namaBarang} (${val.kodeUnik})";
                        }
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: namaBarangController,
                  decoration: InputDecoration(
                    labelText: isKerusakan
                        ? 'Nama Fasilitas / Barang Rusak'
                        : 'Nama Barang yang Dibutuhkan',
                    hintText: isKerusakan
                        ? 'Misal: Kipas Angin Dinding, Kran Wudhu'
                        : 'Misal: Rak Sepatu, Sapu Lantai, Lampu LED',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (!isKerusakan) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Unit Dibutuhkan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: deskripsiController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isKerusakan
                        ? 'Keterangan Kerusakan'
                        : 'Alasan Kebutuhan Barang',
                    hintText: isKerusakan
                        ? 'Jelaskan kondisi kerusakan secara singkat...'
                        : 'Jelaskan mengapa barang ini dibutuhkan di asrama...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Foto Bukti / Pendukung (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ambilFoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ambilFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
                if (_fotoBukti != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _fotoBukti!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _fotoBukti = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isSaving ? null : _simpanLaporan,
            icon: const Icon(Icons.send_rounded),
            label: Text(
              _isSaving ? 'Mengirim...' : 'Kirim Sekarang',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
