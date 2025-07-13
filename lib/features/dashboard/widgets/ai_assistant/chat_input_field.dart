import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'chat_cubit.dart';

class ChatInputField extends StatelessWidget {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => context.read<ChatCubit>().handleAttachment(),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (text) {
                if (text.trim().isEmpty) return;
                context.read<ChatCubit>().handleMessage(
                  types.PartialText(text: text.trim()),
                );
                controller.clear();
              },
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
