class ItemInventaris {
  String? id;
  String idLokasi;
  String kodeUnik;
  String namaBarang;
  String kategori;
  String? merek;
  int jumlah;
  String kondisi;
  String? keterangan;
  int isSynced;

  ItemInventaris({
    this.id,
    required this.idLokasi,
    required this.kodeUnik,
    required this.namaBarang,
    required this.kategori,
    this.merek,
    this.jumlah = 1,
    required this.kondisi,
    this.keterangan,
    this.isSynced = 0,
  });

  static String buatKodeUnik(String kodeRuangan, String kategori, int urutan) {
    final kodeRuangBersih = kodeRuangan.replaceAll('-', '');
    final kodeKat = kategori == 'Peralatan' ? 'ALT' : 'PLK';
    final nomor = urutan.toString().padLeft(3, '0');
    return '$kodeRuangBersih-$kodeKat-$nomor';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_lokasi': idLokasi,
      'kode_unik': kodeUnik,
      'nama_barang': namaBarang,
      'kategori': kategori,
      'merek': merek,
      'jumlah': jumlah,
      'kondisi': kondisi,
      'keterangan': keterangan,
      'is_synced': isSynced,
    };
  }

  factory ItemInventaris.fromMap(Map<String, dynamic> map) {
    return ItemInventaris(
      id: map['id']?.toString(),
      idLokasi: map['id_lokasi']?.toString() ?? '',
      kodeUnik: map['kode_unik']?.toString() ?? 'ITM-000',
      namaBarang: map['nama_barang']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? 'Peralatan',
      merek: map['merek']?.toString(),
      jumlah: (map['jumlah'] as int?) ?? 1,
      kondisi: map['kondisi']?.toString() ?? 'Baik',
      keterangan: map['keterangan']?.toString(),
      isSynced: (map['is_synced'] as int?) ?? 0,
    );
  }
}
