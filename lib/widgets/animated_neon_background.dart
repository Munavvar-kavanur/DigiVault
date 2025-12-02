import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedNeonBackground extends StatefulWidget {
  final Widget child;
  final int
  currentIndex; // Kept for compatibility, though we might not use it for alignment anymore

  const AnimatedNeonBackground({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  State<AnimatedNeonBackground> createState() => _AnimatedNeonBackgroundState();
}

class _AnimatedNeonBackgroundState extends State<AnimatedNeonBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Node> _nodes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            for (var node in _nodes) {
              node.update();
            }
          })
          ..repeat();

    // Initialize nodes
    for (int i = 0; i < 20; i++) {
      _nodes.add(
        Node(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.002,
          vy: (_random.nextDouble() - 0.5) * 0.002,
          size: _random.nextDouble() * 3 + 1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme
    final Color bgStart = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF0F4F8); // Slate 900 or Slate 50
    final Color bgEnd = isDark
        ? const Color(0xFF1E1B4B)
        : const Color(0xFFE0E7FF); // Indigo 950 or Indigo 100
    final Color gridColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.03);
    final Color nodeColor = Theme.of(
      context,
    ).colorScheme.primary.withOpacity(isDark ? 0.3 : 0.2);

    return Stack(
      children: [
        // 1. Base Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgStart, bgEnd],
            ),
          ),
        ),

        // 2. Animated Grid and Nodes
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: TechBackgroundPainter(
                nodes: _nodes,
                gridColor: gridColor,
                nodeColor: nodeColor,
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // 3. Content
        widget.child,
      ],
    );
  }
}

class Node {
  double x;
  double y;
  double vx;
  double vy;
  double size;

  Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;

    // Bounce off edges
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
  }
}

class TechBackgroundPainter extends CustomPainter {
  final List<Node> nodes;
  final Color gridColor;
  final Color nodeColor;
  final double animationValue;

  TechBackgroundPainter({
    required this.nodes,
    required this.gridColor,
    required this.nodeColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final Paint nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = nodeColor.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Draw Grid
    const double gridSize = 40.0;
    // Offset grid slightly based on animation to give a "scanning" feel or just static
    // Let's make it static for stability, or very slow move

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Update and Draw Nodes
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // node.update(); // Moved to controller listener

      final Offset pos = Offset(node.x * size.width, node.y * size.height);

      // Draw Node Glow
      canvas.drawCircle(pos, node.size, nodePaint);

      // Draw Connections
      for (var j = i + 1; j < nodes.length; j++) {
        final otherNode = nodes[j];
        final Offset otherPos = Offset(
          otherNode.x * size.width,
          otherNode.y * size.height,
        );
        final double distance = (pos - otherPos).distance;

        if (distance < 150) {
          // Connect if close enough
          // Opacity based on distance
          final double opacity = (1 - (distance / 150)) * 0.2;
          linePaint.color = nodeColor.withOpacity(opacity);
          canvas.drawLine(pos, otherPos, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TechBackgroundPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
