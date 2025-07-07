import 'package:flutter/material.dart';

import 'add_new_card.dart';
import 'icon_card.dart';

class HorizontalCardCarousel extends StatelessWidget {
  final String type; // 'mail' or 'calendar'
  const HorizontalCardCarousel({required this.type});

  @override
  Widget build(BuildContext context) {
    final items = [
      Icons.email,
      Icons.email_outlined,
      Icons.alternate_email,
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < items.length) {
            return IconCard(icon: items[index]);
          } else {
            return AddNewCard(label: 'Add ${type == 'mail' ? 'Mailbox' : 'Calendar'}');
          }
        },
      ),
    );
  }
}
