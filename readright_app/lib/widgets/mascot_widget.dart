import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mascot_tiger.dart';

/// MascotWidget: Uses a full-color PNG/SVG tiger illustration from assets/mascot.svg
/// Falls back gracefully to a simplified friendly tiger if asset is missing
class MascotWidget extends StatefulWidget {
  final double size;
  final bool animated;
  final bool waving;

  const MascotWidget({
    super.key,
    this.size = 120,
    this.animated = true,
    this.waving = false,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bounceAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try SVG first, then PNG, then fallback to programmatic tiger
    Widget mascotContent = FutureBuilder(
      future: _loadMascot(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data!;
        }
        // Fallback to friendly programmatic tiger
        return _buildFriendlyTiger();
      },
    );

    if (widget.animated) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            ),
          );
        },
        child: mascotContent,
      );
    }

    return mascotContent;
  }

  Future<Widget?> _loadMascot() async {
    try {
      // Try SVG first (Clemson tiger)
      return SvgPicture.asset(
        'assets/mascot.svg',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );
    } catch (e) {
      try {
        // Try PNG fallback
        return Image.asset(
          'assets/mascot.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        );
      } catch (e) {
        // Return null to use programmatic fallback
        return null;
      }
    }
  }

  Widget _buildFriendlyTiger() {
    // More friendly, rounded tiger for children
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade300, Colors.orange.shade600],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Friendly face
          Positioned(
            top: widget.size * 0.25,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left eye - big and friendly
                Container(
                  width: widget.size * 0.12,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.06,
                      height: widget.size * 0.06,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: widget.size * 0.15),
                // Right eye - big and friendly
                Container(
                  width: widget.size * 0.12,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.06,
                      height: widget.size * 0.06,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Friendly smile
          Positioned(
            top: widget.size * 0.5,
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.18,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.size * 0.3),
                  bottomRight: Radius.circular(widget.size * 0.3),
                ),
              ),
            ),
          ),
          // Cute nose
          Positioned(
            top: widget.size * 0.45,
            child: Container(
              width: widget.size * 0.08,
              height: widget.size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
