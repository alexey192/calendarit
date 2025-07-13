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

  static List<String> getMissingRequiredFields(Map<String, dynamic> event) {
    final requiredFields = ['title', 'start', 'end'];
    return requiredFields.where((field) {
      final value = event[field];
      return value == null || (value is String && value.trim().isEmpty);
    }).toList();
  }

  static Future<types.Message> handleUserMessage(String inputText, {Map<String, dynamic>? previousEvent}) async {
    final result = await EventParserService.parseEventFromTextSmart(inputText, previousEvent: previousEvent);

    if (result == null) {
      return buildTextMessage(
        'Oops, something went wrong while analyzing your message. Please try again later.',
      );
    }

    print('Parsed event result: ${result.toJson()}');

    if (result.event != null && result.event!.hasEvent) {
      final missingFields = getMissingRequiredFields(result.event!.event!);

      print('Missing required fields: $missingFields');

      if (missingFields.isEmpty) {
        final suggestion = EventSuggestion.fromJson(result.event!.event!);
        final lines = [
          'Got it! Here’s what I understood from your message:',
          '- Title: ${suggestion.title}',
          '- Start: ${suggestion.start}',
          '- End: ${suggestion.end}',
          if (suggestion.location != null && suggestion.location!.isNotEmpty)
            '- Location: ${suggestion.location}',
          if (suggestion.description != null && suggestion.description!.isNotEmpty)
            '- Description: ${suggestion.description}',
        ];

        var successResponse =  buildTextMessage(lines.join('\n'));
        successResponse.metadata?['isSuccess'] = true;
        successResponse.metadata?['eventSuggestion'] = EventSuggestion(
          title: suggestion.title,
          location: suggestion.location,
          start: suggestion.start,
          end: suggestion.end,
          isTimeSpecified: suggestion.isTimeSpecified,
          description: suggestion.description,
          category: suggestion.category,
        );

        return successResponse;
      } else {
        final lines = <String>[
          'Here’s what I understood so far:',
          '- Title: ${result.event!.event!['title'] ?? '_missing_'}',
          '- Start: ${result.event!.event!['start'] ?? '_missing_'}',
          '- End: ${result.event!.event!['end'] ?? '_missing_'}',
          '',
          'Could you provide the missing info: ${missingFields.join(', ')}?',
        ];

        return buildTextMessage(lines.join('\n'));
      }
    }

    return buildTextMessage(result.reply.isEmpty ?
    "I'm here to help! Want to add an event or share a flyer?" 
    : result.reply);
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

  static types.TextMessage buildTextMessage(String text) {
    return types.TextMessage(
      author: assistant,
      id: Random().nextInt(999999).toString(),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      metadata: <String, dynamic>{},
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
