import 'package:flutter/material.dart';

class DashboardAnimations {
  late final AnimationController fadeController;
  late final AnimationController slideController;
  late final AnimationController scaleController;

  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> scaleAnimation;

  DashboardAnimations(TickerProvider vsync) {
    fadeController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 1000));
    slideController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 800));
    scaleController = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 600));

    fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeInOut);
    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: slideController, curve: Curves.easeOutCubic));
    scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: scaleController, curve: Curves.easeOutBack));
  }

  void start() {
    fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => slideController.forward());
    Future.delayed(const Duration(milliseconds: 400), () => scaleController.forward());
  }

  void dispose() {
    fadeController.dispose();
    slideController.dispose();
    scaleController.dispose();
  }
}
