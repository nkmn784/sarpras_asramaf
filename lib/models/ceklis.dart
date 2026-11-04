class Ceklis {
  final String? id;
  final String tanggal;
  final String
  petugas; // Nama petugas piket hari itu (Misal: Nu'man, Rozaq, dll)
  final String namaFasilitas; // Fasilitas yang dicek (Misal: Kamar Mandi Lantai 1, Lampu Lorong)
  final int kondisi; // 1 = Berfungsi (Ceklis), 0 = Bermasalah (Silang)
  final int isSynced;

  Ceklis({
    this.id,
    required this.tanggal,
    required this.petugas,
    required this.namaFasilitas,
    required this.kondisi,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal,
      'petugas': petugas,
      'nama_fasilitas': namaFasilitas,
      'kondisi': kondisi,
      'is_synced': isSynced,
    };
  }

  factory Ceklis.fromMap(Map<String, dynamic> map) {
    return Ceklis(
      id: map['id'],
      tanggal: map['tanggal'],
      petugas: map['petugas'],
      namaFasilitas: map['nama_fasilitas'],
      kondisi: map['kondisi'],
      isSynced: map['is_synced'],
    );
  }
}
