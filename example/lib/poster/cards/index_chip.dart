import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';
import 'bevel_panel.dart';

/// The 01–12 numbered chip of DESIGN_SPEC.md §4.10 — itself a [BevelPanel].
///
/// Archivo `wght 800` / `wdth 104`, 44–78 design px (see
/// `PosterType.indexChip`). Chip 01 carries the design's `-3.4deg` tilt.
class IndexChip extends StatelessWidget {
  const IndexChip({
    super.key,
    required this.label,
    this.kind = BevelKind.chipWhite,
    this.fontDesignPx = 56,
    this.rotationDegrees = 0,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 14),
    this.screws,
    this.variantGround = false,
    this.shadow = const BevelShadow(left: 5, top: 8, right: 5, bottom: 8),
    this.inkColor,
  }) : assert(
          kind == BevelKind.chipWhite || kind == BevelKind.chipDark,
          'An index chip is either chipWhite or chipDark.',
        );

  /// Chip 01, tilted `-3.4deg` as in the design.
  const IndexChip.tilted({
    super.key,
    required this.label,
    this.kind = BevelKind.chipWhite,
    this.fontDesignPx = 78,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 14),
    this.screws,
    this.variantGround = false,
    this.shadow = const BevelShadow(left: 5, top: 8, right: 5, bottom: 8),
    this.inkColor,
  })  : rotationDegrees = -3.4,
        assert(
          kind == BevelKind.chipWhite || kind == BevelKind.chipDark,
          'An index chip is either chipWhite or chipDark.',
        );

  final String label;
  final BevelKind kind;
  final double fontDesignPx;
  final double rotationDegrees;

  /// Inner padding in DESIGN px.
  final EdgeInsets padding;

  final ScrewDots? screws;
  final bool variantGround;
  final BevelShadow shadow;
  final Color? inkColor;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final bool white = kind == BevelKind.chipWhite;
    final Color ink =
        inkColor ?? (white ? PosterColors.chipInk : PosterColors.inkDisplay1);

    final Widget chip = BevelPanel(
      style: white ? BevelStyle.chipWhite : BevelStyle.chipDark,
      groundColor: bevelGroundColor(kind),
      groundGradient: bevelGroundGradient(kind, variant: variantGround),
      screws: screws,
      shadow: shadow,
      padding: padding,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: PosterType.indexChip(metrics.f, fontDesignPx).copyWith(
          color: ink,
          height: 1.0,
        ),
      ),
    );

    if (rotationDegrees == 0) return chip;
    return Transform.rotate(
      angle: rotationDegrees * math.pi / 180,
      child: chip,
    );
  }
}

/// Pins an [IndexChip] to a card's corner per §4.10: `left/right −24..−34px`,
/// `top −22..−34px`, measured in DESIGN px and scaled through [metrics].
///
/// Returns a [Positioned], so call it directly inside a card's `Stack`:
///
/// ```dart
/// Stack(clipBehavior: Clip.none, children: [
///   card,
///   pinIndexChip(metrics: m, chip: const IndexChip(label: '03')),
/// ])
/// ```
Positioned pinIndexChip({
  required PosterMetrics metrics,
  required Widget chip,
  double left = -28,
  double? right,
  double top = -26,
}) {
  return Positioned(
    left: right == null ? metrics.px(left) : null,
    right: right == null ? null : metrics.px(right),
    top: metrics.px(top),
    child: chip,
  );
}
