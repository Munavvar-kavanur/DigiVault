import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F172A), // Slate 900
                  const Color(0xFF1E293B), // Slate 800
                ]
              : [
                  const Color(0xFFF8FAFC), // Slate 50
                  const Color(0xFFE2E8F0), // Slate 200
                ],
        ),
      ),
      child: child,
    );
  }
}
