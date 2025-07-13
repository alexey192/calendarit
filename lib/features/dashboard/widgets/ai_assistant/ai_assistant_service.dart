import 'dart:io';
import 'package:calendarit/services/firestore_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import '../../../../services/cloud_vision_ocr_service.dart';
import '../../../../services/event_parser_service.dart';
import 'package:flutter/material.dart';

class AiAssistantService {
  final _uuid = const Uuid();

  Future<types.TextMessage?> handleUserMessage(String text) async {
    final suggestion = await EventParserService.parseEventFromTextSmart(text);

    if (suggestion != null && suggestion.event != null) {
      await FirestoreUtils.saveEventWithPendingStatus(suggestion.event!);

      return _assistant("Got it! I've added the event to your calendar as pending.");
    } else if (suggestion != null && suggestion.missingInfoPrompt != null) {
      return _assistant(suggestion.missingInfoPrompt!);
    }

    return _assistant("Thanks! Let me know if you want to extract info from a flyer too.");
  }

  Future<types.TextMessage?> handleAttachmentFlow() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      return _assistant("Failed to load the image file. Please try again.");
    }

    final extractedText = await CloudVisionOcrService.extractTextFromImageBytes(file.bytes!);

    if (extractedText == null || extractedText.trim().isEmpty) {
      return _assistant("I couldn't read anything from the image. Try a clearer photo.");
    }

    final suggestion = await EventParserService.parseEventFromTextSmart(extractedText);

    if (suggestion != null && suggestion.event != null) {
      await FirestoreUtils.saveEventWithPendingStatus(suggestion.event!);
      return _assistant("I extracted the event from the image and saved it as pending!");
    } else if (suggestion != null && suggestion.missingInfoPrompt != null) {
      return _assistant(suggestion.missingInfoPrompt!);
    }

    return _assistant("I saw some text but couldn't detect an event. Try a different image?");
  }

  types.TextMessage _assistant(String text) {
    return types.TextMessage(
      id: _uuid.v4(),
      author: const types.User(id: 'assistant'),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
