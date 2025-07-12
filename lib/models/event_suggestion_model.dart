class EventSuggestion {
  final String title;
  final String location;
  final DateTime? start;
  final DateTime? end;
  final bool isTimeSpecified;
  final String description;
  final String category;

  EventSuggestion({
    required this.title,
    required this.location,
    required this.start,
    required this.end,
    required this.isTimeSpecified,
    required this.description,
    required this.category,
  });

  factory EventSuggestion.fromJson(Map<String, dynamic> json) {
    return EventSuggestion(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      start: json['start'] != null ? DateTime.tryParse(json['start']) : null,
      end: json['end'] != null ? DateTime.tryParse(json['end']) : null,
      isTimeSpecified: json['isTimeSpecified'] ?? false,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}
