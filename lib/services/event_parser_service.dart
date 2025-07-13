import 'dart:convert';
import 'package:calendarit/app/const_values.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:calendarit/models/parsed_event_result.dart';
import 'package:http/http.dart' as http;

class GptEventResponse {
  final Map<String, dynamic>? parsedJson;
  final String rawGptMessage;

  GptEventResponse({required this.rawGptMessage, this.parsedJson});
}

class EventParserService {
  static const _gptEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const _apiKey = ConstValues.openAiToken;

  static Future<EventSuggestion?> parseEventFromText(String rawText) async {
    final currentYear = DateTime.now().year;

    final prompt = '''You are an AI that extracts structured event information from free text that was automatically recognized on the photo. This could be a flyer or a poster about some event, or a text message that contains information about an event.
Maybe there is no event at all, in which case you should return null.
Return a single valid JSON object in the format below. If any field is missing in the input, fill with null or empty string.
If the year is not specified, use $currentYear or the next if this date has already passed. If the time is not specified, set "isTimeSpecified" to false and set start and end to null.

{
  "title": string,
  "location": string,
  "start": ISO 8601 timestamp or null,
  "end": ISO 8601 timestamp or null,
  "isTimeSpecified": boolean,
  "description": string,
  "category": string (e.g., "meeting", "webinar", "conference", "deadline", "party", "concert", "other")
}

Text:
"""$rawText"""
''';

    final result = await _callGptAndParse(prompt);
    return result?.parsedJson != null ? EventSuggestion.fromJson(result!.parsedJson!) : null;
  }

  static Future<ParsedEventResult?> parseEventFromTextSmart(String rawText) async {
    final currentYear = DateTime.now().year;

    final prompt = '''You are an AI chat bot assistant that helps users schedule events based on free-form messages. The user might give full or partial event information, or no event at all.
Extract a structured event as JSON if you can. If any details are missing (like time or location), return them as null or empty string.

Use $currentYear or next if the year is missing and the date has already passed.
If time is not specified, set "isTimeSpecified" to false and set start and end to null.
If the user provides a category, use it; otherwise, default to "other".
If the user does not chat about scheduling events, just chat naturally and friendly with the user and I will use this response, and do not try to extract events, 
but still encourage them to provide more details about any events they want to schedule or upload an image with event info to the chat.

Format in case you found an event:
{
  "title": string,
  "location": string,
  "start": ISO 8601 timestamp or null,
  "end": ISO 8601 timestamp or null,
  "isTimeSpecified": boolean,
  "description": string,
  "category": string
}

User message:
"""$rawText"""
''';

    final result = await _callGptAndParse(prompt);
    if (result == null) return null;

    if (result.parsedJson != null) {
      final suggestion = EventSuggestion.fromJson(result.parsedJson!);

      final isComplete = [
        suggestion.title,
        suggestion.location,
        suggestion.description,
        suggestion.category,
      ].every((field) => field.trim().isNotEmpty);

      if (isComplete && suggestion.start != null && suggestion.end != null) {
        return ParsedEventResult(event: suggestion.toJson());
      }
    }

    return ParsedEventResult(
      missingInfoPrompt: result.rawGptMessage.trim(),
    );
  }

  static Future<GptEventResponse?> _callGptAndParse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_gptEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'system', 'content': 'Extract structured event information from the given text.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final content = jsonBody['choices']?[0]?['message']?['content'];
        if (content != null) {
          try {
            final parsedJson = jsonDecode(content);
            return GptEventResponse(rawGptMessage: content, parsedJson: parsedJson);
          } catch (_) {
            // Not JSON — just return GPT reply as fallback
            return GptEventResponse(rawGptMessage: content);
          }
        }
      } else {
        print('GPT API error: ${response.statusCode} | ${response.body}');
      }
    } catch (e) {
      print('GPT call failed: $e');
    }

    return null;
  }
}
