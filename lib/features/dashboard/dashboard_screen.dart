import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/styles.dart';
import '../../models/connected_account.dart';
import 'widgets/event_list_widget.dart';
import 'widgets/section_title.dart';
import 'widgets/horizontal_card_carousel.dart';
import 'widgets/icon_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear),
            onPressed: () => context.go('/settings'),
          ),
        ],
        title: const Text("Dashboard"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: "Connections"),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
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

              return HorizontalCardCarousel(accounts: accounts);
            },
          ),
          const SectionTitle(title: "Your Events"),
          const Expanded(child: EventListWidget()),
        ],
      ),
    );
  }
}
