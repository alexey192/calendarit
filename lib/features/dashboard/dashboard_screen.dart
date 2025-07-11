import 'package:calendarit/features/dashboard/widgets/add_new_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/connected_account.dart';
import 'calendar_widgets/calendar_cubit.dart';
import 'calendar_widgets/calendar_repository.dart';
import 'widgets/horizontal_card_carousel.dart';
import 'widgets/pending_events_section.dart';
import 'widgets/ai_assistant_section.dart';
import 'calendar_widgets//calendar_section.dart';
import 'widgets/dashboard_animations.dart';
import 'widgets/todo_list_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late DashboardAnimations _animations;

  @override
  void initState() {
    super.initState();
    _animations = DashboardAnimations(this);
    _animations.start();
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return BlocProvider(
      create: (_) => CalendarCubit(CalendarRepository())..loadEvents(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your connections',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 0),

                    // Gmail Connections
                    SlideTransition(
                      position: _animations.slideAnimation,
                      child: FadeTransition(
                        opacity: _animations.fadeAnimation,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('gmailAccounts')
                              .snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            final accounts = docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return ConnectedAccount(
                                email: data['email'] ?? '',
                                type: AccountType.gmail,
                              );
                            }).toList();

                            return accounts.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        Icon(Icons.link_off_rounded, size: 32, color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No connections yet',
                                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    AddNewCard(),
                                  ],
                                ),
                              ),
                            )
                                : HorizontalCardCarousel(accounts: accounts);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Schedule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const CalendarSection(),
                              const SizedBox(height: 32),
                              const AIAssistantSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              PendingEventsSection(),
                              SizedBox(height: 24),
                              TodoListSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
