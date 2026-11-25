import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/preference_service.dart';
import 'role_selection_page.dart';

class PengaturanPage extends StatefulWidget {
  final bool isAdminSarpras;
  const PengaturanPage({super.key, this.isAdminSarpras = true});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _namaPetugasController = TextEditingController();
  final _pinController = TextEditingController();

  bool _autoSync = true;
  bool _pengingatInspeksi = true;
  String _jamInspeksi = '08:00';
  bool _pengingatPinjam = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatPreferensi();
  }

  Future<void> _muatPreferensi() async {
    final nama = await PreferenceService.getNamaPetugas();
    final pin = await PreferenceService.getPinOtorisasi();
    final autoSync = await PreferenceService.getAutoSync();
    final pengingatIns = await PreferenceService.getPengingatInspeksi();
    final jamIns = await PreferenceService.getJamInspeksi();
    final pengingatPjm = await PreferenceService.getPengingatPinjam();

    if (!mounted) return;
    setState(() {
      _namaPetugasController.text = nama;
      _pinController.text = pin;
      _autoSync = autoSync;
      _pengingatInspeksi = pengingatIns;
      _jamInspeksi = jamIns;
      _pengingatPinjam = pengingatPjm;
      _isLoading = false;
    });
  }

  Future<void> _pilihJamInspeksi() async {
    final parts = _jamInspeksi.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final jam = picked.hour.toString().padLeft(2, '0');
      final menit = picked.minute.toString().padLeft(2, '0');
      setState(() => _jamInspeksi = '$jam:$menit');
    }
  }

  Future<void> _simpanPengaturan() async {
    final pinBaru = _pinController.text.trim();
    if (widget.isAdminSarpras && pinBaru.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Otorisasi minimal 4 digit angka.')),
      );
      return;
    }

    final namaBaru = _namaPetugasController.text.trim();
    await PreferenceService.setNamaPetugas(namaBaru);
    if (widget.isAdminSarpras) {
      await PreferenceService.setPinOtorisasi(pinBaru);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(namaBaru);
    }
    await PreferenceService.setAutoSync(_autoSync);
    await PreferenceService.setPengingatInspeksi(_pengingatInspeksi);
    await PreferenceService.setJamInspeksi(_jamInspeksi);
    await PreferenceService.setPengingatPinjam(_pengingatPinjam);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferensi & pengaturan berhasil disimpan!'),
      ),
    );
  }

  Future<void> _keluarAkun() async {
    await FirebaseAuth.instance.signOut();
    await PreferenceService.setRoleAktif('');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _namaPetugasController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statusAuth = user == null
        ? 'Sesi Lokal'
        : (user.isAnonymous ? 'Anonymous Auth (Warga)' : 'Firebase Email Auth');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan & Akun',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Kartu Status Autentikasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0x1A0F766E),
                            child: Icon(
                              widget.isAdminSarpras
                                  ? Icons.verified_user_rounded
                                  : Icons.person_outline_rounded,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isAdminSarpras
                                      ? (user?.email ?? 'Pengurus Sarpras')
                                      : 'Walisantri / Ketua Kamar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  statusAuth,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'UID: ${user.uid}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _keluarAkun,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Keluar Akun / Ganti Peran'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Preferensi Petugas & Keamanan
                if (widget.isAdminSarpras) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profil Petugas & Keamanan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _namaPetugasController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Petugas Pemeriksa Default',
                            hintText: 'Contoh: Ust. Ahmad / Nukman',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PIN Otorisasi Daftar Pengurus Baru',
                            prefixIcon: Icon(Icons.pin_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Kartu Preferensi Sinkronisasi & Jadwal Pengingat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferensi Sinkronisasi & Pengingat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sinkronisasi Otomatis Cloud',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Sinkronkan data SQLite ke Firestore saat beranda dibuka',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _autoSync,
                        activeColor: const Color(0xFF0F766E),
                        onChanged: (val) => setState(() => _autoSync = val),
                      ),
                      if (widget.isAdminSarpras) ...[
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Pengingat Tenggat Peminjaman',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Notifikasi otomatis saat batas kembali alat santri tiba',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _pengingatPinjam,
                          activeColor: const Color(0xFF0F766E),
                          onChanged: (val) =>
                              setState(() => _pengingatPinjam = val),
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Alarm Jadwal Inspeksi Rutin',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Pengingat harian pemeriksaan fasilitas ruangan',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _pengingatInspeksi,
                          activeColor: const Color(0xFF0F766E),
                          onChanged: (val) =>
                              setState(() => _pengingatInspeksi = val),
                        ),
                        if (_pengingatInspeksi)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.alarm_rounded,
                              color: Color(0xFF0F766E),
                            ),
                            title: const Text(
                              'Jam Pengingat Inspeksi',
                              style: TextStyle(fontSize: 14),
                            ),
                            trailing: Chip(
                              label: Text(
                                _jamInspeksi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            onTap: _pilihJamInspeksi,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _simpanPengaturan,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }
}
