import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Pulls from --dart-define-from-file=../.env (BACKEND_URL) or defaults to local dev
  static const String _hostUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get baseUrl => '$_hostUrl/api/v1';

  static Future<Map<String, dynamic>> sendAudioMessage(String filePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/tutor/chat'));
    
    // Attach the audio file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}