import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/preference_service.dart';
import 'main_navigation_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _memeriksaSesi = true;
  bool _sedangProses = false;

  @override
  void initState() {
    super.initState();
    _cekSesiLoginAktif();
  }

  Future<void> _cekSesiLoginAktif() async {
    final user = FirebaseAuth.instance.currentUser;
    final roleTersimpan = await PreferenceService.getRoleAktif();

    if (!mounted) return;
    if (user != null &&
        (roleTersimpan == 'admin' || roleTersimpan == 'warga')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainNavigationPage(isAdminSarpras: roleTersimpan == 'admin'),
        ),
      );
      return;
    }

    setState(() => _memeriksaSesi = false);
  }

  String _pesanErrorAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email atau kata sandi salah. Periksa kembali data login Anda.';
      case 'wrong-password':
        return 'Kata sandi yang dimasukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar sebagai akun pengurus.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'network-request-failed':
        return 'Gagal terhubung ke internet. Periksa koneksi jaringan Anda.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).';
    }
  }

  Future<void> _masukSebagaiWarga() async {
    if (_sedangProses) return;
    setState(() => _sedangProses = true);

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      await PreferenceService.setRoleAktif('warga');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationPage(isAdminSarpras: false),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Fallback jika Anonymous Auth belum diaktifkan di Console
      if (e.code == 'admin-restricted-operation') {
        await PreferenceService.setRoleAktif('warga');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationPage(isAdminSarpras: false),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_pesanErrorAuth(e))));
    } finally {
      if (mounted) setState(() => _sedangProses = false);
    }
  }

  void _tampilkanDialogAuthPengurus() {
    bool modeDaftar = false;
    bool sembunyiSandi = true;
    bool loadingDialog = false;
    String? pesanError;

    final namaController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          Future<void> prosesSubmit() async {
            final email = emailController.text.trim();
            final password = passwordController.text.trim();

            if (email.isEmpty || password.isEmpty) {
              setSheetState(() {
                pesanError = 'Email dan kata sandi wajib diisi.';
              });
              return;
            }

            setSheetState(() {
              loadingDialog = true;
              pesanError = null;
            });

            try {
              if (modeDaftar) {
                final pinBenar = await PreferenceService.getPinOtorisasi();
                if (pinController.text.trim() != pinBenar) {
                  setSheetState(() {
                    loadingDialog = false;
                    pesanError = 'PIN Otorisasi Asrama tidak sesuai.';
                  });
                  return;
                }

                final cred = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                final namaPetugas = namaController.text.trim();
                if (namaPetugas.isNotEmpty) {
                  await cred.user?.updateDisplayName(namaPetugas);
                  await PreferenceService.setNamaPetugas(namaPetugas);
                }
              } else {
                final cred = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                final displayName = cred.user?.displayName ?? '';
                final namaTersimpan = await PreferenceService.getNamaPetugas();
                if (namaTersimpan.isEmpty && displayName.isNotEmpty) {
                  await PreferenceService.setNamaPetugas(displayName);
                }
              }

              await PreferenceService.setRoleAktif('admin');
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MainNavigationPage(isAdminSarpras: true),
                ),
              );
            } on FirebaseAuthException catch (e) {
              setSheetState(() {
                loadingDialog = false;
                pesanError = _pesanErrorAuth(e);
              });
            } catch (e) {
              setSheetState(() {
                loadingDialog = false;
                pesanError = 'Gagal masuk: $e';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Autentikasi Pengurus Sarpras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk menggunakan akun Firebase terdaftar untuk mengelola aset asrama.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Masuk Akun')),
                          selected: !modeDaftar,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: !modeDaftar ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setSheetState(() {
                            modeDaftar = false;
                            pesanError = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Daftar Pengurus')),
                          selected: modeDaftar,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: modeDaftar ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setSheetState(() {
                            modeDaftar = true;
                            pesanError = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (modeDaftar) ...[
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Petugas',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Pengurus',
                      hintText: 'sarpras@asramaf.id',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: sembunyiSandi,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          sembunyiSandi
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setSheetState(() => sembunyiSandi = !sembunyiSandi),
                      ),
                    ),
                  ),
                  if (modeDaftar) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN Otorisasi Asrama',
                        hintText: 'Masukkan PIN keamanan pengurus',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (pesanError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x1FDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pesanError!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loadingDialog ? null : prosesSubmit,
                      icon: Icon(
                        modeDaftar
                            ? Icons.person_add_alt_1_rounded
                            : Icons.login_rounded,
                      ),
                      label: Text(
                        loadingDialog
                            ? 'Memproses...'
                            : (modeDaftar
                                  ? 'Daftar & Masuk'
                                  : 'Masuk ke Dashboard'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_memeriksaSesi) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0F766E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.domain_verification_rounded,
                      size: 56,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sarpras Asrama F',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sistem Manajemen Inventaris, Inspeksi,\n& Layanan Fasilitas Asrama',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),

                  // Kartu 1: Pengurus Sarpras
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _sedangProses
                          ? null
                          : _tampilkanDialogAuthPengurus,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1A0F766E),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Color(0xFF0F766E),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengurus Sarpras',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Login akun pengurus untuk kelola inventaris, inspeksi, peminjaman, & ekspor.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kartu 2: Walisantri / Ketua Kamar
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _sedangProses ? null : _masukSebagaiWarga,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1A2563EB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF2563EB),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Walisantri / Ketua Kamar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cek fasilitas ruangan, laporkan kerusakan, & kirim usulan kebutuhan barang.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
