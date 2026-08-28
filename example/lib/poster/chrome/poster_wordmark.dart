import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The display wordmark from DESIGN_SPEC.md §6 "Chrome" and §2.
///
/// Four uppercase lines — PLATE / INPUT / FOR THE / ROAD — in Archivo
/// `wght 900`, `wdth 79`, 176 design px, line height `.86`, tracking
/// `-.045em`. It is the largest element on the page and fills the lower-left
/// quadrant the device used to occupy (anchor `.036, .172`, width `.396`).
///
/// Two details carry the design:
///
///   * Lines 1 and 2 glow — `0 0 80px rgba(150,180,220,.28–.32)`. Rendered as
///     a `Text.shadows` blur, scaled through [PosterMetrics] so it tracks the
///     type size.
///   * Line 4 ("ROAD") is a `#1A2130` base with a brighter `#BCD3F0` copy laid
///     over it and cut on a hard diagonal — `linear-gradient(103.5deg,
///     opaque 0→46%, transparent 46%)`. The two stops sit at the *same*
///     position (46%) so the edge is a crisp cut, not a fade. A `ShaderMask`
///     with a `LinearGradient` whose begin/end are derived from 103.5°
///     reproduces it.
class PosterWordmark extends StatelessWidget {
  const PosterWordmark({super.key});

  /// The `#BCD3F0` glow lines carry a 80 design-px blur at full scale.
  static const double _glowBlurDesignPx = 80;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double f = metrics.f;

    // Base display style — 176 design px through the fluid factor, so every
    // metric below (line height, tracking) rides on the same size.
    final TextStyle base = PosterType.wordmark(f);

    // The soft blue glow on lines 1–2. `.28–.32` in the source; a single .30
    // reads the same at this blur radius.
    final List<Shadow> lineGlow = <Shadow>[
      Shadow(
        color: const Color(0x4D96B4DC), // rgba(150,180,220,.30)
        blurRadius: metrics.px(_glowBlurDesignPx),
      ),
    ];

    return SizedBox(
      width: metrics.px(760),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'PLATE',
            style: base.copyWith(
              color: PosterColors.inkDisplay1,
              shadows: lineGlow,
            ),
          ),
          Text(
            'INPUT',
            style: base.copyWith(
              color: PosterColors.inkDisplay2,
              shadows: lineGlow,
            ),
          ),
          Text(
            'FOR THE',
            style: base.copyWith(color: PosterColors.inkDisplay3),
          ),
          _RoadLine(base: base),
        ],
      ),
    );
  }
}

/// The fourth wordmark line: a dark `#1A2130` base with a brighter
/// `#BCD3F0` copy diagonally cut across it.
class _RoadLine extends StatelessWidget {
  const _RoadLine({required this.base});

  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    final Text dark = Text(
      'ROAD',
      style: base.copyWith(color: PosterColors.inkDisplay4),
    );
    final Text cut = Text(
      'ROAD',
      style: base.copyWith(color: PosterColors.inkDisplayCut),
    );

    return Stack(
      children: <Widget>[
        dark,
        // The bright copy, masked to the diagonal.
        Positioned.fill(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (Rect bounds) {
              // `linear-gradient(103.5deg, opaque 0–25%, transparent 25%)`.
              // CSS angles run clockwise from "to top"; 103.5° points right
              // and just past horizontal (down a hair). Two stops at the same
              // 25% position keep the edge hard rather than feathered.
              final Alignment begin = _alignmentForCssAngle(103.5);
              return LinearGradient(
                begin: begin,
                end: -begin,
                colors: const <Color>[
                  Color(0xFFFFFFFF), // opaque — bright copy shows (R only)
                  Color(0xFFFFFFFF),
                  Color(0x00FFFFFF), // transparent — bright copy hidden (OAD)
                ],
                stops: const <double>[0.0, 0.25, 0.25],
              ).createShader(bounds);
            },
            child: cut,
          ),
        ),
      ],
    );
  }
}

/// Maps a CSS gradient angle (degrees, clockwise from "to top") to the
/// `begin` [Alignment] of a Flutter [LinearGradient] whose `end` is its
/// negation. The gradient axis runs from `begin` (the 0% edge) toward `end`
/// (the 100% edge).
Alignment _alignmentForCssAngle(double deg) {
  // CSS "to top" is 0°, increasing clockwise. The 100%-end direction vector
  // in screen space (y down) is (sin θ, −cos θ); begin is the opposite edge.
  final double rad = deg * math.pi / 180.0;
  final double dx = math.sin(rad);
  final double dy = -math.cos(rad);
  return Alignment(-dx, -dy);
}
