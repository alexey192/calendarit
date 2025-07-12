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

    _start = widget.eventData['start'] is DateTime
        ? widget.eventData['start']
        : null;
    _end = widget.eventData['end'] is DateTime
        ? widget.eventData['end']
        : null;

    _selectedAccountId = widget.accountIds.isNotEmpty ? widget.accountIds.first : null;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Google Calendar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              onChanged: (value) => setState(() => _selectedAccountId = value),
              items: widget.accountIds
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Google Account'),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(_start == null
                      ? 'Start: Not set'
                      : 'Start: ${DateFormat.yMd().add_Hm().format(_start!)}'),
                ),
                TextButton(
                  onPressed: () => _pickDateTime(isStart: true),
                  child: const Text('Pick'),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(_end == null
                      ? 'End: Not set'
                      : 'End: ${DateFormat.yMd().add_Hm().format(_end!)}'),
                ),
                TextButton(
                  onPressed: () => _pickDateTime(isStart: false),
                  child: const Text('Pick'),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
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
    builder: (ctx) => AddEventDialog(
      eventData: eventData,
      accountIds: accountIds,
      onConfirm: onConfirm,
    ),
  );
}
