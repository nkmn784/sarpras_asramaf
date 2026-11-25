import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/item_inventaris.dart';
import '../models/lokasi.dart';
import '../services/sync_service.dart';
import 'isi_ruangan_page.dart';

class PencarianBarangPage extends StatefulWidget {
  final bool isAdminSarpras;
  final String filterKondisiAwal;

  const PencarianBarangPage({
    super.key,
    this.isAdminSarpras = true,
    this.filterKondisiAwal = 'Semua',
  });

  @override
  State<PencarianBarangPage> createState() => _PencarianBarangPageState();
}

class _PencarianBarangPageState extends State<PencarianBarangPage> {
  final TextEditingController _searchController = TextEditingController();

  List<ItemInventaris> _semuaItem = [];
  Map<String, Lokasi> _petaLokasi = {};
  List<Lokasi> _daftarLokasi = [];

  String _kataKunci = '';
  late String _filterKondisi;
  String _filterIdLokasi = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filterKondisi = widget.filterKondisiAwal;
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    final rawLokasi = await DatabaseHelper.instance.getAllLokasi();
    final rawItems = await DatabaseHelper.instance.getAllItems();

    final listLokasi = rawLokasi.map((e) => Lokasi.fromMap(e)).toList();
    final Map<String, Lokasi> mapLok = {};
    for (var lok in listLokasi) {
      if (lok.id != null) {
        mapLok[lok.id!] = lok;
      }
    }

