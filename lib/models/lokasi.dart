class Lokasi {
  String? id;
  String kodeRuangan;
  String namaLokasi;
  String? penanggungJawab;
  int isSynced;

  Lokasi({
    this.id,
    required this.kodeRuangan,
    required this.namaLokasi,
    this.penanggungJawab,
    this.isSynced = 0,
  });

  static String buatKodeRuangan(String namaLokasi, int urutan) {
    final hurufSaja = namaLokasi
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toUpperCase();
    final awalan = hurufSaja.padRight(3, 'R').substring(0, 3);
    final nomor = urutan.toString().padLeft(2, '0');
    return '$awalan-$nomor';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_ruangan': kodeRuangan,
      'nama_lokasi': namaLokasi,
      'penanggung_jawab': penanggungJawab,
      'is_synced': isSynced,
    };
  }

  factory Lokasi.fromMap(Map<String, dynamic> map) {
    return Lokasi(
      id: map['id']?.toString(),
      kodeRuangan: map['kode_ruangan']?.toString() ?? 'RNG-00',
      namaLokasi: map['nama_lokasi']?.toString() ?? '',
      penanggungJawab: map['penanggung_jawab']?.toString(),
      isSynced: (map['is_synced'] as int?) ?? 0,
    );
  }
}
