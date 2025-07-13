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
  late final TextEditingController _descriptionController;

  DateTime? _start;
  DateTime? _end;
  String? _selectedAccountId;

  @override
  void initState() {
    //print eventData
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['title'] ?? '');
    _locationController = TextEditingController(text: widget.eventData['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    _start = widget.eventData['start'] is DateTime ? widget.eventData['start'] : null;
    _end = widget.eventData['end'] is DateTime ? widget.eventData['end'] : null;
    _selectedAccountId = widget.accountIds.isNotEmpty ? widget.accountIds.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_start ?? DateTime.now()) : (_end ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? (_start ?? DateTime.now()) : (_end ?? DateTime.now())),
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
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.6,
        ),
      ),
    );
  }


  final List<String> _categories = ["Sport", "Music", "Education", "Work", "Health", "Arts & Culture", "Social & Entertainment", "Others"]; //TODO define a list
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          color: theme.dialogBackgroundColor,
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
                      Text(
                        'Add to Google Calendar',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.iconTheme.color),
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

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration('Description (optional)'),
                  ),
                  const SizedBox(height: 12),

                  // Start
                  TextFormField(
                    readOnly: true,
                    onTap: () => _pickDateTime(isStart: true),
                    decoration: _inputDecoration('Start').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, size: 20, color: theme.iconTheme.color),
                        onPressed: () => _pickDateTime(isStart: true),
                        splashRadius: 20,
                      ),
                      hintText: 'Not set',
                    ),
                    controller: TextEditingController(
                      text: _start == null ? '' : DateFormat.yMd().add_Hm().format(_start!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // End
                  TextFormField(
                    readOnly: true,
                    onTap: () => _pickDateTime(isStart: false),
                    decoration: _inputDecoration('End').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, size: 20, color: theme.iconTheme.color),
                        onPressed: () => _pickDateTime(isStart: false),
                        splashRadius: 20,
                      ),
                      hintText: 'Not set',
                    ),
                    controller: TextEditingController(
                      text: _end == null ? '' : DateFormat.yMd().add_Hm().format(_end!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    items: _categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    decoration: _inputDecoration('Category'),
                  ),
                  const SizedBox(height: 24),



                  // Submit
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
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Add',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
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
