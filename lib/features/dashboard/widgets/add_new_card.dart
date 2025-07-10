import 'package:flutter/material.dart';
import 'provider_picker_modal.dart';

class AddNewCard extends StatelessWidget {
  const AddNewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showProviderPickerModal(context),
      child: SizedBox(
        width: 120,
        height: 120,
        child: Card(
          color: Colors.grey[100],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 40, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
