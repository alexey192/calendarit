import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEventDialog extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final List<String> accountIds;
  final void Function({
  required String accountId,
  required String title,
  required DateTime start,
  required DateTime end,
  String? location,
  }) onConfirm;

  const AddEventDialog({
    super.key,
    required this.eventData,
    required this.accountIds,
    required this.onConfirm,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  DateTime? _start;
  DateTime? _end;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['title'] ?? '');
    _locationController = TextEditingController(text: widget.eventData['location'] ?? '');
    _start = widget.eventData['start'] is DateTime ? widget.eventData['start'] : null;
    _end = widget.eventData['end'] is DateTime ? widget.eventData['end'] : null;
    _selectedAccountId = widget.accountIds.isNotEmpty ? widget.accountIds.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = dateTime;
      } else {
        _end = dateTime;
      }
    });
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
          _start != null &&
          _end != null &&
          _selectedAccountId != null &&
          _start!.isBefore(_end!);

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0076BC), width: 1.6),
      ),
    );
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add to Google Calendar',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Account Picker
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    onChanged: (value) => setState(() => _selectedAccountId = value),
                    items: widget.accountIds
                        .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                        .toList(),
                    decoration: _inputDecoration('Google Account'),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Title'),
                  ),
                  const SizedBox(height: 12),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: _inputDecoration('Location (optional)'),
                  ),
                  const SizedBox(height: 12),

                  // Start time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _start == null
                              ? 'Start: Not set'
                              : 'Start: ${DateFormat.yMd().add_Hm().format(_start!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDateTime(isStart: true),
                        child: const Text('Pick'),
                      ),
                    ],
                  ),

                  // End time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _end == null
                              ? 'End: Not set'
                              : 'End: ${DateFormat.yMd().add_Hm().format(_end!)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDateTime(isStart: false),
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () {
                        widget.onConfirm(
                          accountId: _selectedAccountId!,
                          title: _titleController.text.trim(),
                          start: _start!,
                          end: _end!,
                          location: _locationController.text.trim().isEmpty
                              ? null
                              : _locationController.text.trim(),
                        );
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9ECDEC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Add',
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

Future<void> showAddEventDialog({
  required BuildContext context,
  required Map<String, dynamic> eventData,
  required List<String> accountIds,
  required void Function({
  required String accountId,
  required String title,
  required DateTime start,
  required DateTime end,
  String? location,
  }) onConfirm,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AddEventDialog(
      eventData: eventData,
      accountIds: accountIds,
      onConfirm: onConfirm,
    ),
  );
}
