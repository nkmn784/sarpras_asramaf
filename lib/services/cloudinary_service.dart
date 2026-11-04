import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudinaryService {
  // TODO: Ganti dengan data akun Cloudinary Anda nanti
  static const String cloudName = 'qytkinqe';
  static const String uploadPreset = 'ml_default';

  // Fungsi untuk melempar file foto dari SQLite ke Cloudinary
  static Future<String?> uploadFoto(File imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        // Jika berhasil, kembalikan URL link foto yang sudah online
        return data['secure_url'];
      } else {
        print('Gagal upload: ${data['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan koneksi: $e');
      return null;
    }
  }
}
