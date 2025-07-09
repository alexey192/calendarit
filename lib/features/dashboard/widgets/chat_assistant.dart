import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatAssistant extends StatefulWidget {
  const ChatAssistant({super.key});

  @override
  State<ChatAssistant> createState() => _ChatAssistantState();
}

class _ChatAssistantState extends State<ChatAssistant> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final List<_ChatMessage> _messages = [
    _ChatMessage(text: "Hello!", isUser: false),
    _ChatMessage(text: "Hi there! How can I help?", isUser: true),
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
    });
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _messages.add(_ChatMessage(imageBytes: bytes, isUser: true));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(imageFile: File(pickedFile.path), isUser: true));
        });
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.imageFile != null || msg.imageBytes != null) {
                      return ImageChatBubble(
                        imageFile: msg.imageFile,
                        imageBytes: msg.imageBytes,
                        isUser: msg.isUser,
                      );
                    } else {
                      return ChatBubble(message: msg.text ?? "", isUser: msg.isUser);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    // Image upload button on the left
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.image, color: Colors.deepPurple),
                        onPressed: _pickImage,
                        tooltip: 'Upload Image',
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text input field
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Send button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurple),
                        onPressed: _sendMessage,
                        tooltip: 'Send Message',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  final String? text;
  final File? imageFile;       // for mobile
  final Uint8List? imageBytes; // for web
  final bool isUser;

  _ChatMessage({
    this.text,
    this.imageFile,
    this.imageBytes,
    required this.isUser,
  }) : assert(
  text != null || imageFile != null || imageBytes != null,
  'Either text or image must be provided',
  );
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({required this.message, required this.isUser, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message),
      ),
    );
  }
}

class ImageChatBubble extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final bool isUser;

  const ImageChatBubble({
    this.imageFile,
    this.imageBytes,
    required this.isUser,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageFile != null) {
      imageWidget = Image.file(
        imageFile!,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
      );
    } else if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = const SizedBox.shrink();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageWidget,
        ),
      ),
    );
  }
}
