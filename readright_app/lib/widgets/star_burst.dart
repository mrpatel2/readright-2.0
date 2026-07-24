import 'package:flutter/material.dart';
// small helper for trig
import 'dart:math' as Math;

/// Simple star-burst animation used for positive feedback.
class StarBurst extends StatefulWidget {
  final bool play;
  final double size;

  const StarBurst({super.key, required this.play, this.size = 200});

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.play) _ctl.forward();
  }

  @override
  void didUpdateWidget(covariant StarBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !_ctl.isAnimating) {
      _ctl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_ctl.value);
          return CustomPaint(
            painter: _StarPainter(
              progress: t,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.9 + 0.1);
    final center = Offset(size.width / 2, size.height / 2);

    // Draw 8 radiating small circles to simulate burst
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159;
      final radius = progress * (size.width * 0.45);
      final dx = center.dx + radius * Math.cos(angle);
      final dy = center.dy + radius * Math.sin(angle);
      final r = (1 - progress) * 8 + 2;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
