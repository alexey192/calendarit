import 'package:flutter/material.dart';

import '../../../services/gmail_auth_service.dart';

void showProviderPickerModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const ProviderPickerModal(),
  );
}

class ProviderPickerModal extends StatefulWidget {
  const ProviderPickerModal({super.key});

  @override
  State<ProviderPickerModal> createState() => _ProviderPickerModalState();
}

class _ProviderPickerModalState extends State<ProviderPickerModal>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  Future<void> _connectGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GmailAuthService().connectAccount();
      if (!mounted) return;
      Navigator.of(context).pop();
      _showResultDialog(
        context,
        success: true,
        title: 'Success',
        message: 'Google account connected! 🎉',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showResultDialog(
        context,
        success: false,
        title: 'Something went wrong',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Connect an Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildCard(
                onTap: _isLoading ? null : _connectGoogle,
                label: 'Google',
                icons: const [Icons.email, Icons.calendar_today],
              ),
              _buildCard(
                onTap: null,
                label: 'Outlook',
                icons: const [Icons.mail_outline],
              ),
              _buildCard(
                onTap: null,
                label: 'Apple',
                icons: const [Icons.apple],
              ),
            ],
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required VoidCallback? onTap,
    required String label,
    required List<IconData> icons,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[200] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: icons
                    .map((icon) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(icon, size: 24),
                ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isDisabled)
                const Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showResultDialog(BuildContext context,
    {required bool success,
      required String title,
      required String message}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
