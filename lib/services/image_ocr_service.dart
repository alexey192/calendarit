import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class ImageOcrService {
  /// Opens file picker, performs OCR, and returns extracted text
  static Future<String?> performOcr() async {
    // Let user pick image file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) return null;

    final imagePath = result.files.single.path!;

    try {
      print("Performing OCR on image: $imagePath");
      final text = await FlutterTesseractOcr.extractText(imagePath);
      print("OCR result: $text");
      return text.trim().isEmpty ? null : text;
    } catch (e) {
      print("OCR failed: $e");
      return null;
    }
  }
}
