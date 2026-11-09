class ItemInventaris {
  String? id;
  String idLokasi;
  String namaBarang;
  String kategori;
  int jumlah;
  String kondisi;
  String? keterangan;
  int isSynced;

  ItemInventaris({
    this.id,
    required this.idLokasi,
    required this.namaBarang,
    required this.kategori,
    this.jumlah = 1,
    required this.kondisi,
    this.keterangan,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_lokasi': idLokasi,
      'nama_barang': namaBarang,
      'kategori': kategori,
      'jumlah': jumlah,
      'kondisi': kondisi,
      'keterangan': keterangan,
      'is_synced': isSynced,
    };
  }

  factory ItemInventaris.fromMap(Map<String, dynamic> map) {
    return ItemInventaris(
      id: map['id'],
      idLokasi: map['id_lokasi'],
      namaBarang: map['nama_barang'],
      kategori: map['kategori'],
      jumlah: map['jumlah'],
      kondisi: map['kondisi'],
      keterangan: map['keterangan'],
      isSynced: map['is_synced'],
    );
  }
}
