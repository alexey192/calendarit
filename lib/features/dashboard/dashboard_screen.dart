import 'package:calendarit/features/dashboard/widgets/add_new_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/connected_account.dart';
import '../auth/auth_cubit.dart';
import '../../models/calendar_event.dart';
import 'calendar_widgets/calendar_cubit.dart';
import 'calendar_widgets/calendar_repository.dart';
import 'widgets/horizontal_card_carousel.dart';
import 'widgets/pending_events_section.dart';
import 'widgets/ai_assistant_section.dart';
import 'calendar_widgets/calendar_section.dart';
import 'widgets/dashboard_animations.dart';
import 'widgets/todo_list_section.dart';
import 'widgets/manage_events_dialog.dart'; // <-- New import for manage events dialog

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late DashboardAnimations _animations;
  final calendarRepository = CalendarRepository();

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

  void _openManageEventsDialog(List<CalendarEvent> allEvents, List<String> accountIds) {
    showDialog(
      context: context,
      builder: (_) => ManageEventsDialog(
        events: allEvents,
        calendarRepository: calendarRepository,
        accountIds: accountIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authState = context.watch<AuthCubit>().state;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final accountIds = authState is AuthSuccess ? authState.accountIds : <String>[];

    return BlocProvider(
      create: (_) => CalendarCubit(calendarRepository)..loadEvents(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF005C96),
                Color(0xFF0076B8),
                Color(0xFF54A7D5),
                Color(0xFF9ECDEC),
              ],
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
                    // Gmail Connections
                    SlideTransition(
                      position: _animations.slideAnimation,
                      child: FadeTransition(
                        opacity: _animations.fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.4,
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
                                            ? Row(
                                          children: [
                                            Icon(Icons.link_off_rounded,
                                                size: 32, color: Colors.grey.shade300),
                                            const SizedBox(width: 8),
                                            Text(
                                              'No connections yet',
                                              style: TextStyle(
                                                  fontSize: 16, color: Colors.grey.shade500),
                                            ),
                                            const SizedBox(width: 12),
                                            const AddNewCard(),
                                          ],
                                        )
                                            : HorizontalCardCarousel(accounts: accounts);
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: MediaQuery.of(context).size.width / 2 - 60,
                                  top: -55,
                                  child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Image.asset(
                                      'icons/logo.png', //TODO change logo
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 10,
                                  child: IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.white, size: 36),
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      if (context.mounted) {
                                        context.go('/sign-in'); // or your actual login/onboarding route
                                      }
                                    },
                                  ),

                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('events')
                                    .snapshots(), // fetch all events for manage dialog
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final docs = snapshot.data?.docs ?? [];
                                  final allEvents = docs.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return CalendarEvent.fromMap(data, doc.id);
                                  }).toList();

                                  final pendingEvents = allEvents
                                      .where((e) => e.status?.toLowerCase() == 'pending')
                                      .toList();

                                  return Stack(
                                    children: [
                                      PendingEventsSection(
                                        events: pendingEvents,
                                        calendarRepository: calendarRepository,
                                        accountIds: accountIds,
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () {
                                            _openManageEventsDialog(allEvents, accountIds);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0076BC),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.list_alt,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              const TodoListSection(),
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
