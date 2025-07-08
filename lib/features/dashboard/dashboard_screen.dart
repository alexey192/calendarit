import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/connected_account.dart';
import 'widgets/horizontal_card_carousel.dart';
import 'widgets/section_title.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Email Accounts'),
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
            const SizedBox(height: 24),
            const SectionTitle(title: 'Calendars'),
            const HorizontalCardCarousel(accounts: []), // Placeholder
            const SizedBox(height: 24),
            const SectionTitle(title: 'Events'),
            const Placeholder(), // You can replace with your EventList
          ],
        ),
      ),
    );
  }
}
