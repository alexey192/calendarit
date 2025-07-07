import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventListPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
            (index) => Card(
          child: ListTile(
            leading: const Icon(Icons.event),
            title: Text('Event Title ${index + 1}'),
            subtitle: const Text('Event summary or details...'),
            onTap: () => context.go('/event/event-${index + 1}'),
          ),
        ),
      ),
    );
  }
}
