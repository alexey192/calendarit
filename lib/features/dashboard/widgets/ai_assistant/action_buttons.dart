import 'package:calendarit/features/dashboard/widgets/add_event_dialogue.dart';
import 'package:calendarit/features/dashboard/widgets/ai_assistant/round_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendarit/app/app_colors.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_cubit.dart';
import 'package:calendarit/services/event_parser_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_image_handler.dart';

class ActionButtons extends StatelessWidget {
  final CalendarRepository calendarRepository;
  final List<String> accountIds;

  const ActionButtons({
    super.key,
    required this.calendarRepository,
    required this.accountIds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundButton(
            icon: Icons.image,
            color: AppColors.primaryColor,
            onPressed: () async {
              final result = await AiImageHandler.handleOcrAndEventFlow(
                  context,
                  accountIds,
                  calendarRepository,
                onStatusUpdate: (message, {isAssistant = false}) {
                  AiImageHandler.showLoadingDialog(context, message);
                },
              );
              if (result != null) {
                context.read<CalendarCubit>().loadEvents();
              }
            },
          ),
          const SizedBox(height: 12),
          RoundButton(
            icon: Icons.add_circle_outline,
            color: const Color(0xFF059669),
            onPressed: () {
              showAddEventDialog(
                context: context,
                eventData: {},
                accountIds: accountIds,
                onConfirm: ({
                  required String accountId,
                  required String title,
                  required DateTime start,
                  required DateTime end,
                  String? location,
                }) async {
                  await calendarRepository.addEventToGoogleCalendar(
                    accountId: accountId,
                    title: title,
                    startDateTime: start,
                    endDateTime: end,
                    location: location,
                  );

                  final suggestion = EventSuggestion(
                    title: title,
                    location: location ?? '',
                    start: start,
                    end: end,
                    isTimeSpecified: true,
                    description: '',
                    category: 'Manual',
                  );

                  await _saveSuggestedEventToFirestore(suggestion);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveSuggestedEventToFirestore(
      EventSuggestion suggestion, {
        String status = 'pending',
      }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc();

    await docRef.set({
      'title': suggestion.title,
      'location': suggestion.location,
      'start': suggestion.start,
      'end': suggestion.end,
      'isTimeSpecified': suggestion.isTimeSpecified,
      'description': suggestion.description,
      'category': suggestion.category,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
