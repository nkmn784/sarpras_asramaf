import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/item_inventaris.dart';
import '../services/cloudinary_service.dart';

class TambahPeminjamanPage extends StatefulWidget {
  const TambahPeminjamanPage({super.key});

  @override
  State<TambahPeminjamanPage> createState() => _TambahPeminjamanPageState();
}

class _TambahPeminjamanPageState extends State<TambahPeminjamanPage> {
  final namaSantriController = TextEditingController();
  final kamarSantriController = TextEditingController();
  final barangManualController = TextEditingController();

  List<ItemInventaris> daftarInventaris = [];
  ItemInventaris? itemTerpilih;
  bool _inputManual = false;

  late DateTime _batasKembali;
  XFile? _fotoJaminan;
  Uint8List? _fotoBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _batasKembali = DateTime.now().add(const Duration(days: 1));
    _muatDaftarBarang();
  }

  Future<void> _muatDaftarBarang() async {
    final raw = await DatabaseHelper.instance.getAllItems();
    if (!mounted) return;
    setState(() {
      daftarInventaris = raw.map((e) => ItemInventaris.fromMap(e)).toList();
      if (daftarInventaris.isEmpty) {
        _inputManual = true;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $jam:$menit";
  }

  Future<void> _pilihJadwalKembali() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _batasKembali,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (tgl == null || !mounted) return;

    final waktu = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_batasKembali),
    );
    if (waktu == null || !mounted) return;

    setState(() {
      _batasKembali = DateTime(
        tgl.year,
        tgl.month,
        tgl.day,
        waktu.hour,
        waktu.minute,
      );
    });
  }

  Future<void> _ambilFotoJaminan(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoJaminan = picked;
        _fotoBytes = bytes;
      });
    }
  }

  Future<void> _simpanPeminjaman() async {
    if (namaSantriController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama santri peminjam.')),
      );
      return;
    }

    final namaBarangFinal = _inputManual
        ? barangManualController.text.trim()
        : (itemTerpilih?.namaBarang ?? '');

    if (namaBarangFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau tulis barang yang dipinjam.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String jaminanFinal = _fotoJaminan?.path ?? 'Tanpa Foto EKP';
    if (kIsWeb && _fotoJaminan != null) {
      final urlCloud = await CloudinaryService.uploadFoto(_fotoJaminan!);
      jaminanFinal = urlCloud ?? 'Tanpa Foto EKP';
    }

    final row = {
      'id': const Uuid().v4(),
      'nama_santri': namaSantriController.text.trim(),
      'kamar_santri': kamarSantriController.text.trim().isEmpty
          ? '-'
          : kamarSantriController.text.trim(),
      'kode_unik': _inputManual ? '' : (itemTerpilih?.kodeUnik ?? ''),
      'nama_barang': namaBarangFinal,
      'tanggal_pinjam': _formatDateTime(DateTime.now()),
      'batas_kembali': _formatDateTime(_batasKembali),
      'jaminan_ekp': jaminanFinal,
      'status': 'Dipinjam',
      'is_synced': kIsWeb ? 1 : 0,
    };

    await DatabaseHelper.instance.insertPeminjaman(row);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    namaSantriController.dispose();
    kamarSantriController.dispose();
    barangManualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catat Peminjaman Alat',
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
                TextField(
                  controller: namaSantriController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Santri Peminjam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kamarSantriController,
                  decoration: const InputDecoration(
                    labelText: 'Asal Kamar / Kelas',
                    hintText: 'Misal: Kamar 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bed_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                if (daftarInventaris.isNotEmpty)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Ketik nama barang secara manual',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _inputManual,
                    onChanged: (val) => setState(() => _inputManual = val),
                  ),
                if (!_inputManual)
                  DropdownButtonFormField<ItemInventaris>(
                    value: itemTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Barang dari Inventaris',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: daftarInventaris.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text("${item.kodeUnik} - ${item.namaBarang}"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => itemTerpilih = val),
                  )
                else
                  TextField(
                    controller: barangManualController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang yang Dipinjam',
                      hintText: 'Misal: Proyektor, Kabel Roll, Tangga',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.handyman_outlined),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Batas Waktu Wajib Kembali',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pilihJadwalKembali,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDateTime(_batasKembali),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Ubah',
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Foto Jaminan EKP / Identitas (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!kIsWeb) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _ambilFotoJaminan(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Foto EKP'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ambilFotoJaminan(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(kIsWeb ? 'Pilih Foto EKP' : 'Galeri'),
                      ),
                    ),
                  ],
                ),
                if (_fotoBytes != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _fotoBytes!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
            onPressed: _isSaving ? null : _simpanPeminjaman,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan Peminjaman',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
