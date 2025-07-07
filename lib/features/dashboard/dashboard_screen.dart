import 'package:calendarit/features/dashboard/widgets/event_list_placeholder.dart';
import 'package:calendarit/features/dashboard/widgets/horizontal_card_carousel.dart';
import 'package:calendarit/features/dashboard/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar-it'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: 'Connections'),
          const SizedBox(height: 8),
          const HorizontalCardCarousel(type: 'mail'),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Calendars'),
          const SizedBox(height: 8),
          const HorizontalCardCarousel(type: 'calendar'),
          const SizedBox(height: 24),
          const SectionTitle(title: 'Found Events'),
          const SizedBox(height: 8),
          EventListPlaceholder(),
        ],
      ),
    );
  }
}
