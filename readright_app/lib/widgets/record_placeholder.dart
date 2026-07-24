import 'package:flutter/material.dart';
import '../widgets/mascot_widget.dart';

class RecordPlaceholder extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const RecordPlaceholder({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  State<RecordPlaceholder> createState() => _RecordPlaceholderState();
}

class _RecordPlaceholderState extends State<RecordPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.isRecording;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Use the friendly tiger mascot instead of a boring circle!
        AnimatedBuilder(
          animation: _ctl,
          builder: (context, child) {
            final scale = isRecording ? 1.1 : _scale.value;
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRecording
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [Colors.orange.shade400, Colors.orange.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : Colors.orange)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Tiger mascot in the center
                  MascotWidget(size: 75, animated: !isRecording),
                  // Recording indicator overlay
                  if (isRecording)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.fiber_manual_record,
                              color: Colors.white,
                              size: 10,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'REC',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Child-friendly instructions
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecording ? Icons.stop_circle : Icons.mic,
                  size: 32,
                  color: isRecording
                      ? Colors.red.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  isRecording
                      ? "🎤 Recording... You're doing great!"
                      : "👆 Tap the tiger to say the word!",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  isRecording
                      ? 'Speak clearly and loudly'
                      : 'Remember: speak slowly and clearly',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
