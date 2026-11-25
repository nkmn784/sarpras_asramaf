import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyRoleAktif = 'role_aktif';
  static const String _keyNamaPetugas = 'nama_petugas_default';
  static const String _keyPinOtorisasi = 'pin_otorisasi_sarpras';
  static const String _keyAutoSync = 'auto_sync_aktif';
  static const String _keyPengingatInspeksi = 'pengingat_inspeksi_aktif';
  static const String _keyJamInspeksi = 'jam_pengingat_inspeksi';
  static const String _keyPengingatPinjam = 'pengingat_pinjam_aktif';

  static Future<String> getRoleAktif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRoleAktif) ?? '';
  }

  static Future<void> setRoleAktif(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoleAktif, role);
  }

  static Future<String> getNamaPetugas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNamaPetugas) ?? '';
  }

  static Future<void> setNamaPetugas(String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNamaPetugas, nama);
  }

  static Future<String> getPinOtorisasi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPinOtorisasi) ?? '1234';
  }

  static Future<void> setPinOtorisasi(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinOtorisasi, pin);
  }

  static Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? true;
  }

  static Future<void> setAutoSync(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, aktif);
  }

  static Future<bool> getPengingatInspeksi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPengingatInspeksi) ?? true;
  }

  static Future<void> setPengingatInspeksi(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPengingatInspeksi, aktif);
  }

  static Future<String> getJamInspeksi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJamInspeksi) ?? '08:00';
  }

  static Future<void> setJamInspeksi(String jam) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJamInspeksi, jam);
  }

  static Future<bool> getPengingatPinjam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPengingatPinjam) ?? true;
  }

  static Future<void> setPengingatPinjam(bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPengingatPinjam, aktif);
  }
}
