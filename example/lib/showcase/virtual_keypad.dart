import 'package:flutter/material.dart';
import 'package:plate_number/showcase/theme/poster_tokens.dart';
import 'package:plate_number/tools.dart';

/// A fake soft keyboard drawn inside the device screen, below the plate.
///
/// Purely decorative: taps do nothing, but a key can be flashed
/// programmatically by passing its label as [highlightedKey].
class VirtualKeypad extends StatelessWidget {
  const VirtualKeypad({
    super.key,
    required this.highlightedKey,
    this.compact = false,
  });

  /// Label of the key to flash; null flashes nothing.
  final String? highlightedKey;

  /// true on mobile (shorter keys), false on tablet.
  final bool compact;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final double keyHeight = compact ? 44 : 56;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < _rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 6),
            SizedBox(
              height: keyHeight,
              child: Row(
                children: [
                  for (var c = 0; c < _rows[r].length; c++) ...[
                    if (c > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _Key(
                        label: _rows[r][c],
                        highlighted: _rows[r][c].isNotEmpty &&
                            _rows[r][c] == highlightedKey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // Empty label = blank spacer, no border.
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color ink = highlighted ? const Color(0xFF05080B) : Colors.white;

    return AnimatedScale(
      scale: highlighted ? 0.94 : 1.0,
      duration: Duration(milliseconds: highlighted ? 90 : 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: highlighted ? 90 : 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? PosterTokens.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted ? PosterTokens.accent : PosterTokens.hairline,
            width: 1,
          ),
        ),
        child: Text(
          label == '⌫' ? '⌫' : toPersianDigits(label),
          style: TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
