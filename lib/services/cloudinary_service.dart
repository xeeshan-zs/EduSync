
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_config.dart';

class CloudinaryService {
  final String _cloudName = AppConfig.cloudinaryCloudName;
  final String _uploadPreset = AppConfig.cloudinaryUploadPreset;
  
  Future<String?> uploadImage(Uint8List fileBytes) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dwihjvj2p/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: 'upload.jpg'));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'];
      } else {
        print('Cloudinary Error: ${jsonMap['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}
