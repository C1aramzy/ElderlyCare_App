import 'dart:convert';
import 'package:http/http.dart' as http;

class MmWaveService {
  static const String _baseUrl =
      'http://elderlym.atspace.cc/mmWave_Sensor';

  static Future<Map<String, dynamic>> getMotionData(
    int userId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/getMotionEvent_Clara.php?user_id=$userId',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Server returned status ${response.statusCode}',
      );
    }

    final dynamic decodedData = jsonDecode(response.body);

    if (decodedData is! Map<String, dynamic>) {
      throw Exception('Invalid response from server.');
    }

    if (decodedData['success'] != true) {
      throw Exception(
        decodedData['message'] ?? 'Unable to retrieve sensor data.',
      );
    }

    return decodedData;
  }
}