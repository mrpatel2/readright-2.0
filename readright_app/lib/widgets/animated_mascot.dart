import 'package:flutter/material.dart';
import 'mascot_tiger.dart';

/// Animated wrapper for MascotTiger: bob + subtle wave.
class AnimatedMascot extends StatefulWidget {
  final double size;

  const AnimatedMascot({super.key, this.size = 72});

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _bob;
  late final Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _bob = Tween<double>(
      begin: -4.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeInOut));
    _wave = Tween<double>(
      begin: -0.06,
      end: 0.06,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bob.value),
          child: Transform.rotate(
            angle: _wave.value,
            child: MascotTiger(size: widget.size, waving: true),
          ),
        );
      },
    );
  }
}
