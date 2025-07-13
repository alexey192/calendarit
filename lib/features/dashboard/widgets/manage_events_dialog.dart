import 'package:calendarit/models/calendar_event.dart';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/animated_event_card.dart';
import '../widgets/add_event_dialogue.dart';

class ManageEventsDialog extends StatefulWidget {
  final List<CalendarEvent> events;
  final CalendarRepository calendarRepository;
  final List<String> accountIds;

  const ManageEventsDialog({
    super.key,
    required this.events,
    required this.calendarRepository,
    required this.accountIds,
  });

  @override
  State<ManageEventsDialog> createState() => _ManageEventsDialogState();
}

class _ManageEventsDialogState extends State<ManageEventsDialog> {
  late List<CalendarEvent> acceptedEvents;
  late List<CalendarEvent> pendingEvents;
  late List<CalendarEvent> declinedEvents;

  @override
  void initState() {
    super.initState();
    _splitEvents();
  }

  void _splitEvents() {
    acceptedEvents = widget.events.where((e) => e.status?.toLowerCase() == 'accepted').toList();
    pendingEvents = widget.events.where((e) => e.status?.toLowerCase() == 'pending').toList();
    declinedEvents = widget.events.where((e) => e.status?.toLowerCase() == 'declined' || e.status?.toLowerCase() == 'rejected').toList();
  }

  Future<void> _updateEventStatus(CalendarEvent event, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .doc(event.id)
        .update({'status': newStatus});

    setState(() {
      acceptedEvents.removeWhere((e) => e.id == event.id);
      pendingEvents.removeWhere((e) => e.id == event.id);
      declinedEvents.removeWhere((e) => e.id == event.id);

      final updatedEvent = CalendarEvent(
        id: event.id,
        title: event.title,
        start: event.start,
        end: event.end,
        location: event.location,
        description: event.description,
        status: newStatus,
        category: event.category,
      );

      switch (newStatus.toLowerCase()) {
        case 'accepted':
          acceptedEvents.add(updatedEvent);
          break;
        case 'pending':
          pendingEvents.add(updatedEvent);
          break;
        case 'declined':
        case 'rejected':
          declinedEvents.add(updatedEvent);
          break;
      }
    });
  }

  void _showEditDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEventDialog(
          eventData: {
            'id': event.id,
            'title': event.title,
            'start': event.start,
            'end': event.end,
            'location': event.location,
            'description': event.description,
          },
          accountIds: widget.accountIds,
          onConfirm: ({
            required String accountId,
            required String title,
            required DateTime start,
            required DateTime end,
            String? location,
          }) async {
            await widget.calendarRepository.addEventToGoogleCalendar(
              accountId: accountId,
              title: title,
              startDateTime: start,
              endDateTime: end,
              location: location,
            );
            await _updateEventStatus(event, 'accepted');
          },
        );
      },
    );
  }

  Widget _buildCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6), // space between cards
      child: SizedBox(
        width: 300, // fix width same as drag feedback
        child: AnimatedEventCard(
          eventId: event.id,
          title: event.title.isNotEmpty ? event.title : 'Untitled Event',
          date: event.start != null
              ? '${event.start!.toLocal().toString().split(' ')[0]}'
              : 'No date',
          location: event.location ?? 'No location',
          onUpdateStatus: (status) async => await _updateEventStatus(event, status),
          onEdit: () => _showEditDialog(event),
          showActionButtons: false, // no buttons in Manage dialog
          category: event.category ?? '',
        ),
      ),
    );
  }

  Widget _buildColumn(String title, List<CalendarEvent> events, Color color, String status) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: DragTarget<CalendarEvent>(
          onWillAccept: (event) => event?.status?.toLowerCase() != status.toLowerCase(),
          onAccept: (event) => _updateEventStatus(event, status),
          builder: (context, candidateData, rejectedData) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: events.map((event) {
                      return Draggable<CalendarEvent>(
                        data: event,
                        feedback: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(width: 300, child: _buildCard(event)),
                        ),
                        childWhenDragging: Opacity(opacity: 0.5, child: _buildCard(event)),
                        child: _buildCard(event),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0076BC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Manage Events',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildColumn('Accepted', acceptedEvents, Colors.green.shade700, 'accepted'),
                  _buildColumn('Pending', pendingEvents, Colors.orange.shade700, 'pending'),
                  _buildColumn('Declined', declinedEvents, Colors.red.shade700, 'declined'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
