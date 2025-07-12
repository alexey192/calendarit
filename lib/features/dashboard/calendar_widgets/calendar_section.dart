import 'package:calendarit/features/dashboard/widgets/card_wrapper.dart';
import 'package:calendarit/models/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'calendar_cubit.dart';
import 'calendar_state.dart';


class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CalendarError) {
          return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.white)));
        } else if (state is CalendarLoaded) {
          return CardWrapper(
            height: 400,
            child: SfCalendar(
              view: CalendarView.week,
              todayHighlightColor: Color(0xFF0076BC),
              cellBorderColor: Color(0xFF103750).withOpacity(0.4),
              headerStyle: const CalendarHeaderStyle(
                backgroundColor: Colors.transparent,
                textAlign: TextAlign.center,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              selectionDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Color(0xFF0076BC), width: 2),
              ),
              dataSource: _CalendarDataSource(state.events),
              showNavigationArrow: true,
              //showTodayButton: true,
              allowDragAndDrop: false,
              allowAppointmentResize: true,
            ),
          );
        }
        return const SizedBox(height: 400);
      },
    );
  }
}

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<CalendarEvent> events) {
    appointments = events;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;
  @override
  DateTime getEndTime(int index) => appointments![index].endTime;
  @override
  String getSubject(int index) => appointments![index].title;
}
