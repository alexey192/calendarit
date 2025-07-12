import 'dart:convert';
import 'dart:io';
import 'package:calendarit/app/const_values.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CloudVisionOcrService {
  static const _apiKey = ConstValues.googleApiKey;
  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';

  static Future<String?> extractTextFromImage() async {
    // Pick image
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return null;

    final imageFile = File(result.files.single.path!);
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
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
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final fullText = jsonResponse['responses']?[0]?['fullTextAnnotation']?['text'];
      return fullText?.trim();
    } else {
      print("Vision API failed: ${response.statusCode} ${response.body}");
      return null;
    }
  }
}
