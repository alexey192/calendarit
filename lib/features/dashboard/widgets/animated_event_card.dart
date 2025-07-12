import 'dart:async';

import 'package:flutter/material.dart';

import 'compact_event_card.dart';

class AnimatedEventCard extends StatefulWidget {
  final String eventId;
  final String title;
  final String date;
  final String location;
  final Function(String status) onUpdateStatus;
  final VoidCallback? onEdit;

  const AnimatedEventCard({
    super.key,
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.onUpdateStatus,
    this.onEdit,
  });

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard>
    with TickerProviderStateMixin {
  bool _visible = true;
  bool _pendingUndo = false;
  late AnimationController _controller;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  void _handleAction(String status) {
    setState(() => _pendingUndo = true);

    final countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _undoTimer = Timer(const Duration(seconds: 5), () async {
      print('Undo timer expired for event ${widget.eventId}');
      await widget.onUpdateStatus(status);
      print('Event ${widget.eventId} marked as $status');
      _controller.reverse().then((_) {
        if (mounted) setState(() => _visible = false);
      });
      countdownController.dispose();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.black87,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Marking as ${status == 'accepted' ? 'accepted' : 'declined'} shortly',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: countdownController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - countdownController.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.lightBlueAccent,
          onPressed: () {
            _undoTimer?.cancel();
            countdownController.dispose();
            setState(() => _pendingUndo = false);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: Opacity(
        opacity: _pendingUndo ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9ECDEC).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF9ECDEC).withOpacity(0),
              width: 1,
            ),
          ),
          child: CompactEventCard(
            title: widget.title,
            date: widget.date,
            location: widget.location,
            onAccept: () {
              if (_pendingUndo) return;
              _handleAction('accepted');
            },
            onDecline: () {
              if (_pendingUndo) return;
              _handleAction('declined');
            },
            onEdit: widget.onEdit ?? () {},
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
