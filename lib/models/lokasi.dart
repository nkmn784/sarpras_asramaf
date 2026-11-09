class Lokasi {
  String? id;
  String namaLokasi;
  int isSynced;

  Lokasi({this.id, required this.namaLokasi, this.isSynced = 0});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama_lokasi': namaLokasi, 'is_synced': isSynced};
  }

  factory Lokasi.fromMap(Map<String, dynamic> map) {
    return Lokasi(
      id: map['id'],
      namaLokasi: map['nama_lokasi'],
      isSynced: map['is_synced'],
    );
  }
}
