import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

import '../poster/poster_tokens.dart';

/// Backspace's key label; not a character any alphabet accepts.
const String kBackspaceKey = 'BACKSPACE';

/// Duration of the letters-pad slide in/out. Public because the showcase's
/// typist awaits this same constant to sync with the animation.
const Duration kLetterPadSlide = Duration(milliseconds: 260);

/// A fake soft keyboard drawn inside the device screen, below the plate.
///
/// Taps report through [onKey] when set; a key can also be flashed
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
    this.activeAlphabet,
    this.unavailableKeys = const {},
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

  /// The focused slot's alphabet. Keys outside it render disabled — submit()
  /// would reject them anyway — since it may be a subset of [digitAlphabet]
  /// or [letterAlphabet]. Null disables no keys (e.g. no slot is focused).
  final PlateAlphabet? activeAlphabet;

  /// Keys that are currently barred by a validation rule (e.g. a forbidden
  /// letter pair). They stay in the grid at the same position; they render
  /// disabled and swallow taps. Never affects layout.
  final Set<String> unavailableKeys;

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
                          Expanded(child: _buildDigitKey(_rows[r][c])),
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

  /// Whether [key] should accept taps: always true for backspace, otherwise
  /// only when it is in [PlateAlphabet.characters] for the alphabet driving
  /// the pad it belongs to (the focused slot's alphabet when known, else the
  /// pad's own alphabet) — submit() would reject anything else — and not
  /// currently barred by [VirtualKeypad.unavailableKeys].
  bool _keyEnabled(String key, PlateAlphabet ownAlphabet) {
    if (key.isEmpty) return false;
    if (key == kBackspaceKey) return true;
    return (widget.activeAlphabet ?? ownAlphabet).accepts(key) &&
        !widget.unavailableKeys.contains(key);
  }

  Widget _buildDigitKey(String rawLabel) {
    final bool isBackspace = rawLabel == '⌫';
    final String key = isBackspace ? kBackspaceKey : rawLabel;
    final bool enabled = _keyEnabled(key, widget.digitAlphabet);
    return GestureDetector(
      onTap: enabled ? () => widget.onKey?.call(key) : null,
      child: _Key(
        label: rawLabel,
        highlighted: rawLabel.isNotEmpty && rawLabel == widget.highlightedKey,
        enabled: enabled,
        digitAlphabet: widget.digitAlphabet,
      ),
    );
  }

  Widget _buildLettersLayer(double innerHeight) {
    final List<String> alphabetLetters = widget.letterAlphabet.characters;
    // A roughly square grid, its width derived from how many letters there
    // are rather than fixed, so a 16-letter and a 26-letter alphabet both
    // lay out sensibly.
    //
    // Layout invariant: columns/rowCount are derived from
    // letterAlphabet.characters.length only. activeAlphabet and
    // unavailableKeys must never narrow the list the grid is built from —
    // they only affect whether an already-placed key renders enabled — or
    // the pad would reflow when a validation rule fires.
    final int columns = math.sqrt(alphabetLetters.length).ceil();
    final int rowCount = (alphabetLetters.length / columns).ceil();
    // Divide the fixed inner height (minus the gaps between rows) so the
    // letters pad always ends flush with the digit pad.
    final double rowHeight =
        (innerHeight - 6 * (rowCount - 1)) / rowCount;

    // Pad the final row with blank spacers so every row has the same width.
    final List<String> letters = [...alphabetLetters];
    while (letters.length < rowCount * columns) {
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
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final letter = letters[r * columns + c];
                            final enabled =
                                _keyEnabled(letter, widget.letterAlphabet);
                            return GestureDetector(
                              onTap: enabled
                                  ? () => widget.onKey?.call(letter)
                                  : null,
                              child: _Key(
                                label: letter,
                                highlighted: letter.isNotEmpty &&
                                    letter == widget.highlightedKey,
                                enabled: enabled,
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
    required this.enabled,
    this.digitAlphabet,
  });

  final String label;
  final bool highlighted;

  /// Barred by a validation rule (or outside the active alphabet) when
  /// false. Stays in the grid at the same position; a disabled key is never
  /// highlighted — [highlighted] always wins visually because a barred key
  /// can't be tapped in the first place, so the two never conflict.
  final bool enabled;

  /// When set, [label] is rendered through this alphabet (digit grid keys).
  /// When null, [label] is shown verbatim (letters grid keys, backspace).
  final PlateAlphabet? digitAlphabet;

  @override
  Widget build(BuildContext context) {
    // Empty label = blank spacer, no border.
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color ink = highlighted
        ? const Color(0xFF05080B)
        : enabled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.30);

    // Highlight presses stay quick (90ms in / 160ms out); an enabled<->
    // disabled transition tweens a bit slower (180ms) so the grey-out reads
    // as a deliberate fade rather than a snap.
    final Duration duration = Duration(
      milliseconds: highlighted ? 90 : (enabled ? 160 : 180),
    );

    return AnimatedScale(
      scale: highlighted ? 0.94 : 1.0,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted ? PosterTokens.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted
                ? PosterTokens.accent
                : enabled
                    ? PosterTokens.hairline
                    : PosterTokens.hairline.withValues(
                        alpha: PosterTokens.hairline.a * 0.5,
                      ),
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
