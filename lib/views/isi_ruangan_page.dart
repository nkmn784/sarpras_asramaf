import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import '../models/item_inventaris.dart';

class IsiRuanganPage extends StatefulWidget {
  final Lokasi lokasi;
  final bool isAdminSarpras;

  const IsiRuanganPage({
    super.key,
    required this.lokasi,
    this.isAdminSarpras = true,
  });

  @override
  State<IsiRuanganPage> createState() => _IsiRuanganPageState();
}

class _IsiRuanganPageState extends State<IsiRuanganPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ItemInventaris> daftarPeralatan = [];
  List<ItemInventaris> daftarPerlengkapan = [];
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  Future<void> _refreshData() async {
    final rawPeralatan = await DatabaseHelper.instance
        .getItemByLokasiAndKategori(widget.lokasi.id!, 'Peralatan');
    final rawPerlengkapan = await DatabaseHelper.instance
        .getItemByLokasiAndKategori(widget.lokasi.id!, 'Perlengkapan');
    if (!mounted) return;
    setState(() {
      daftarPeralatan = rawPeralatan
          .map((e) => ItemInventaris.fromMap(e))
          .toList();
      daftarPerlengkapan = rawPerlengkapan
          .map((e) => ItemInventaris.fromMap(e))
          .toList();
    });
  }

  void _formItemDialog(String kategori, {ItemInventaris? itemEdit}) {
    final isEdit = itemEdit != null;
    final namaController = TextEditingController(
      text: itemEdit?.namaBarang ?? '',
    );
    final merekController = TextEditingController(text: itemEdit?.merek ?? '');
    final jumlahController = TextEditingController(
      text: '${itemEdit?.jumlah ?? 1}',
    );
    final ketController = TextEditingController(
      text: itemEdit?.keterangan ?? '',
    );
    String kondisi = itemEdit?.kondisi ?? 'Baik';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit ${itemEdit.kodeUnik}' : 'Tambah $kategori',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: merekController,
                  decoration: const InputDecoration(
                    labelText: 'Merek / Spesifikasi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kondisi,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Fisik',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Baik', 'Rusak Ringan', 'Rusak Berat']
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => kondisi = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ketController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
                  if (isEdit) {
                    final updated = ItemInventaris(
                      id: itemEdit.id,
                      idLokasi: itemEdit.idLokasi,
                      kodeUnik: itemEdit.kodeUnik,
                      namaBarang: namaController.text.trim(),
                      kategori: itemEdit.kategori,
                      merek: merekController.text.trim(),
                      jumlah: int.tryParse(jumlahController.text) ?? 1,
                      kondisi: kondisi,
                      keterangan: ketController.text.trim(),
                      isSynced: 0,
                    );
                    await DatabaseHelper.instance.updateItem(
                      itemEdit.id!,
                      updated.toMap(),
                    );
                  } else {
                    final urutan =
                        (kategori == 'Peralatan'
                            ? daftarPeralatan.length
                            : daftarPerlengkapan.length) +
                        1;
                    final kodeUnikBaru = ItemInventaris.buatKodeUnik(
                      widget.lokasi.kodeRuangan,
                      kategori,
                      urutan,
                    );
                    final newItem = ItemInventaris(
                      id: const Uuid().v4(),
                      idLokasi: widget.lokasi.id!,
                      kodeUnik: kodeUnikBaru,
                      namaBarang: namaController.text.trim(),
                      kategori: kategori,
                      merek: merekController.text.trim(),
                      jumlah: int.tryParse(jumlahController.text) ?? 1,
                      kondisi: kondisi,
                      keterangan: ketController.text.trim(),
                    );
                    await DatabaseHelper.instance.insertItem(newItem.toMap());
                  }
                  if (context.mounted) Navigator.pop(context);
                  _refreshData();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Color _warnaTeksKondisi(String kondisi) {
    if (kondisi == 'Baik') return const Color(0xFF0F766E);
    if (kondisi == 'Rusak Ringan') return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _warnaBgKondisi(String kondisi) {
    if (kondisi == 'Baik') return const Color(0x1F0F766E);
    if (kondisi == 'Rusak Ringan') return const Color(0x1FD97706);
    return const Color(0x1FDC2626);
  }

  Widget _buildListView(List<ItemInventaris> sourceList, String kategori) {
    final filtered = sourceList.where((item) {
      final q = _kataKunci.toLowerCase();
      return item.namaBarang.toLowerCase().contains(q) ||
          item.kodeUnik.toLowerCase().contains(q) ||
          (item.merek ?? '').toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _kataKunci.isEmpty
              ? 'Belum ada data $kategori di ${widget.lokasi.namaLokasi}.'
              : 'Tidak ditemukan barang dengan kata kunci "$_kataKunci".',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _warnaBgKondisi(item.kondisi),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.kondisi,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _warnaTeksKondisi(item.kondisi),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.isAdminSarpras) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () =>
                            _formItemDialog(kategori, itemEdit: item),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteItem(item.id!);
                          _refreshData();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.namaBarang} (${item.jumlah} unit)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if ((item.merek ?? '').isNotEmpty ||
                    (item.keterangan ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if ((item.merek ?? '').isNotEmpty)
                          'Merek: ${item.merek}',
                        if ((item.keterangan ?? '').isNotEmpty)
                          item.keterangan!,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lokasi.namaLokasi,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Kode: ${widget.lokasi.kodeRuangan} • PJ: ${widget.lokasi.penanggungJawab ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          indicatorColor: const Color(0xFF0F766E),
          tabs: const [
            Tab(icon: Icon(Icons.build_rounded), text: 'Peralatan'),
            Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Perlengkapan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (val) => setState(() => _kataKunci = val),
              decoration: InputDecoration(
                hintText: 'Cari nama barang atau kode unik (misal: ALT-001)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(daftarPeralatan, 'Peralatan'),
                _buildListView(daftarPerlengkapan, 'Perlengkapan'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdminSarpras
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              onPressed: () {
                final currentKategori = _tabController.index == 0
                    ? 'Peralatan'
                    : 'Perlengkapan';
                _formItemDialog(currentKategori);
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            )
          : null,
    );
  }
}
