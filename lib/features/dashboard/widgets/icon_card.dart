import 'package:flutter/material.dart';

class IconCard extends StatelessWidget {
  final IconData icon;
  const IconCard({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Icon(icon, size: 32),
      ),
    );
  }
}
