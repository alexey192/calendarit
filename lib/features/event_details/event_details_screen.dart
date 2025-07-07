import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event: $eventId')),
      body: const Center(
        child: Text('Event Details Here'),
      ),
    );
  }
}
