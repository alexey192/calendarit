import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? location;
  final String? description;
  final String? status;

  CalendarEvent({
    required this.id,
    required this.title,
    this.start,
    this.end,
    this.location,
    this.description,
    this.status,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> data, String id) {
    final rawStart = data['start'];
    final rawEnd = data['end'];

    DateTime? parsedStart;
    DateTime? parsedEnd;

    try {
      if (rawStart is Timestamp) parsedStart = rawStart.toDate();
      else if (rawStart is String) parsedStart = DateTime.tryParse(rawStart);
    } catch (_) {}

    try {
      if (rawEnd is Timestamp) parsedEnd = rawEnd.toDate();
      else if (rawEnd is String) parsedEnd = DateTime.tryParse(rawEnd);
    } catch (_) {}

    if (kDebugMode && (parsedStart == null || parsedEnd == null)) {
      debugPrint('⚠️ Event "$id" has invalid or missing start/end times: start=$rawStart, end=$rawEnd');
    }

    return CalendarEvent(
      id: id,
      title: data['title'] ?? '',
      start: parsedStart,
      end: parsedEnd,
      location: data['location'],
      description: data['description'],
      status: data['status'],
    );
  }
}
