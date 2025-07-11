

import 'package:calendarit/models/calendar_event.dart';

abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;
  CalendarLoaded(this.events);
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);
}
