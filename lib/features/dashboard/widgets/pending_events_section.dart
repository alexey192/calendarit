import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:calendarit/models/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../calendar_widgets/calendar_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_event_dialogue.dart';
import 'animated_event_card.dart';
import 'card_wrapper.dart';

class PendingEventsSection extends StatelessWidget {
  final List<CalendarEvent> events;
  final CalendarRepository calendarRepository;
  final List<String> accountIds;

  const PendingEventsSection({
    super.key,
    required this.events,
    required this.calendarRepository,
    required this.accountIds,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        CardWrapper(
          height: 400,
          child: events.isEmpty
              ? Center(
            child: Text(
              'No pending events',
              style: TextStyle(color: Colors.black45.withOpacity(0.8)),
            ),
          )
              : ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];

              final title = event.title.isNotEmpty ? event.title : 'Untitled Event';
              final location = event.location ?? 'No location';
              final date = event.start?.toString() ?? 'No date';

              return GestureDetector(
                onTap: () => _showManualEditDialog(context, event),
                child: AnimatedEventCard(
                  key: ValueKey(event.id),
                  eventId: event.id,
                  title: title,
                  date: date,
                  location: location,
                  onUpdateStatus: (status) async {
                    //log event we are updating
                    print('Updating event ${event.id} status to $status');
                    print('Event details: $title, $date, $location');

                    if (status == 'accepted') {
                      final hasValidTitle = event.title.trim().isNotEmpty;
                      final hasValidStart = event.start != null;
                      final hasValidEnd = event.end != null;

                      if (hasValidTitle && hasValidStart && hasValidEnd) {
                        await calendarRepository.addEventToGoogleCalendar(
                          accountId: accountIds.first,
                          title: event.title,
                          startDateTime: event.start!,
                          endDateTime: event.end!,
                          location: event.location,
                        );
                        await _updateStatus(event.id, 'accepted');
                        //call update google calendar
                        context.read<CalendarCubit>().loadEvents();
                      } else {
                        _showManualEditDialog(context, event);
                      }
                    } else {
                      await _updateStatus(event.id, status);
                    }
                  },

                  onEdit: () => _showManualEditDialog(context, event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showManualEditDialog(BuildContext context, CalendarEvent event) {
    showAddEventDialog(
      context: context,
      eventData: {
        'id': event.id,
        'title': event.title,
        'start': event.start,
        'end': event.end,
        'location': event.location,
      },
      accountIds: accountIds,
      onConfirm: ({
        required String accountId,
        required String title,
        required DateTime start,
        required DateTime end,
        String? location,
      }) async {
        await calendarRepository.addEventToGoogleCalendar(
          accountId: accountId,
          title: title,
          startDateTime: start,
          endDateTime: end,
          location: location,
        );
        await _updateStatus(event.id, 'accepted');
      },
    );
  }

  Future<void> _updateStatus(String eventId, String status) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc(eventId)
        .update({'status': status});
  }
}
