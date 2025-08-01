import 'dart:math';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_cubit.dart';
import 'package:calendarit/features/dashboard/calendar_widgets/calendar_repository.dart';
import 'package:calendarit/models/event_suggestion_model.dart';
import 'package:calendarit/services/firestore_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../auth/auth_cubit.dart';
import '../widgets/card_wrapper.dart';
import 'add_event_dialogue.dart';
import 'ai_assistant/action_buttons.dart';
import 'ai_assistant/ai_assistant_service.dart';
import 'ai_assistant/ai_image_handler.dart';

class AIAssistantSection extends StatefulWidget {
  const AIAssistantSection({super.key});

  @override
  State<AIAssistantSection> createState() => _AIAssistantSectionState();
}

class _AIAssistantSectionState extends State<AIAssistantSection> {
  final AiAssistantService _aiAssistantService = AiAssistantService();

  final types.User _user = const types.User(id: 'user-1');

  final List<types.Message> _messages = [
    types.TextMessage(
      author: types.User(id: 'assistant', firstName: 'AI Assistant'),
      id: 'init_msg_1',
      text: 'Hello!\nHow can I help you today?',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

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

    AiAssistantService.handleUserMessage(message.text).then((response) async {
      if (response != null) {
        setState(() {
          _messages.insert(0, response);
        });

        if(response is types.TextMessage
        && response.metadata?['isSuccess'] == true
        ) {
          setState(() {
            _messages.insert(0,
              AiAssistantService.buildTextMessage(
                'Now I will open a form to save this event in your calendar 📅'
              )
            );
          });

          EventSuggestion suggestion = response.metadata?['eventSuggestion'];

          final eventSuggestion = suggestion.toJson();
          //parse start and end times in event suggestion
          if (suggestion.start != null) {
            eventSuggestion['start'] = DateTime.parse(suggestion.start.toString());
          }
          if (suggestion.end != null) {
            eventSuggestion['end'] = DateTime.parse(suggestion.end.toString());
          }

          await showAddEventDialog(
          context: context,
          eventData: eventSuggestion,
          accountIds: await FirestoreUtils.getAccountIds(),
          onConfirm: ({
            required String accountId,
            required String title,
            required DateTime start,
            required DateTime end,
            String? location,
          }) async {
            await FirestoreUtils.addEventAccepted(eventSuggestion);
            await context.read<CalendarRepository>().addEventToGoogleCalendar(
              accountId: accountId,
              title: title,
              startDateTime: start,
              endDateTime: end,
              location: location,
            );
            await context.read<CalendarCubit>().loadEvents();
          },
          );
        }
      }
    });
  }

  void _handleAttachmentPressed() async {
    final uuid = const Uuid();

    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final imageMessage = types.ImageMessage(
      author: _user,
      id: uuid.v4(),
      name: image.name,
      size: await image.length(),
      uri: image.path,
    );

    setState(() => _messages.insert(0, imageMessage));

    final calendarRepository = context.read<CalendarRepository>();
    final accountIds = await FirestoreUtils.getAccountIds();
    //final accountIds = context.read<AuthCubit>().accountIds;

    // Define callback to inject chat messages
    void onStatusUpdate(String msg, {bool isAssistant = true}) {
      final chatMsg = types.TextMessage(
        author: types.User(id: isAssistant ? 'assistant' : _user.id),
        id: uuid.v4(),
        text: msg,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      setState(() => _messages.insert(0, chatMsg));
    }

    final result = await AiImageHandler.handleOcrAndEventFlow(
      context,
      accountIds,
      calendarRepository,
      image: image,
      onStatusUpdate: onStatusUpdate,
      isChat: true,
    );

    if (result == true) {
      context.read<CalendarCubit>().loadEvents();
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
                      theme: DefaultChatTheme(
                        inputBackgroundColor: Colors.white,
                        inputTextColor: Colors.black87,
                        inputBorderRadius: BorderRadius.all(Radius.circular(16)),
                        inputTextStyle: TextStyle(fontSize: 16),
                        backgroundColor: Colors.transparent,
                        primaryColor: Color(0xFF0076BC),
                        secondaryColor: Color(0xFF9ECDEC),
                        receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
                        sentMessageBodyTextStyle: TextStyle(color: Colors.white),
                        inputContainerDecoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          border: Border.all(
                            color: Color(0xFF0076BC),
                            width: 1.2,
                          ),
                        ),
                      ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 10,
              child: ActionButtons(
                calendarRepository: context.read<CalendarRepository>(),
                accountIds: context.read<AuthCubit>().accountIds,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
