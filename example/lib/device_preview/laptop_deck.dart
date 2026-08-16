import 'package:flutter/material.dart';

part 'laptop_deck.parts.dart';

/// One row of the laptop keyboard: a height and a list of (label, flex) keys.
class DeckRow {
  const DeckRow(this.height, this.keys);
  final double height;
  final List<DeckKey> keys;
}

class DeckKey {
  const DeckKey(this.label, {this.flex = 1});
  final String label;
  final double flex;
}

List<DeckKey> _row(String spec, {Map<int, double> flex = const {}}) {
  final parts = spec.split('|');
  return [
    for (var i = 0; i < parts.length; i++)
      DeckKey(parts[i], flex: flex[i] ?? 1),
  ];
}

/// A Persian (Farsi) keyboard layout, purely decorative — it dresses the
/// laptop preset but doesn't feed input anywhere.
final deckRows = <DeckRow>[
  DeckRow(32, _row('esc|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|⏻', flex: {0: 1.7})),
  DeckRow(52, _row('`|1|2|3|4|5|6|7|8|9|0|-|=|⌫', flex: {13: 1.9})),
  DeckRow(52, _row('⇥|ض|ص|ث|ق|ف|غ|ع|ه|خ|ح|ج|چ', flex: {0: 1.5})),
  DeckRow(52, _row('⇪|ش|س|ی|ب|ل|ا|ت|ن|م|ک|گ|⏎', flex: {0: 1.8, 12: 2.0})),
  DeckRow(52, _row('⇧|ظ|ط|ز|ر|ذ|د|پ|و|ژ|/|⇧', flex: {0: 2.4, 11: 2.4})),
  DeckRow(52, const [
    DeckKey('fn'), DeckKey('⌃'), DeckKey('⌥'), DeckKey('⌘', flex: 1.4),
    DeckKey('', flex: 6.6),
    DeckKey('⌘', flex: 1.4), DeckKey('⌥'),
    DeckKey('◂'), DeckKey('▴'), DeckKey('▾'), DeckKey('▸'),
  ]),
];

/// The laptop base: milled aluminium and a recessed keyboard well with
/// keycaps. Laid out at its full physical depth — [DeviceFrame] tilts it
/// into perspective, so it unfolds out of the body as the frame morphs.
class LaptopDeck extends StatelessWidget {
  const LaptopDeck({
    super.key,
    required this.frontOpacity,
    required this.backOpacity,
    this.onKey,
    this.pressedKey,
  });

  /// Keyboard side, facing us while the laptop is open.
  final double frontOpacity;

  /// Underside, seen once the deck has swung past edge-on. The two cross-fade
  /// through the fold, so neither ever pops.
  final double backOpacity;

  /// Called with the tapped key's reported label, e.g. "A", "BACKSPACE".
  final ValueChanged<String>? onKey;

  /// Label of a key to render as held down, e.g. from a hardware keypress.
  /// Applies to the deck rows only, not the numpad.
  final String? pressedKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2126), Color(0xFF2A2E35), Color(0xFF1A1D22), Color(0xFF0C0E11)],
          stops: [0, .22, .62, 1],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: Color(0x9E000000), blurRadius: 40, offset: Offset(0, 26)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: backOpacity.clamp(0, 1),
              child: const _BackPanel(),
            ),
          ),
          Opacity(
            opacity: frontOpacity.clamp(0, 1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 22, 40, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 77,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0B0D10), Color(0xFF14171C)],
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0xB3000000), blurRadius: 14, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (final row in deckRows) ...[
                            SizedBox(
                              height: row.height,
                              child: Row(
                                children: [
                                  for (var i = 0; i < row.keys.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(
                                      flex: (row.keys[i].flex * 100).round(),
                                      child: _Key(
                                        label: row.keys[i].label,
                                        icon: _iconFor(row.keys[i].label),
                                        onKey: onKey,
                                        pressedLabel: pressedKey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: _rowGap),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(flex: 23, child: _Numpad(onKey: onKey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
