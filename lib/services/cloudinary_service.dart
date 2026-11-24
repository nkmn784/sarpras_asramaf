import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Pertahankan cloudName dan uploadPreset asli milikmu di bawah ini:
  static const String cloudName = 'qytkinqe';
  static const String uploadPreset = 'ml_default';

  static Future<String?> uploadFoto(XFile imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final bytes = await imageFile.readAsBytes();
      final namaFile = imageFile.name.isNotEmpty ? imageFile.name : 'foto.jpg';

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: namaFile),
        );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      print('Gagal upload ke Cloudinary: $e');
      return null;
    }
  }
}
