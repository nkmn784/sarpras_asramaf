class Pengaduan {
  final String? id;
  final String namaPelapor; // Bisa santri atau wali santri
  final String fasilitasRusak; // Deskripsi kerusakan
  final String tanggalLapor;
  final String status; // 'Menunggu', 'Dikerjakan Biro', atau 'Diserahkan Pusat'
  final int isSynced;

  Pengaduan({
    this.id,
    required this.namaPelapor,
    required this.fasilitasRusak,
    required this.tanggalLapor,
    this.status = 'Menunggu', // Default saat pertama kali dilapor
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pelapor': namaPelapor,
      'fasilitas_rusak': fasilitasRusak,
      'tanggal_lapor': tanggalLapor,
      'status': status,
      'is_synced': isSynced,
    };
  }

  factory Pengaduan.fromMap(Map<String, dynamic> map) {
    return Pengaduan(
      id: map['id'],
      namaPelapor: map['nama_pelapor'],
      fasilitasRusak: map['fasilitas_rusak'],
      tanggalLapor: map['tanggal_lapor'],
      status: map['status'],
      isSynced: map['is_synced'],
    );
  }
}
