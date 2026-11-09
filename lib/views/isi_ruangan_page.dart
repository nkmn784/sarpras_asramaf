import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/lokasi.dart';
import '../models/item_inventaris.dart';

class IsiRuanganPage extends StatefulWidget {
  final Lokasi lokasi;
  const IsiRuanganPage({super.key, required this.lokasi});

  @override
  State<IsiRuanganPage> createState() => _IsiRuanganPageState();
}

class _IsiRuanganPageState extends State<IsiRuanganPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ItemInventaris> daftarPeralatan = [];
  List<ItemInventaris> daftarPerlengkapan = [];

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
    setState(() {
      daftarPeralatan = rawPeralatan
          .map((e) => ItemInventaris.fromMap(e))
          .toList();
      daftarPerlengkapan = rawPerlengkapan
          .map((e) => ItemInventaris.fromMap(e))
          .toList();
    });
  }

  void _tambahItemDialog(String kategori) {
    final namaController = TextEditingController();
    final jumlahController = TextEditingController(text: '1');
    String kondisi = 'Baik';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tambah $kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
              ),
              TextField(
                controller: jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              DropdownButtonFormField<String>(
                value: kondisi,
                items: ['Baik', 'Rusak Ringan', 'Rusak Berat']
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => kondisi = val);
                },
                decoration: const InputDecoration(labelText: 'Kondisi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (namaController.text.isNotEmpty) {
                  final newItem = ItemInventaris(
                    id: const Uuid().v4(),
                    idLokasi: widget.lokasi.id!,
                    namaBarang: namaController.text,
                    kategori: kategori,
                    jumlah: int.tryParse(jumlahController.text) ?? 1,
                    kondisi: kondisi,
                  );
                  await DatabaseHelper.instance.insertItem(newItem.toMap());
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

  Widget _buildListView(List<ItemInventaris> list, String kategori) {
    if (list.isEmpty) {
      return Center(child: Text('Belum ada data $kategori di ruangan ini.'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.namaBarang} (${item.jumlah} unit)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  item.isSynced == 1 ? Icons.cloud_done : Icons.cloud_off,
                  color: item.isSynced == 1 ? Colors.green : Colors.grey,
                  size: 18,
                ),
              ],
            ),
            subtitle: Text('Kondisi: ${item.kondisi}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await DatabaseHelper.instance.deleteItem(item.id!);
                _refreshData();
              },
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
        title: Text(widget.lokasi.namaLokasi),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Peralatan'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Perlengkapan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(daftarPeralatan, 'Peralatan'),
          _buildListView(daftarPerlengkapan, 'Perlengkapan'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          final currentKategori = _tabController.index == 0
              ? 'Peralatan'
              : 'Perlengkapan';
          _tambahItemDialog(currentKategori);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
