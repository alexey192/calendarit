import 'package:flutter/material.dart';
import '../../../services/gmail_auth_service.dart';

class AddNewCard extends StatelessWidget {
  const AddNewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProviderPicker(context),
      child: SizedBox(
        width: 100,
        child: Card(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.add, size: 40),
          ),
        ),
      ),
    );
  }

  void _showProviderPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Gmail'),
              onTap: () async {
                Navigator.of(context).pop();
                try {
                  await GmailAuthService().connectAccount();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gmail account connected!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Microsoft Outlook (Coming soon)'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Outlook support coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
