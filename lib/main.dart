import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'views/home_page.dart';

void main() async {
  // 1. Mengunci binding Flutter agar inisialisasi async berjalan aman
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Menyalakan mesin Firebase berdasarkan file firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Menjalankan UI utama
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarpras Asrama F',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}
