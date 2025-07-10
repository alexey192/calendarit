import 'package:flutter/material.dart';

class CompactEventCard extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onEdit;

  const CompactEventCard({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.onAccept,
    required this.onDecline,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Text info (title, date, location)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937), // Dark color for white background
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Buttons - smaller for compact layout
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 14,
                ),
                onPressed: onAccept,
                tooltip: 'Accept',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                  size: 14,
                ),
                onPressed: onDecline,
                tooltip: 'Decline',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.blue,
                  size: 14,
                ),
                onPressed: onEdit,
                tooltip: 'Edit',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}