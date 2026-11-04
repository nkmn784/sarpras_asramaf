class Peminjaman {
  final String? id;
  final String namaSantri;
  final String namaBarang;
  final String tanggalPinjam;
  final String jaminanEkp; // Sementara berupa teks/nomor EKP, nanti kita tingkatkan jadi foto
  final String status; // Isinya: 'Dipinjam' atau 'Dikembalikan'
  final int isSynced;

  Peminjaman({
    this.id,
    required this.namaSantri,
    required this.namaBarang,
    required this.tanggalPinjam,
    required this.jaminanEkp,
    this.status = 'Dipinjam',
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_santri': namaSantri,
      'nama_barang': namaBarang,
      'tanggal_pinjam': tanggalPinjam,
      'jaminan_ekp': jaminanEkp,
      'status': status,
      'is_synced': isSynced,
    };
  }

  factory Peminjaman.fromMap(Map<String, dynamic> map) {
    return Peminjaman(
      id: map['id'],
      namaSantri: map['nama_santri'],
      namaBarang: map['nama_barang'],
      tanggalPinjam: map['tanggal_pinjam'],
      jaminanEkp: map['jaminan_ekp'],
      status: map['status'],
      isSynced: map['is_synced'],
    );
  }
}
