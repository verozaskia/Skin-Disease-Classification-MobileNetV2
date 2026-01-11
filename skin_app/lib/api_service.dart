import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = "http://10.33.112.171:8000";
  static const double lowConfidenceThreshold = 70.0;

  static Future<Map<String, dynamic>> predictImage(XFile image) async {
    final uri = Uri.parse("$baseUrl/predict");

    final request = http.MultipartRequest("POST", uri)
      ..files.add(
        await http.MultipartFile.fromPath("file", image.path),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    // Debug
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: $responseBody");

    if (response.statusCode != 200) {
      throw Exception(
          "API Error ${response.statusCode}: $responseBody");
    }

    final Map<String, dynamic> json = jsonDecode(responseBody);

    final double confidence =
        (json["Confidence"] as num).toDouble();

    // ⬇⬇⬇ INI BARIS THRESHOLD < 70%
    final bool isLowConfidence =
        confidence < lowConfidenceThreshold;

    return {
      "prediction": json["Prediction"],
      "confidence": confidence,
      "isLowConfidence": isLowConfidence,
    };
  }
}
