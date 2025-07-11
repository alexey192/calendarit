import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          'Pending events',
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
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return CardWrapper(
                height: 200,
                child: Center(
                  child: Text(
                    'No events to highlight',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
                  final data = docs[index].data() as Map<String, dynamic>;
                  final doc = docs[index];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: CompactEventCard(
                      title: data['title'] ?? 'Untitled Event',
                      date: data['date'] ?? 'No date',
                      location: data['location'] ?? 'No location',
                      onAccept: () {
                        doc.reference.update({'status': 'accepted'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event accepted!'),
                            backgroundColor: Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onDecline: () {
                        doc.reference.update({'status': 'declined'});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event declined!'),
                            backgroundColor: Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onEdit: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit functionality coming soon!'),
                            backgroundColor: Color(0xFF2563EB),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onTap: () {
                        // TODO: show dialog with details?
                      },
                    ),
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
