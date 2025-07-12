import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'animated_event_card.dart';
import 'card_wrapper.dart';

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
              .limit(5)
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

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87.withOpacity(0.5),
                        builder: (context) {
                          final titleController = TextEditingController(text: data['title']);
                          final locationController = TextEditingController(text: data['location']);
                          final dateController = TextEditingController(text: data['date']);
                          final descriptionController = TextEditingController(text: data['description']);
                          final tagController = TextEditingController(text: data['tag']);

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420), // 💡 sets dialog width
                              child: Material(
                                borderRadius: BorderRadius.circular(20),
                                clipBehavior: Clip.antiAlias,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: StatefulBuilder(
                                    builder: (context, setState) => SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Edit Event',
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () => Navigator.of(context).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          _buildTextField('Title', titleController),
                                          const SizedBox(height: 12),
                                          _buildTextField('Location', locationController),
                                          const SizedBox(height: 12),
                                          _buildTextField('Date & Time', dateController),
                                          const SizedBox(height: 12),
                                          _buildTextField('Description', descriptionController, maxLines: 3),
                                          const SizedBox(height: 12),
                                          _buildTextField('Tag', tagController),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                await doc.reference.update({
                                                  'title': titleController.text.trim(),
                                                  'location': locationController.text.trim(),
                                                  'date': dateController.text.trim(),
                                                  'description': descriptionController.text.trim(),
                                                  'tag': tagController.text.trim(),
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.deepPurpleAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                              child: const Text(
                                                'Save Changes',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: AnimatedEventCard(
                      key: ValueKey(doc.id),
                      eventId: doc.id,
                      title: data['title'] ?? 'Untitled Event',
                      date: data['date'] ?? 'No date',
                      location: data['location'] ?? 'No location',
                      onUpdateStatus: (status) async {
                        await doc.reference.update({'status': status});
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

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.6),
        ),
      ),
    );
  }
}