    if (!mounted) return;
    setState(() {
      _daftarLokasi = listLokasi;
      _petaLokasi = mapLok;
      _semuaItem = rawItems.map((e) => ItemInventaris.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  List<ItemInventaris> get _hasilFilter {
    final q = _kataKunci.trim().toLowerCase();
    return _semuaItem.where((item) {
      // 1. Filter Ruangan
      if (_filterIdLokasi != 'Semua' && item.idLokasi != _filterIdLokasi) {
        return false;
      }

      // 2. Filter Kondisi
      if (_filterKondisi == 'Perlu Servis') {
        if (item.kondisi == 'Baik') return false;
      } else if (_filterKondisi != 'Semua') {
        if (item.kondisi != _filterKondisi) return false;
      }

      // 3. Filter Kata Kunci (Kode, Nama Barang, Merek, Kategori, Ruangan)
      if (q.isNotEmpty) {
        final lok = _petaLokasi[item.idLokasi];
        final teksGabungan = [
          item.kodeUnik,
          item.namaBarang,
          item.kategori,
          item.merek ?? '',
          item.keterangan ?? '',
          lok?.kodeRuangan ?? '',
          lok?.namaLokasi ?? '',
        ].join(' ').toLowerCase();

        if (!teksGabungan.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  int _hitungJumlahByFilter(String kategoriFilter) {
    return _semuaItem.where((item) {
      if (_filterIdLokasi != 'Semua' && item.idLokasi != _filterIdLokasi) {
        return false;
      }
      if (kategoriFilter == 'Semua') return true;
      if (kategoriFilter == 'Perlu Servis') return item.kondisi != 'Baik';
      return item.kondisi == kategoriFilter;
    }).length;
  }

  Color _warnaKondisi(String kondisi) {
    if (kondisi == 'Rusak Berat') return const Color(0xFFDC2626);
    if (kondisi == 'Rusak Ringan') return const Color(0xFFD97706);
    return const Color(0xFF0F766E);
  }

  Color _bgKondisi(String kondisi) {
    if (kondisi == 'Rusak Berat') return const Color(0x1FDC2626);
    if (kondisi == 'Rusak Ringan') return const Color(0x1FD97706);
    return const Color(0x1F0F766E);
  }

  Future<void> _ubahKondisiCepat(
    ItemInventaris item,
    String kondisiBaru,
  ) async {
    if (item.id == null) return;
    await DatabaseHelper.instance.updateItem(item.id!, {
      'kondisi': kondisiBaru,
      'is_synced': 0,
    });
    await _muatData();
    SyncService.syncSemuaData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kondisi ${item.namaBarang} diperbarui menjadi $kondisiBaru',
        ),
      ),
    );
  }

  void _tampilkanDetailItem(ItemInventaris item) {
    final lokasi = _petaLokasi[item.idLokasi];
    String kondisiSaatIni = item.kondisi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0F766E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.kodeUnik,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _bgKondisi(kondisiSaatIni),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kondisiSaatIni,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _warnaKondisi(kondisiSaatIni),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.namaBarang,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              _BarisInfo(
                icon: Icons.meeting_room_outlined,
                label: 'Lokasi',
                nilai: lokasi != null
                    ? '${lokasi.kodeRuangan} - ${lokasi.namaLokasi} (PJ: ${lokasi.penanggungJawab ?? '-'})'
                    : 'Ruangan tidak ditemukan',
              ),
              _BarisInfo(
                icon: Icons.category_outlined,
                label: 'Kategori & Merek',
                nilai:
                    '${item.kategori}${(item.merek ?? '').isNotEmpty ? ' • ${item.merek}' : ''}',
              ),
              _BarisInfo(
                icon: Icons.numbers_rounded,
                label: 'Jumlah Unit',
                nilai: '${item.jumlah} unit',
              ),
              if ((item.keterangan ?? '').isNotEmpty)
                _BarisInfo(
                  icon: Icons.notes_rounded,
                  label: 'Keterangan',
                  nilai: item.keterangan!,
                ),
              if (widget.isAdminSarpras) ...[
                const Divider(height: 24),
                const Text(
                  'Ubah Status Kondisi Cepat:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Baik', 'Rusak Ringan', 'Rusak Berat'].map((st) {
                    final terpilih = kondisiSaatIni == st;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              st == 'Rusak Ringan'
                                  ? 'R. Ringan'
                                  : (st == 'Rusak Berat' ? 'R. Berat' : st),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: terpilih
                                    ? Colors.white
                                    : _warnaKondisi(st),
                              ),
                            ),
                          ),
                          selected: terpilih,
                          selectedColor: _warnaKondisi(st),
                          onSelected: (_) async {
                            setSheetState(() => kondisiSaatIni = st);
                            await _ubahKondisiCepat(item, st);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (lokasi != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IsiRuanganPage(
                            lokasi: lokasi,
                            isAdminSarpras: widget.isAdminSarpras,
                          ),
                        ),
                      );
                      _muatData();
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('Buka Ruangan ${lokasi.namaLokasi}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daftarTampil = _hasilFilter;
    final totalUnitTampil = daftarTampil.fold<int>(
      0,
      (sum, item) => sum + item.jumlah,
    );

    final daftarChip = [
      'Semua',
      'Perlu Servis',
      'Baik',
      'Rusak Ringan',
      'Rusak Berat',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cari & Filter Inventaris',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Pencarian aset lintas ruangan asrama',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bilah Pencarian & Filter Ruangan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _kataKunci = val),
                  decoration: InputDecoration(
                    hintText:
                        'Cari kode (ITM-...), nama barang, merek, kamar...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0F766E),
                    ),
                    suffixIcon: _kataKunci.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _kataKunci = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _filterIdLokasi,
                  isDense: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.meeting_room_outlined,
                      size: 20,
                      color: Color(0xFF0F766E),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Semua',
                      child: Text('Semua Ruangan & Area'),
                    ),
                    ..._daftarLokasi.where((l) => l.id != null).map((lok) {
                      return DropdownMenuItem(
                        value: lok.id!,
                        child: Text('${lok.kodeRuangan} - ${lok.namaLokasi}'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _filterIdLokasi = val);
                  },
                ),
              ],
            ),
          ),

          // Filter Chip Kondisi Barang
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: daftarChip.length,
              itemBuilder: (context, index) {
                final label = daftarChip[index];
                final aktif = _filterKondisi == label;
                final jumlah = _hitungJumlahByFilter(label);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$label ($jumlah)'),
                    selected: aktif,
                    selectedColor:
                        label == 'Perlu Servis' || label == 'Rusak Berat'
                        ? const Color(0x26DC2626)
                        : (label == 'Rusak Ringan'
                              ? const Color(0x26D97706)
                              : const Color(0x260F766E)),
                    onSelected: (_) => setState(() => _filterKondisi = label),
                  ),
                );
              },
            ),
          ),

          // Ringkasan Hasil
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ditemukan ${daftarTampil.length} jenis barang ($totalUnitTampil unit)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_kataKunci.isNotEmpty ||
                    _filterKondisi != 'Semua' ||
                    _filterIdLokasi != 'Semua')
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _kataKunci = '';
                        _filterKondisi = 'Semua';
                        _filterIdLokasi = 'Semua';
                      });
                    },
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Daftar Hasil Pencarian
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : daftarTampil.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada barang yang cocok dengan filter.\nCoba ubah kata kunci atau filter kondisi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: daftarTampil.length,
                    itemBuilder: (context, index) {
                      final item = daftarTampil[index];
                      final lokasi = _petaLokasi[item.idLokasi];

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _tampilkanDetailItem(item),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _bgKondisi(item.kondisi),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.kondisi,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _warnaKondisi(item.kondisi),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${item.jumlah} unit',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.namaBarang,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.meeting_room_outlined,
                                      size: 15,
                                      color: Color(0xFF0F766E),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        lokasi != null
                                            ? '${lokasi.kodeRuangan} • ${lokasi.namaLokasi}'
                                            : 'Lokasi tidak diketahui',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.kategori,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _BarisInfo({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: nilai),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
