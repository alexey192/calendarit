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
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: accounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < accounts.length) {
            return IconCard(account: accounts[index]);
          } else {
            return const AddNewCard();
          }
        },
      ),
    );
  }
}
