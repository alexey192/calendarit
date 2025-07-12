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
    with SingleTickerProviderStateMixin {
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

    _undoTimer = Timer(const Duration(seconds: 5), () async {
      await widget.onUpdateStatus(status);
      _controller.reverse().then((_) {
        if (mounted) setState(() => _visible = false);
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('Marked as ${status == 'accepted' ? 'accepted' : 'declined'}'),
            const Spacer(),
            const SizedBox(width: 8),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _undoTimer?.cancel();
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
            color: Color(0xFF9ECDEC).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFF9ECDEC).withOpacity(0),
              width: 1,
            ),
          ),
          child: CompactEventCard(
            title: widget.title,
            date: widget.date,
            location: widget.location,
            //onAccept: _pendingUndo ? null : () => _handleAction('accepted'),
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
