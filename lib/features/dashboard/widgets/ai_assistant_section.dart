import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../widgets/card_wrapper.dart';

class AIAssistantSection extends StatefulWidget {
  const AIAssistantSection({super.key});

  @override
  State<AIAssistantSection> createState() => _AIAssistantSectionState();
}

class _AIAssistantSectionState extends State<AIAssistantSection> {
  final types.User _user = const types.User(id: 'user-1');
  final List<types.Message> _messages = [
    types.TextMessage(
      author: types.User(id: 'assistant', firstName: 'AI Assistant'),
      id: 'init_msg_1',
      text: 'Hello!\nHow can I help you today?',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  final ImagePicker _picker = ImagePicker();

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: Random().nextInt(100000).toString(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });
  }

  Future<void> _handleAttachmentPressed() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageMessage = types.ImageMessage(
          author: _user,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: image.name,
          size: await image.length(),
          uri: image.path,
        );

        setState(() {
          _messages.insert(0, imageMessage);
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Assistant',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 90,
              child: CardWrapper(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  child: Chat(
                    messages: _messages,
                    onSendPressed: _handleSendPressed,
                    onAttachmentPressed: _handleAttachmentPressed,
                    user: _user,
                    theme: const DefaultChatTheme(
                      inputBackgroundColor: Colors.white,
                      inputTextColor: Colors.black87,
                      inputBorderRadius: BorderRadius.all(Radius.circular(16)),
                      inputTextStyle: TextStyle(fontSize: 16),
                      backgroundColor: Colors.transparent,
                      primaryColor: Color(0xFF0076BC),
                      secondaryColor: Color(0xFF9ECDEC),
                      receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
                      sentMessageBodyTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 10,
              child: _ActionButtons(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roundButton(
            icon: Icons.image,
            color: const Color(0xFF0076BC),
            onPressed: () {
              // TODO: AI from image
            },
          ),
          const SizedBox(height: 12),
          _roundButton(
            icon: Icons.add_circle_outline,
            color: const Color(0xFF059669),
            onPressed: () {
              // TODO: Add event manually
            },
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(0),
        backgroundColor: color,
        shadowColor: color.withOpacity(0.4),
        elevation: 6,
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}
