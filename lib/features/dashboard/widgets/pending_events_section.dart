import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:calendarit/models/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_event_dialogue.dart';

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
    return Column(
      children: events.map((event) {
        final hasValidTitle = event.title.trim().isNotEmpty;
        final hasValidStart = event.start != null;
        final hasValidEnd = event.end != null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text(event.title.isNotEmpty ? event.title : 'No title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.start != null ? 'Start: ${event.start}' : 'Start: -'),
                Text(event.end != null ? 'End: ${event.end}' : 'End: -'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _handleDecline(event.id),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    if (hasValidTitle && hasValidStart && hasValidEnd) {
                      await calendarRepository.addEventToGoogleCalendar(
                        accountId: accountIds.first,
                        title: event.title,
                        startDateTime: event.start!,
                        endDateTime: event.end!,
                        location: event.location,
                      );
                      await _markEventAccepted(event.id);
                    } else {
                      await showAddEventDialog(
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
                          await _markEventAccepted(event.id);
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleDecline(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc(eventId)
        .update({'status': 'declined'});
  }

  Future<void> _markEventAccepted(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc(eventId)
        .update({'status': 'accepted'});
  }
}
