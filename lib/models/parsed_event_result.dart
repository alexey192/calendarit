class ParsedEventResult {
  final Map<String, dynamic>? event;
  final String? missingInfoPrompt;

  const ParsedEventResult({this.event, this.missingInfoPrompt});

  factory ParsedEventResult.fromJson(Map<String, dynamic> json) {
    return ParsedEventResult(
      event: json['event'] as Map<String, dynamic>?,
      missingInfoPrompt: json['missingInfoPrompt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'missingInfoPrompt': missingInfoPrompt,
    };
  }

  bool get hasEvent => event != null && event!.isNotEmpty;
}

class SmartEventParseResult {
  final String reply;
  final ParsedEventResult? event;

  SmartEventParseResult({required this.reply, this.event});

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'event': event?.toJson(),
    };
  }

  factory SmartEventParseResult.fromJson(Map<String, dynamic> json) {
    return SmartEventParseResult(
      reply: json['reply'] ?? '',
      event: json['event'] != null ? ParsedEventResult.fromJson(json['event']) : null,
    );
  }
}
