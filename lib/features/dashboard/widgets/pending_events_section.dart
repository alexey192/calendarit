import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'animated_event_card.dart';
import 'card_wrapper.dart';
import 'compact_event_card.dart';

class PendingEventsSection extends StatelessWidget {
  const PendingEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('events')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return CardWrapper(
                height: 400,
                child: Center(
                  child: Text(
                    'No pending events',
                    style: TextStyle(color: Colors.black45.withOpacity(0.8)),
                  ),
                ),
              );
            }

            return CardWrapper(
              height: 400,
              child: ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return AnimatedEventCard(
                    key: ValueKey(doc.id),
                    eventId: doc.id,
                    title: data['title'] ?? 'Untitled Event',
                    date: data['date'] ?? 'No date',
                    location: data['location'] ?? 'No location',
                    onUpdateStatus: (status) async {
                      await doc.reference.update({'status': status});
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
