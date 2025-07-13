import 'dart:convert';
import 'dart:typed_data';
import 'package:calendarit/app/const_values.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CloudVisionOcrService {
  static const _apiKey = ConstValues.googleApiKey;
  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';

  static Future<String?> extractTextFromImage() async {
    print("CloudVisionOcrService: Starting OCR process...");

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final imageBytes = await pickedFile.readAsBytes();;
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

  static Future<String?> extractTextFromImageBytes(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);

    print("CloudVisionOcrService: Base64 encoded image size: ${base64Image.length} characters");

    final requestPayload = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION'},
          ],
        },
      ],
    };

    try {
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

      if (response.statusCode == 200) {
        print('OCR API response: ${response.body.substring(0, 100)}...');
        final data = jsonDecode(response.body);
        return data['responses']?[0]?['fullTextAnnotation']?['text'];
      } else {
        print('OCR API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('OCR exception: $e');
      return null;
    }
  }
}
