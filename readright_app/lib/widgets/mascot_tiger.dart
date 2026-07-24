import 'package:flutter/material.dart';

class MascotTiger extends StatelessWidget {
  final double size;
  final bool waving;

  const MascotTiger({super.key, this.size = 72, this.waving = false});

  @override
  Widget build(BuildContext context) {
    final headSize = size;
    final earSize = headSize * 0.28;
    final eyeSize = headSize * 0.12;
    final noseSize = headSize * 0.14;

    return SizedBox(
      width: headSize,
      height: headSize + earSize * 0.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ears
          Positioned(
            left: headSize * 0.12,
            top: 0,
            child: Container(
              width: earSize,
              height: earSize,
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: headSize * 0.12,
            top: 0,
            child: Container(
              width: earSize,
              height: earSize,
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Head
          Positioned(
            top: earSize * 0.45,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.12),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),

          // Stripes (simple horizontal bars)
          Positioned(
            top: headSize * 0.18,
            child: SizedBox(
              width: headSize * 0.7,
              height: headSize * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: headSize * 0.55,
                    height: headSize * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Eyes
          Positioned(
            top: headSize * 0.38,
            left: headSize * 0.22,
            child: Container(
              width: eyeSize,
              height: eyeSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: eyeSize * 0.45,
                  height: eyeSize * 0.45,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: headSize * 0.38,
            right: headSize * 0.22,
            child: Container(
              width: eyeSize,
              height: eyeSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: eyeSize * 0.45,
                  height: eyeSize * 0.45,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Nose / muzzle
          Positioned(
            top: headSize * 0.55,
            child: Column(
              children: [
                Container(
                  width: noseSize * 1.4,
                  height: noseSize * 0.9,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(noseSize * 0.6),
                  ),
                  child: Center(
                    child: Container(
                      width: noseSize,
                      height: noseSize * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: headSize * 0.42,
                  height: headSize * 0.06,
                  color: Color.fromRGBO(255, 255, 255, 0.9),
                ),
              ],
            ),
          ),

          // Smile / whiskers
          Positioned(
            top: headSize * 0.74,
            left: headSize * 0.12,
            child: Container(
              width: headSize * 0.24,
              height: 2,
              color: Colors.black54,
            ),
          ),
          Positioned(
            top: headSize * 0.74,
            right: headSize * 0.12,
            child: Container(
              width: headSize * 0.24,
              height: 2,
              color: Colors.black54,
            ),
          ),

          // Optional waving paw (decorative)
          if (waving)
            Positioned(
              right: -headSize * 0.06,
              bottom: headSize * 0.18,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: headSize * 0.32,
                  height: headSize * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
