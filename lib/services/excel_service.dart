import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

typedef InfoLokasi = Map<String, String>;

enum JenisEksporExcel { semuaLengkap, inventarisSaja, laporanWargaSaja }

class ExcelService {
  static final Border _borderTipis = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.fromHexString('#CBD5E1'),
  );

  static CellStyle _styleJudul() {
    return CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#0F766E'),
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _styleSubjudul() {
    return CellStyle(
      italic: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#475569'),
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _styleHeader() {
    return CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F766E'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _borderTipis,
      rightBorder: _borderTipis,
      topBorder: _borderTipis,
      bottomBorder: _borderTipis,
    );
  }

  static CellStyle _styleData({
    bool rataTengah = false,
    String warnaBgHex = '#FFFFFF',
    String warnaTeksHex = '#1E293B',
    bool tebal = false,
  }) {
    return CellStyle(
      bold: tebal,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString(warnaTeksHex),
      backgroundColorHex: ExcelColor.fromHexString(warnaBgHex),
      horizontalAlign: rataTengah
          ? HorizontalAlign.Center
          : HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _borderTipis,
      rightBorder: _borderTipis,
      topBorder: _borderTipis,
      bottomBorder: _borderTipis,
    );
  }

  static void _isiTeks(
    Sheet sheet,
    int col,
    int row,
    String teks,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(teks);
    cell.cellStyle = style;
  }

  static void _isiAngka(
    Sheet sheet,
    int col,
    int row,
    int angka,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = IntCellValue(angka);
    cell.cellStyle = style;
  }

  static String _stampWaktu() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $jam:$menit";
  }

  static String _stampNamaFile() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return "${y}${m}${d}";
  }

  static Future<bool> eksporLaporan(JenisEksporExcel jenis) async {
    final excel = Excel.createExcel();
    final waktuCetak = _stampWaktu();

    if (jenis == JenisEksporExcel.semuaLengkap ||
        jenis == JenisEksporExcel.inventarisSaja) {
      await _buatSheetInventaris(excel, waktuCetak);
    }

    if (jenis == JenisEksporExcel.semuaLengkap) {
      await _buatSheetInspeksi(excel, waktuCetak);
      await _buatSheetPeminjaman(excel, waktuCetak);
    }

    if (jenis == JenisEksporExcel.semuaLengkap ||
        jenis == JenisEksporExcel.laporanWargaSaja) {
      await _buatSheetLaporanWarga(excel, waktuCetak);
    }

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final rawBytes = excel.save();
    if (rawBytes == null) return false;

    final prefix = jenis == JenisEksporExcel.inventarisSaja
        ? 'Inventaris_Sarpras'
        : (jenis == JenisEksporExcel.laporanWargaSaja
              ? 'Laporan_Warga_Sarpras'
              : 'Rekap_Lengkap_Sarpras');
    final namaFile = "${prefix}_AsramaF_${_stampNamaFile()}.xlsx";

    final fileXlsx = XFile.fromData(
      Uint8List.fromList(rawBytes),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      name: namaFile,
    );

    await Share.shareXFiles(
      [fileXlsx],
      subject: 'Rekap Sarpras Asrama F',
      text: 'Dokumen rekap Excel Sarpras Asrama F ($namaFile)',
    );
    return true;
  }

  // ================= SHEET 1: INVENTARIS BARANG =================
  static Future<void> _buatSheetInventaris(
    Excel excel,
    String waktuCetak,
  ) async {
    final sheet = excel['Inventaris Barang'];
    final daftarLokasi = await DatabaseHelper.instance.getAllLokasi();
    final daftarItem = await DatabaseHelper.instance.getAllItems();

    final Map<String, InfoLokasi> petaLokasi = {};
    for (var lok in daftarLokasi) {
      final id = (lok['id'] ?? '').toString();
      petaLokasi[id] = {
        'kode': (lok['kode_ruangan'] ?? '-').toString(),
        'nama': (lok['nama_lokasi'] ?? '-').toString(),
      };
    }

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
    );
    _isiTeks(
      sheet,
      0,
      0,
      'REKAPITULASI INVENTARIS SARPRAS ASRAMA F',
      _styleJudul(),
    );
    _isiTeks(sheet, 0, 1, 'Dicetak pada: $waktuCetak', _styleSubjudul());

    final headers = [
      'No',
      'Kode Ruang',
      'Nama Ruangan',
      'Kode Barang',
      'Nama Barang',
      'Kategori',
      'Merek',
      'Jumlah',
      'Kondisi',
      'Keterangan',
    ];
    for (int c = 0; c < headers.length; c++) {
      _isiTeks(sheet, c, 3, headers[c], _styleHeader());
    }

    int rowIdx = 4;
    int totalUnit = 0;
    int totalRusak = 0;

    for (int i = 0; i < daftarItem.length; i++) {
      final item = daftarItem[i];
      final idLok = (item['id_lokasi'] ?? '').toString();
      final infoLok = petaLokasi[idLok] ?? {'kode': '-', 'nama': 'Umum'};
      final qty = (item['jumlah'] as num?)?.toInt() ?? 1;
      final kondisi = (item['kondisi'] ?? 'Baik').toString();

      totalUnit += qty;
      if (kondisi != 'Baik') totalRusak += qty;

      final warnaKondisiBg = kondisi == 'Rusak Berat'
          ? '#FEE2E2'
          : (kondisi == 'Rusak Ringan' ? '#FEF3C7' : '#DCFCE7');
      final warnaKondisiTeks = kondisi == 'Rusak Berat'
          ? '#B91C1C'
          : (kondisi == 'Rusak Ringan' ? '#B45309' : '#0F766E');

      _isiAngka(sheet, 0, rowIdx, i + 1, _styleData(rataTengah: true));
      _isiTeks(
        sheet,
        1,
        rowIdx,
        infoLok['kode']!,
        _styleData(rataTengah: true),
      );
      _isiTeks(sheet, 2, rowIdx, infoLok['nama']!, _styleData());
      _isiTeks(
        sheet,
        3,
        rowIdx,
        (item['kode_unik'] ?? '-').toString(),
        _styleData(rataTengah: true, tebal: true),
      );
      _isiTeks(
        sheet,
        4,
        rowIdx,
        (item['nama_barang'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        5,
        rowIdx,
        (item['kategori'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        6,
        rowIdx,
        (item['merek'] ?? '-').toString(),
        _styleData(),
      );
      _isiAngka(sheet, 7, rowIdx, qty, _styleData(rataTengah: true));
      _isiTeks(
        sheet,
        8,
        rowIdx,
        kondisi,
        _styleData(
          rataTengah: true,
          warnaBgHex: warnaKondisiBg,
          warnaTeksHex: warnaKondisiTeks,
          tebal: true,
        ),
      );
      _isiTeks(
        sheet,
        9,
        rowIdx,
        (item['keterangan'] ?? '-').toString(),
        _styleData(),
      );
      rowIdx++;
    }

    // Baris Ringkasan Bawah
    _isiTeks(
      sheet,
      6,
      rowIdx,
      'TOTAL UNIT',
      _styleData(rataTengah: true, warnaBgHex: '#F1F5F9', tebal: true),
    );
    _isiAngka(
      sheet,
      7,
      rowIdx,
      totalUnit,
      _styleData(rataTengah: true, warnaBgHex: '#F1F5F9', tebal: true),
    );
    _isiTeks(
      sheet,
      8,
      rowIdx,
      'Rusak: $totalRusak unit',
      _styleData(
        rataTengah: true,
        warnaBgHex: '#F1F5F9',
        warnaTeksHex: '#B91C1C',
        tebal: true,
      ),
    );

    final lebarKolom = [
      6.0,
      14.0,
      22.0,
      15.0,
      26.0,
      16.0,
      16.0,
      10.0,
      16.0,
      26.0,
    ];
    for (int c = 0; c < lebarKolom.length; c++) {
      sheet.setColumnWidth(c, lebarKolom[c]);
    }
  }

  // ================= SHEET 2: RIWAYAT INSPEKSI =================
  static Future<void> _buatSheetInspeksi(Excel excel, String waktuCetak) async {
    final sheet = excel['Riwayat Inspeksi'];
    final daftarInspeksi = await DatabaseHelper.instance.getAllInspeksi();

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    _isiTeks(
      sheet,
      0,
      0,
      'RIWAYAT INSPEKSI RUTIN RUANGAN ASRAMA F',
      _styleJudul(),
    );
    _isiTeks(sheet, 0, 1, 'Dicetak pada: $waktuCetak', _styleSubjudul());

    final headers = [
      'No',
      'Tanggal Inspeksi',
      'Ruangan / Lokasi',
      'Petugas Pemeriksa',
      'Kondisi Ruangan',
      'Catatan Inspeksi',
    ];
    for (int c = 0; c < headers.length; c++) {
      _isiTeks(sheet, c, 3, headers[c], _styleHeader());
    }

    int rowIdx = 4;
    for (int i = 0; i < daftarInspeksi.length; i++) {
      final ins = daftarInspeksi[i];
      _isiAngka(sheet, 0, rowIdx, i + 1, _styleData(rataTengah: true));
      _isiTeks(
        sheet,
        1,
        rowIdx,
        (ins['tanggal'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        2,
        rowIdx,
        (ins['nama_lokasi'] ?? '-').toString(),
        _styleData(tebal: true),
      );
      _isiTeks(
        sheet,
        3,
        rowIdx,
        (ins['petugas'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        4,
        rowIdx,
        (ins['kondisi_ruangan'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        5,
        rowIdx,
        (ins['catatan'] ?? '-').toString(),
        _styleData(),
      );
      rowIdx++;
    }

    final lebarKolom = [6.0, 20.0, 26.0, 22.0, 22.0, 34.0];
    for (int c = 0; c < lebarKolom.length; c++) {
      sheet.setColumnWidth(c, lebarKolom[c]);
    }
  }

  // ================= SHEET 3: PEMINJAMAN ALAT =================
  static Future<void> _buatSheetPeminjaman(
    Excel excel,
    String waktuCetak,
  ) async {
    final sheet = excel['Peminjaman Alat'];
    final daftarPinjam = await DatabaseHelper.instance.getAllPeminjaman();

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
    );
    _isiTeks(sheet, 0, 0, 'LOG PEMINJAMAN ALAT SANTRI ASRAMA F', _styleJudul());
    _isiTeks(sheet, 0, 1, 'Dicetak pada: $waktuCetak', _styleSubjudul());

    final headers = [
      'No',
      'Nama Santri',
      'Asal Kamar',
      'Kode Barang',
      'Nama Barang',
      'Waktu Pinjam',
      'Batas Kembali',
      'Status',
    ];
    for (int c = 0; c < headers.length; c++) {
      _isiTeks(sheet, c, 3, headers[c], _styleHeader());
    }

    int rowIdx = 4;
    for (int i = 0; i < daftarPinjam.length; i++) {
      final p = daftarPinjam[i];
      final status = (p['status'] ?? 'Dipinjam').toString();
      final sudahKembali = status == 'Dikembalikan';

      _isiAngka(sheet, 0, rowIdx, i + 1, _styleData(rataTengah: true));
      _isiTeks(
        sheet,
        1,
        rowIdx,
        (p['nama_santri'] ?? '-').toString(),
        _styleData(tebal: true),
      );
      _isiTeks(
        sheet,
        2,
        rowIdx,
        (p['kamar_santri'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        3,
        rowIdx,
        (p['kode_unik'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        4,
        rowIdx,
        (p['nama_barang'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        5,
        rowIdx,
        (p['tanggal_pinjam'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        6,
        rowIdx,
        (p['batas_kembali'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        7,
        rowIdx,
        status,
        _styleData(
          rataTengah: true,
          warnaBgHex: sudahKembali ? '#DCFCE7' : '#FEF3C7',
          warnaTeksHex: sudahKembali ? '#0F766E' : '#B45309',
          tebal: true,
        ),
      );
      rowIdx++;
    }

    final lebarKolom = [6.0, 22.0, 15.0, 15.0, 25.0, 18.0, 18.0, 16.0];
    for (int c = 0; c < lebarKolom.length; c++) {
      sheet.setColumnWidth(c, lebarKolom[c]);
    }
  }

  // ================= SHEET 4: LAPORAN KERUSAKAN & USULAN =================
  static Future<void> _buatSheetLaporanWarga(
    Excel excel,
    String waktuCetak,
  ) async {
    final sheet = excel['Laporan & Usulan'];
    final daftarLaporan = await DatabaseHelper.instance.getAllLaporanWarga();

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0),
    );
    _isiTeks(
      sheet,
      0,
      0,
      'REKAP LAPORAN KERUSAKAN & USULAN BARANG ASRAMA F',
      _styleJudul(),
    );
    _isiTeks(sheet, 0, 1, 'Dicetak pada: $waktuCetak', _styleSubjudul());

    final headers = [
      'No',
      'Tanggal Lapor',
      'Jenis Laporan',
      'Nama Pelapor',
      'Peran',
      'Lokasi',
      'Barang / Fasilitas',
      'Jumlah',
      'Deskripsi / Alasan',
      'Status',
      'Tanggapan Sarpras',
    ];
    for (int c = 0; c < headers.length; c++) {
      _isiTeks(sheet, c, 3, headers[c], _styleHeader());
    }

    int rowIdx = 4;
    for (int i = 0; i < daftarLaporan.length; i++) {
      final lap = daftarLaporan[i];
      final status = (lap['status'] ?? 'Menunggu').toString();
      final warnaBg = status == 'Selesai'
          ? '#DCFCE7'
          : (status == 'Ditolak' ? '#FEE2E2' : '#FEF3C7');
      final warnaTeks = status == 'Selesai'
          ? '#0F766E'
          : (status == 'Ditolak' ? '#B91C1C' : '#B45309');

      _isiAngka(sheet, 0, rowIdx, i + 1, _styleData(rataTengah: true));
      _isiTeks(
        sheet,
        1,
        rowIdx,
        (lap['tanggal_lapor'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        2,
        rowIdx,
        (lap['jenis_laporan'] ?? '-').toString(),
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        3,
        rowIdx,
        (lap['nama_pelapor'] ?? '-').toString(),
        _styleData(tebal: true),
      );
      _isiTeks(
        sheet,
        4,
        rowIdx,
        (lap['peran_pelapor'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        5,
        rowIdx,
        (lap['nama_lokasi'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        6,
        rowIdx,
        (lap['nama_barang'] ?? '-').toString(),
        _styleData(),
      );
      _isiAngka(
        sheet,
        7,
        rowIdx,
        (lap['jumlah'] as num?)?.toInt() ?? 1,
        _styleData(rataTengah: true),
      );
      _isiTeks(
        sheet,
        8,
        rowIdx,
        (lap['deskripsi'] ?? '-').toString(),
        _styleData(),
      );
      _isiTeks(
        sheet,
        9,
        rowIdx,
        status,
        _styleData(
          rataTengah: true,
          warnaBgHex: warnaBg,
          warnaTeksHex: warnaTeks,
          tebal: true,
        ),
      );
      _isiTeks(
        sheet,
        10,
        rowIdx,
        (lap['tanggapan_sarpras'] ?? '-').toString(),
        _styleData(),
      );
      rowIdx++;
    }

    final lebarKolom = [
      6.0,
      18.0,
      18.0,
      20.0,
      16.0,
      22.0,
      24.0,
      10.0,
      32.0,
      14.0,
      28.0,
    ];
    for (int c = 0; c < lebarKolom.length; c++) {
      sheet.setColumnWidth(c, lebarKolom[c]);
    }
  }
}
