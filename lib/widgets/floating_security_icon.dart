import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:lucide_icons/lucide_icons.dart';

class FloatingSecurityIcon extends StatefulWidget {
  const FloatingSecurityIcon({super.key});

  @override
  State<FloatingSecurityIcon> createState() => _FloatingSecurityIconState();
}

class _FloatingSecurityIconState extends State<FloatingSecurityIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        // Bobbing up and down
        final translateY = math.sin(value * math.pi * 2) * 10;
        // Slight rotation for 3D feel
        final rotateY = math.sin(value * math.pi * 2) * 0.1;
        final rotateX = math.cos(value * math.pi * 2) * 0.1;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..translate(0.0, translateY)
            ..rotateX(rotateX)
            ..rotateY(rotateY),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
              Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: Icon(LucideIcons.shieldCheck, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}
