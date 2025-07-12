import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'animated_event_card.dart';
import 'card_wrapper.dart';

/// The dialog widget extracted for editing events.
class EditEventDialog extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditEventDialog({super.key, required this.doc});

  @override
  State<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  late final TextEditingController titleController;
  late final TextEditingController locationController;
  late final TextEditingController dateController;
  late final TextEditingController descriptionController;
  late final TextEditingController tagController;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    titleController = TextEditingController(text: data['title']);
    locationController = TextEditingController(text: data['location']);
    dateController = TextEditingController(text: data['date']);
    descriptionController = TextEditingController(text: data['description']);
    tagController = TextEditingController(text: data['tag']);
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    tagController.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    await widget.doc.reference.update({
      'title': titleController.text.trim(),
      'location': locationController.text.trim(),
      'date': dateController.text.trim(),
      'description': descriptionController.text.trim(),
      'tag': tagController.text.trim(),
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
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
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9ECDEC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Main widget displaying the list of pending events
class PendingEventsSection extends StatelessWidget {
  const PendingEventsSection({super.key});

  void _showEditEventDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      barrierColor: Colors.black87.withOpacity(0.5),
      builder: (_) => EditEventDialog(doc: doc),
    );
  }

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
                    onTap: () => _showEditEventDialog(context, doc),
                    child: AnimatedEventCard(
                      key: ValueKey(doc.id),
                      eventId: doc.id,
                      title: data['title'] ?? 'Untitled Event',
                      date: data['date'] ?? 'No date',
                      location: data['location'] ?? 'No location',
                      onUpdateStatus: (status) async {
                        await doc.reference.update({'status': status});
                      },
                      onEdit: () => _showEditEventDialog(context, doc),// Edit button callback
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
