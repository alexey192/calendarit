import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:math';

import '../../models/connected_account.dart';
import 'widgets/card_wrapper.dart';
import 'widgets/event_list_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/compact_event_card.dart';
import 'widgets/horizontal_card_carousel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<types.Message> _messages = [
    types.TextMessage(
    author: types.User(id: 'assistant', firstName: 'AI Assistant'),
    id: 'init_msg_1',
    text: 'Hello!\nHow can I help you today?',
    createdAt: DateTime.now().millisecondsSinceEpoch,
  ),
  ];

  final types.User _user = const types.User(id: 'user-1');

  final CalendarController _calendarController = CalendarController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initAnimations();

    _calendarController.view = CalendarView.week;

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _slideController.forward());
    Future.delayed(const Duration(milliseconds: 400), () => _scaleController.forward());

  }

  void _initAnimations() {
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack));
  }

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
      // handle errors here if you want
      print('Image picker error: $e');
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Removed HeaderSection
                  // FadeTransition(opacity: _fadeAnimation, child: HeaderSection(user: user)),
                  // const SizedBox(height: 24),

                  /// Your Connections Heading
                  Text(
                    'Your connections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 0),

                  /// Gmail Connections (Top)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('gmailAccounts')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final accounts = docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ConnectedAccount(
                              email: data['email'] ?? '',
                              type: AccountType.gmail,
                            );
                          }).toList();

                          return accounts.isEmpty
                              ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.link_off_rounded, size: 32, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No connections yet',
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          )
                              : HorizontalCardCarousel(accounts: accounts);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),

                  /// Calendar + Highlights
                  SlideTransition(
                    position: _slideAnimation,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Your Schedule',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CardWrapper(
                                height: 400,
                                child: Stack(
                                  children: [
                                    SfCalendar(
                                      controller: _calendarController,
                                      view: CalendarView.week,
                                      todayHighlightColor: Colors.deepPurpleAccent,
                                      headerStyle: const CalendarHeaderStyle(
                                        backgroundColor: Colors.transparent,
                                        textAlign: TextAlign.center,
                                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 8,
                                      child: IconButton(
                                        onPressed: () {
                                          _calendarController.backward!();
                                        },
                                        icon: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.deepPurpleAccent, // background color
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(0),
                                          child: const Icon(Icons.chevron_left, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 48,
                                      child: IconButton(
                                        onPressed: () {
                                          _calendarController.backward!();
                                        },
                                        icon: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.deepPurpleAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(0),
                                          child: const Icon(Icons.chevron_right, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending events',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('events')
                                    .orderBy('createdAt', descending: true)
                                    .limit(5)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final docs = snapshot.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return CardWrapper(
                                      height: 200,
                                      child: Center(
                                        child: Text(
                                          'No events to highlight',
                                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                        ),
                                      ),
                                    );
                                  }

                                  return CardWrapper(
                                    height: 400,
                                    child: ListView.separated(
                                      itemCount: docs.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final data = docs[index].data() as Map<String, dynamic>;
                                        final doc = docs[index];

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: CompactEventCard(
                                            title: data['title'] ?? 'Untitled Event',
                                            date: data['date'] ?? 'No date',
                                            location: data['location'] ?? 'No location',
                                            onAccept: () {
                                              doc.reference.update({'status': 'accepted'});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Event accepted!'),
                                                  backgroundColor: Color(0xFF059669),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            onDecline: () {
                                              doc.reference.update({'status': 'declined'});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Event declined!'),
                                                  backgroundColor: Color(0xFFDC2626),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            onEdit: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Edit functionality coming soon!'),
                                                  backgroundColor: Color(0xFF2563EB),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(data['title'] ?? 'Untitled Event'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const SizedBox(height: 8),
                                                        Text('📅  Date: ${data['date'] ?? 'No date'}'),
                                                        const SizedBox(height: 8),
                                                        Text('📍  Location: ${data['location'] ?? 'No location'}'),
                                                        const SizedBox(height: 8),
                                                        Text('📝  Description: ${data['description'] ?? 'No description'}'),
                                                        const SizedBox(height: 8),
                                                        Text('🏷️  Tags: ${data['tag'] ?? 'No tags'}'),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          //Todo
                                                        },
                                                        child: const Text('Accept'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          //Todo
                                                        },
                                                        child: const Text('Decline'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          //Todo
                                                        },
                                                        child: const Text('Edit'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 32),

                  /// Events & AI Assistant
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 50,
                        child: Column(
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
                            CardWrapper(
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
                                    primaryColor: Color(0xFF8B5CF6),
                                    secondaryColor: Color(0xFFEDE9FE),
                                    receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
                                    sentMessageBodyTextStyle: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Flexible(
                        flex: 50,
                        child: SizedBox(
                          // width is relative due to flex, no need to specify exact width
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // TODO: handle AI event recognition from image
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Recognize\nfrom image',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  // TODO: handle add event manually
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF059669).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_circle_outline,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Add event\nmanually',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  // TODO: handle settings button press
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4B5563),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4B5563).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Settings',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
