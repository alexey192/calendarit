import 'package:flutter/material.dart';
import '../../../models/connected_account.dart';
import 'icon_card.dart';
import 'add_new_card.dart';

class HorizontalCardCarousel extends StatelessWidget {
  final List<ConnectedAccount> accounts;

  const HorizontalCardCarousel({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == accounts.length) {
            return const AddNewCard();
          }

          final account = accounts[index];

          return IconCard(
            icon: _iconForType(account.type),
            label: account.email,
          );
        },
      ),
    );
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.gmail:
        return Icons.email; // Later can be replaced with Gmail logo if needed
      case AccountType.outlook:
        return Icons.mail_outline;
    }
  }
}
