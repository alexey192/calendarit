import 'package:calendarit/models/calendar_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calendar_state.dart';
import 'calendar_repository.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final CalendarRepository repository;

  CalendarCubit(this.repository) : super(CalendarInitial());

  Future<void> loadEvents() async {
    emit(CalendarLoading());
    try {
      final events = await repository.fetchCalendarEvents();
      emit(CalendarLoaded(events));
    } catch (e, stack) {
      debugPrint('Calendar load failed: $e');
      debugPrintStack(stackTrace: stack);
      emit(CalendarError('Failed to load calendar events'));
    }
  }

  List<CalendarEvent> get events {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      return currentState.events;
    }
    return [];
  }

}
