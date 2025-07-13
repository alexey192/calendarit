import 'dart:convert';
import 'dart:typed_data';
import 'package:calendarit/app/const_values.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CloudVisionOcrService {
  static const _apiKey = ConstValues.googleApiKey;
  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';

  static Future<String?> extractTextFromImage() async {
    print("CloudVisionOcrService: Starting OCR process...");
    // Pick image
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    print("CloudVisionOcrService: User picked image: ${result?.files.single.name}");
    if (result == null || result.files.single.bytes == null) return null;

    final Uint8List imageBytes = result.files.single.bytes!;
    final String base64Image = base64Encode(imageBytes);

    print("CloudVisionOcrService: Base64 encoded image size: ${base64Image.length} characters");

    final requestBody = jsonEncode({
      "requests": [
        {
          "image": {
            "content": base64Image,
          },
          "features": [
            {"type": "DOCUMENT_TEXT_DETECTION"}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse("$_endpoint?key=$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    print("CloudVisionOcrService: Response status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final text = jsonResponse['responses']?[0]?['fullTextAnnotation']?['text'];
      return text?.trim();
    } else {
      print("Vision API failed: ${response.statusCode} ${response.body}");
      return null;
    }
  }
}
