// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

import 'package:flutter/material.dart';

part 'laptop_deck.parts.dart';

/// Width of the milled-aluminium chassis edge painted by [LaptopChassisEdge].
const laptopEdgeWidth = 8.0;

const _edgeColor = Color(0xFF8A909C);

/// Corner rounding shared by the deck and its keyboard well — the desktop
/// preset's own [DeviceConfig.screenRadius], so the base's corners read at the
/// same size as the screen above them.
///
/// Kept at the screen's radius rather than the body's larger one: the well is
/// only 6px of padding away from the bottom keycap row, and a corner much
/// rounder than this eats into the outer keys.
const _cornerRadius = 24.0;

/// The deck's outline. All four corners are rounded, not just the bottom pair:
/// the deck is tilted into perspective as a free-standing slab, so its top
/// corners are just as visible as its bottom ones and read as sharp points
/// against the trapezoid if left square.
///
/// Public because the dissolve overlay stacked above the deck paints square
/// blocks and must be clipped to this same shape, or it squares off the
/// corners mid-transition.
const laptopEdgeRadius = BorderRadius.all(Radius.circular(_cornerRadius));
const _edgeRadius = laptopEdgeRadius;

/// The recessed keyboard well.
const _wellRadius = BorderRadius.all(Radius.circular(_cornerRadius));

/// The chassis rim around the laptop deck: a thin gray-metal ring matching
/// the body's own frame. [DeviceFrame] stacks this on top of the deck's
/// pixel-dissolve reveal, outside it, so the rim reads as opaque body from
/// the very first frame of the intro — never waiting on the dissolve to
/// "glitch" it into view.
class LaptopChassisEdge extends StatelessWidget {
  const LaptopChassisEdge({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(
          BorderSide(color: _edgeColor, width: laptopEdgeWidth),
        ),
        borderRadius: _edgeRadius,
      ),
    );
  }
}

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
  final String? pressedKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9CA2AE), Color(0xFFAEB4C0), Color(0xFF8E94A0), Color(0xFF767C88)],
          stops: [0, .22, .62, 1],
        ),
        borderRadius: _edgeRadius,
        boxShadow: [
          BoxShadow(color: Color(0x9E000000), blurRadius: 40, offset: Offset(0, 26)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            // The underside is a single solid slab, not a cross-faded face: the
            // moment the deck tips past edge-on it snaps to fully opaque so the
            // whole back reads as milled body, never a frosted pane with the
            // chassis glowing through its lower half. The swap is invisible
            // because at edge-on the deck's projected height is ~0.
            child: Opacity(
              opacity: backOpacity <= 0 ? 0 : 1,
              child: const _BackPanel(),
            ),
          ),
          Opacity(
            opacity: frontOpacity.clamp(0, 1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 22, 40, 6),
              child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                      // The bottom keycap row sits only 6px inside the well, so
                      // without this the outer caps paint straight over the
                      // corner curve and square it off.
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: _wellRadius,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0B0D10), Color(0xFF14171C)],
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0xB3000000), blurRadius: 14, offset: Offset(0, 4)),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // The deck's box shrinks during fold/unfold beats and
                          // whenever the frame is scaled down to fit tight
                          // constraints (e.g. a maximised window mid-resize), so
                          // the well can be handed less height than the rows'
                          // natural total. Scale every row and gap down to fit
                          // rather than overflowing — an overflow here forces an
                          // expensive error-render on the busiest possible frame
                          // and has crashed the GL embedder on Linux.
                          final scale = constraints.hasBoundedHeight
                              ? (constraints.maxHeight / _deckWellHeight).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 1.0;
                          // Where the last row starts, and its midpoint, as a
                          // fraction of the column's natural height. The whole
                          // keyboard is masked with a top-to-bottom gradient
                          // that stays fully opaque down to that midpoint, then
                          // dissolves to opacity 0 at the column's very bottom —
                          // so the top rows read crisply and only the last row
                          // fades off the bottom edge of the deck.
                          final totalHeight =
                              deckRows.fold<double>(0, (h, r) => h + r.height) +
                              _rowGap * (deckRows.length - 1);
                          final lastMid =
                              (totalHeight - deckRows.last.height / 2) /
                              totalHeight;
                          return ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0, lastMid, 1],
                            ).createShader(rect),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (
                                  var r = 0;
                                  r < deckRows.length;
                                  r++
                                ) ...[
                                  _DeckRowStrip(
                                    row: deckRows[r],
                                    scale: scale,
                                    onKey: onKey,
                                    pressedKey: pressedKey,
                                  ),
                                  if (r < deckRows.length - 1)
                                    SizedBox(height: _rowGap * scale),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
