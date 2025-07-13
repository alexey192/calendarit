part of 'chat_cubit.dart';

class ChatState {
  final List<types.Message> messages;
  final Map<String, dynamic>? previousEvent;

  const ChatState({
    required this.messages,
    required this.previousEvent,
  });

  factory ChatState.initial() => const ChatState(messages: [], previousEvent: null);

  ChatState copyWith({
    List<types.Message>? messages,
    Map<String, dynamic>? previousEvent,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      previousEvent: previousEvent,
    );
  }
}
