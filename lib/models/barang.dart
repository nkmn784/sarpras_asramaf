class Barang {
  final String?
  id; // Menggunakan String untuk UUID agar aman saat sinkronisasi offline
  final String namaBarang;
  final int jumlah;
  final int kondisiBaik;
  final int kondisiTidak;
  final int isSynced; // 0 = Belum sinkron ke cloud, 1 = Sudah sinkron

  Barang({
    this.id,
    required this.namaBarang,
    required this.jumlah,
    required this.kondisiBaik,
    required this.kondisiTidak,
    this.isSynced = 0, // Default 0 saat baru dibuat secara offline
  });

  // Mengubah objek Dart menjadi format yang bisa disimpan oleh SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'kondisi_baik': kondisiBaik,
      'kondisi_tidak': kondisiTidak,
      'is_synced': isSynced,
    };
  }

  // Mengubah data dari SQLite kembali menjadi objek Dart
  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'],
      namaBarang: map['nama_barang'],
      jumlah: map['jumlah'],
      kondisiBaik: map['kondisi_baik'],
      kondisiTidak: map['kondisi_tidak'],
      isSynced: map['is_synced'],
    );
  }
}
