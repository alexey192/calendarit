import 'package:calendarit/features/dashboard/widgets/add_event_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:calendarit/services/cloud_vision_ocr_service.dart';
import 'package:calendarit/services/event_parser_service.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiImageHandler {
  static final ImagePicker _picker = ImagePicker();

  /// Used in the chat UI flow — converts selected image to an image message (but doesn't process it)
  static Future<types.ImageMessage?> pickAndConvertImageToMessage(types.User user) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      return types.ImageMessage(
        author: user,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: image.name,
        size: await image.length(),
        uri: image.path,
      );
    } catch (e) {
      debugPrint('Image picker error: $e');
      return null;
    }
  }

  /// Used in button flow — runs full OCR + GPT + event parsing + event modal
  static Future<bool> handleOcrAndEventFlow(
      BuildContext context,
      List<String> accountIds,
      CalendarRepository calendarRepository,
      ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      print('Starting AI OCR Event Flow...');
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );
      print('Image selected: ${image?.path}'); // Debugging line to check image selection
      if (image == null) return false;

      // Step 1: Show loading for OCR
      _showLoadingDialog(context, 'Extracting data from your image...');

      final bytes = await image.readAsBytes();
      if (bytes == null) {
        debugPrint('Image bytes are null — possibly a web bug');
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to read image data.')));
        return false;
      }

      print('Image bytes length: ${bytes.length}'); // Debugging line to check byte size
      final ocrText = await CloudVisionOcrService.extractTextFromImageBytes(bytes);
      print('OCR Text: $ocrText'); // Debugging line to check OCR output

      navigator.pop();

      if (ocrText == null || ocrText.trim().isEmpty) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to extract text from image.')));
        return false;
      }

      // Step 2: Show loading for GPT
      _showLoadingDialog(context, 'Parsing event from extracted text...');
      final suggestion = await EventParserService.parseEventFromText(ocrText);
      navigator.pop();

      if (suggestion == null) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to extract event from text.')));
        return false;
      }

      final eventData = {
        'title': suggestion.title,
        'location': suggestion.location,
        'start': suggestion.start,
        'end': suggestion.end,
        'description': suggestion.description,
      };

      await showAddEventDialog(
        context: context,
        eventData: eventData,
        accountIds: accountIds,
        onConfirm: ({
          required String accountId,
          required String title,
          required DateTime start,
          required DateTime end,
          String? location,
        }) async {
          final newSuggestion = EventSuggestion(
            title: title,
            location: location ?? '',
            start: start,
            end: end,
            isTimeSpecified: suggestion.isTimeSpecified,
            description: suggestion.description,
            category: suggestion.category,
          );

          await _saveSuggestedEventToFirestore(newSuggestion);

          await calendarRepository.addEventToGoogleCalendar(
            accountId: accountId,
            title: title,
            startDateTime: start,
            endDateTime: end,
            location: location,
          );
        },
      );

      return true;
    } catch (e) {
      debugPrint('AI OCR Event Flow error: $e');
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Unexpected error during event processing.')));
      return false;
    }
  }

  static Future<void> _showLoadingDialog(BuildContext context, String label) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  static Future<void> _saveSuggestedEventToFirestore(
      EventSuggestion suggestion, {
        String status = 'pending',
      }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc();

    await docRef.set({
      'title': suggestion.title,
      'location': suggestion.location,
      'start': suggestion.start,
      'end': suggestion.end,
      'isTimeSpecified': suggestion.isTimeSpecified,
      'description': suggestion.description,
      'category': suggestion.category,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
