import 'package:calendarit/models/parsed_event_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import 'ai_assistant_service.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(ChatState.initial());

  final _uuid = const Uuid();

  Future<void> sendMessage(String text) async {
    final userMessage = types.TextMessage(
      author: const types.User(id: 'user'),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: text,
    );

    final updatedMessages = [userMessage, ...state.messages];
    emit(state.copyWith(messages: updatedMessages));

    final reply = await AiAssistantService.handleUserMessage(
      text,
      previousEvent: state.previousEvent,
    );

    final updatedWithReply = [reply, ...updatedMessages];
    emit(state.copyWith(messages: updatedWithReply));

    // Parse and update previousEvent tracking
    final parsed = reply.metadata?['parsedEventResult'] as ParsedEventResult?;
    if (parsed != null && parsed.event != null && parsed.event!.isNotEmpty) {
      final missing = AiAssistantService.getMissingRequiredFields(parsed.event!);
      emit(state.copyWith(previousEvent: missing.isEmpty ? null : parsed.event));
    }
  }

  void clearChat() {
    emit(ChatState.initial());
  }
}
