import 'dart:convert';
import 'package:calendarit/app/const_values.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:http/http.dart' as http;

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

    print('EventParserService: Sending prompt to GPT-4:\n$prompt');
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
        'temperature': 0,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final content = jsonBody['choices']?[0]?['message']?['content'];
      if (content != null) {
        try {
          final parsed = jsonDecode(content);
          return EventSuggestion.fromJson(parsed);
        } catch (e) {
          print('Failed to parse JSON: $e');
        }
      }
    } else {
      print('GPT API error: ${response.statusCode}');
    }

    return null;
  }
}
