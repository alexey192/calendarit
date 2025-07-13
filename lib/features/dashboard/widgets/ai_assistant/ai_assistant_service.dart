import 'dart:math';
import 'package:calendarit/models/parsed_event_result.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:calendarit/services/event_parser_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import '../../../../services/cloud_vision_ocr_service.dart';
import '../../../../services/firestore_utils.dart';

class AiAssistantService {
  final _uuid = const Uuid();
  static final types.User assistant = const types.User(id: 'assistant', firstName: 'AI Assistant');

  static Future<types.TextMessage> handleUserMessage(String inputText) async {
    final result = await EventParserService.parseEventFromTextSmart(inputText);

    if (result == null) {
      return _buildTextMessage(
        'Oops, something went wrong while analyzing your message. Please try again later.',
      );
    }

    // If there's a parsed event, format the summary
    final event = result.event;
    if (event != null) {
      print('Parsed event: ${event.toJson()}');
      final suggestion = EventSuggestion.fromJson(event.event!);
      final lines = [
        result.reply.trim(),
        '',
        'Here’s what I understood from your message:',
        '',
        '**Title**: ${suggestion.title}',
        '**Location**: ${suggestion.location}',
        '**Time**: ${_formatTime(suggestion)}',
        '**Category**: ${suggestion.category}',
        '',
        'Want me to add it to your calendar?',
      ];

      return _buildTextMessage(lines.join('\n').trim());
    }

    // If no event, just return the smart reply
    return _buildTextMessage(result.reply.trim());
  }


  static String _formatTime(EventSuggestion suggestion) {
    if (!suggestion.isTimeSpecified) return 'Time not specified';

    if (suggestion.start != null && suggestion.end != null) {
      return '${suggestion.start} – ${suggestion.end}';
    } else if (suggestion.start != null) {
      return '${suggestion.start}';
    } else {
      return 'No specific time';
    }
  }

  static types.TextMessage _buildTextMessage(String text) {
    return types.TextMessage(
      author: assistant,
      id: Random().nextInt(999999).toString(),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
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

    if (suggestion != null && suggestion.event != null && suggestion.event!.event != null) {
      await FirestoreUtils.saveEventWithPendingStatus(suggestion.event!.event!);
      return _assistant("I extracted the event from the image and saved it as pending!");
    } else if (suggestion != null && suggestion.event?.missingInfoPrompt != null) {
      return _assistant(suggestion.event!.missingInfoPrompt!);
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
