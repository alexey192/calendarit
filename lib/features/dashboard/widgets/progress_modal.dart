import 'dart:async';

import 'package:calendarit/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../services/cloud_vision_ocr_service.dart';
import '../../../services/event_parser_service.dart';

class ProgressStep {
  final IconData icon;
  final String label;

  ProgressStep({required this.icon, required this.label});
}

Future<void> showAnimatedProgressModal(BuildContext context, Future<void> Function() task) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnimatedProgressDialog(task: task),
  );
}

class _AnimatedProgressDialog extends StatefulWidget {
  final Future<void> Function() task;

  const _AnimatedProgressDialog({required this.task});

  @override
  State<_AnimatedProgressDialog> createState() => _AnimatedProgressDialogState();
}

class _AnimatedProgressDialogState extends State<_AnimatedProgressDialog> {
  final List<ProgressStep> _steps = [
    ProgressStep(icon: FontAwesomeIcons.image, label: 'Extracting data from your image...'),
    ProgressStep(icon: FontAwesomeIcons.wandMagicSparkles, label: 'Some more magic...'),
    ProgressStep(icon: FontAwesomeIcons.circleCheck, label: 'Done!'),
  ];

  int _currentStep = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        _timer.cancel();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop();
        await widget.task();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(step.icon, key: ValueKey(step.icon), size: 64,
                  color: AppColors.primaryColor),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                step.label,
                key: ValueKey(step.label),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
