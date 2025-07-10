import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'card_wrapper.dart';
import 'compact_event_card.dart';

class HighlightsSection extends StatelessWidget {
  final String uid;

  const HighlightsSection({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Highlights',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9))),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('events')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CardWrapper(
                height: 350,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return CardWrapper(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note_rounded,
                        size: 48, color: Colors.grey.withOpacity(0.6)),
                    const SizedBox(height: 16),
                    Text('No events to highlight',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            return CardWrapper(
              height: 350,
              padding: const EdgeInsets.all(16),
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
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onDecline: () {
                          doc.reference.update({'status': 'declined'});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event declined!'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onEdit: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit functionality coming soon!'),
                              backgroundColor: Colors.blue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  }
              ),
            );
          },
        ),
      ],
    );
  }
}
