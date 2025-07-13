import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
