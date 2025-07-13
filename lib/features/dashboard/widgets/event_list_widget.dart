import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../event_details/event_details_screen.dart';
import 'event_card.dart';

class EventListWidget extends StatelessWidget {
  const EventListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final eventsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('events')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: eventsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No events found"));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final eventId = docs[index].id;

            return EventCard(
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              location: data['location'] ?? '',
              date: data['date'] ?? '',
              status: data['status'] ?? 'pending',
              source: data['source'] ?? '',
              category: data['tag'] ?? '',
              seen: data['seen'] ?? false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailsScreen(eventId: eventId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
