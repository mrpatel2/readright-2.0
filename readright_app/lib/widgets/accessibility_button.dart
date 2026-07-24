import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accessibility_service.dart';

/// Accessibility control with larger fonts and contrast toggle
class AccessibilityButton extends StatelessWidget {
  final bool isStudentMode;

  const AccessibilityButton({super.key, this.isStudentMode = false});

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityService>();
    final theme = Theme.of(context);
    final TextStyle itemTextStyle =
        theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final Color iconReadableColor = theme.colorScheme.onSurface;

    // For students we keep the larger icon and a compact popup (existing behavior)
    if (isStudentMode) {
      return PopupMenuButton<int>(
        tooltip: 'Accessibility Options',
        icon: Icon(
          Icons.accessibility_new,
          size: 32,
          color: Colors.orange.shade700,
        ),
        onSelected: (value) {},
        itemBuilder: (ctx) => [
          // Student menu: text size controls only
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                const Icon(Icons.text_increase, size: 20),
                const SizedBox(width: 12),
                Text('Increase Text Size', style: itemTextStyle),
              ],
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Row(
              children: [
                const Icon(Icons.text_decrease, size: 20),
                const SizedBox(width: 12),
                Text('Decrease Text Size', style: itemTextStyle),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Reset (' + acc.textScale.toStringAsFixed(1) + 'x)',
                  style: itemTextStyle,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Teacher mode: keep a dropdown menu. High-contrast option removed (UI only per request).
    return PopupMenuButton<int>(
      tooltip: 'Accessibility Options',
      icon: Icon(Icons.accessibility_new, size: 24, color: iconReadableColor),
      // Color-blind mode gives a gentle background to the popup; otherwise default
      color: acc.colorBlind ? Colors.blue.shade50 : null,
      onSelected: (value) {
        final svc = context.read<AccessibilityService>();
        if (value == 5) svc.toggleColorBlind();
        // Intentionally do nothing for text-size selections to preserve hard-coded sizes.
      },
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: 5,
          checked: acc.colorBlind,
          child: Row(
            children: [
              Icon(Icons.color_lens, size: 20, color: iconReadableColor),
              const SizedBox(width: 12),
              Text(
                'Color-blind Mode',
                style: itemTextStyle.copyWith(color: iconReadableColor),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.text_increase, size: 20, color: iconReadableColor),
              const SizedBox(width: 12),
              Text(
                'Increase Text Size',
                style: itemTextStyle.copyWith(color: iconReadableColor),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(Icons.text_decrease, size: 20, color: iconReadableColor),
              const SizedBox(width: 12),
              Text(
                'Decrease Text Size',
                style: itemTextStyle.copyWith(color: iconReadableColor),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20, color: iconReadableColor),
              const SizedBox(width: 12),
              Text(
                'Reset (${acc.textScale.toStringAsFixed(1)}x)',
                style: itemTextStyle.copyWith(color: iconReadableColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
