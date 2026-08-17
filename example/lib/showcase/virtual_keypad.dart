import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

import '../poster/poster_tokens.dart';

/// Duration of the letters-pad slide in/out. Public because the showcase's
/// typist awaits this same constant to sync with the animation.
const Duration kLetterPadSlide = Duration(milliseconds: 260);

/// A fake soft keyboard drawn inside the device screen, below the plate.
///
/// Purely decorative: taps do nothing, but a key can be flashed
/// programmatically by passing its label as [highlightedKey].
class VirtualKeypad extends StatefulWidget {
  const VirtualKeypad({
    super.key,
    required this.highlightedKey,
    this.compact = false,
    this.showLetters = false,
    this.onKey,
    this.digitAlphabet = PlateAlphabet.persianDigits,
    this.letterAlphabet = PlateAlphabet.persianPlateLetters,
  });

  /// Label of the key to flash; null flashes nothing.
  final String? highlightedKey;

  /// true on mobile (shorter keys), false on tablet.
  final bool compact;

  /// When true, the letters pad slides in over the digit pad.
  final bool showLetters;

  /// Fires with the tapped letter from the letters pad.
  final ValueChanged<String>? onKey;

  /// Alphabet used to render the digit grid's labels.
  final PlateAlphabet digitAlphabet;

  /// Alphabet used to render the letters pad's labels.
  final PlateAlphabet letterAlphabet;

  @override
  State<VirtualKeypad> createState() => _VirtualKeypadState();
}

class _VirtualKeypadState extends State<VirtualKeypad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kLetterPadSlide,
  );

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showLetters) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant VirtualKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLetters != oldWidget.showLetters) {
      if (widget.showLetters) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyHeight = widget.compact ? 44 : 56;
    // Fixed inner height so the pad never resizes when the letters layer
    // appears: 4 digit rows plus the three 6px gaps between them.
    final double innerHeight = _rows.length * keyHeight + 3 * 6;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: innerHeight,
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
                                  _rows[r][c] == widget.highlightedKey,
                              digitAlphabet: widget.digitAlphabet,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(child: _buildLettersLayer(innerHeight)),
        ],
      ),
    );
  }

  Widget _buildLettersLayer(double innerHeight) {
    final List<String> alphabetLetters = widget.letterAlphabet.characters;
    final int rowCount = (alphabetLetters.length / 4).ceil();
    // Divide the fixed inner height (minus the gaps between rows) so the
    // letters pad always ends flush with the digit pad.
    final double rowHeight =
        (innerHeight - 6 * (rowCount - 1)) / rowCount;

    // Pad the final row with blank spacers so every row has 4 columns.
    final List<String> letters = [...alphabetLetters];
    while (letters.length < rowCount * 4) {
      letters.add('');
    }

    final TextDirection direction =
        widget.letterAlphabet == PlateAlphabet.persianPlateLetters
            ? TextDirection.rtl
            : TextDirection.ltr;

    final Widget grid = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: direction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rowCount; r++) ...[
              if (r > 0) const SizedBox(height: 6),
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    for (var c = 0; c < 4; c++) ...[
                      if (c > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final letter = letters[r * 4 + c];
                            return GestureDetector(
                              onTap: () => widget.onKey?.call(letter),
                              child: _Key(
                                label: letter,
                                highlighted: letter.isNotEmpty &&
                                    letter == widget.highlightedKey,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final slide = SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: grid,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => IgnorePointer(
        ignoring: _controller.isDismissed,
        child: child,
      ),
      child: slide,
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.highlighted,
    this.digitAlphabet,
  });

  final String label;
  final bool highlighted;

  /// When set, [label] is rendered through this alphabet (digit grid keys).
  /// When null, [label] is shown verbatim (letters grid keys, backspace).
  final PlateAlphabet? digitAlphabet;

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
          label == '⌫' || digitAlphabet == null
              ? label
              : digitAlphabet!.render(label),
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
