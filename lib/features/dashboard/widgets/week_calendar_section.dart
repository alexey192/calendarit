import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'week_calendar_view.dart';
import 'highlights_section.dart';
import 'card_wrapper.dart';

class WeekCalendarSection extends StatelessWidget {
  final String uid;

  const WeekCalendarSection({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Week Calendar',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 16),
              CardWrapper(
                height: 350,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: WeekCalendarView(
                    events: [],
                    onEventTap: (event) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped: ${event.title}'),
                          backgroundColor: event.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    onDateTap: (date) {
                      debugPrint('Tapped date: $date');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: HighlightsSection(uid: uid),
        ),
      ],
    );
  }
}
