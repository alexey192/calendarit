import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'ai_assistant_service.dart';

class ChatCubit extends Cubit<List<types.Message>> {
  final AiAssistantService _service;
  final _uuid = const Uuid();
  static const _chatKey = 'ai_chat_history';

  ChatCubit(this._service) : super([]);

  void loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chatKey) ?? [];
    final history = raw.map((e) => types.TextMessage.fromJson(jsonDecode(e))).toList();
    emit(history);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_chatKey, raw);
  }

  void handleMessage(types.PartialText message) async {
    final userMessage = types.TextMessage(
      id: _uuid.v4(),
      author: const types.User(id: 'user'),
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    emit([...state, userMessage]);
    await _persist();

    final botMessage = await _service.handleUserMessage(message.text);
    if (botMessage != null) {
      emit([...state, userMessage, botMessage]);
      await _persist();
    }
  }

  void handleAttachment() async {
    final result = await _service.handleAttachmentFlow();
    if (result != null) {
      emit([...state, result]);
      await _persist();
    }
  }
}
