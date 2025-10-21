import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = 'dylep5ibz';
  final String uploadPreset = 'bhajans_preset';

  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'bhajan_lyrics'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (data['secure_url'] != null) return data['secure_url'];
    throw Exception('Failed to upload image: ${data['error'] ?? data}');
  }

  Future<String> uploadAudio(Uint8List bytes, String fileName) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'bhajans' // target folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (data['secure_url'] != null) return data['secure_url'];
    throw Exception('Failed to upload audio: ${data['error'] ?? data}');
  }
}
