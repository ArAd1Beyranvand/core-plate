import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The per-card extras at the end of DESIGN_SPEC.md §4. Each one is a leaf
/// widget sized in DESIGN px through [PosterMetrics]; the cards themselves
/// (P7) position them.

/// Card 01 — vertical IR flag strip, 26px wide, inset `left 22, top 22,
/// bottom 22`, with `inset 0 0 0 2px rgba(0,8,26,.55)` and a
/// `0 0 0 1px rgba(226,238,255,.30)` outline.
class IrFlagStrip extends StatelessWidget {
  const IrFlagStrip({
    super.key,
    this.width = 26,
    this.muted = false,
    this.opacity = 1,
    this.innerRing = true,
  });

  /// Strip width in DESIGN px.
  final double width;

  /// Card 02's faded bands.
  final bool muted;
  final double opacity;

  /// The 2px inner ring + 1px outline of card 01. Card 02's 5px strip has
  /// neither.
  final bool innerRing;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final List<Color> bands = muted
        ? const <Color>[
            PosterColors.flagMutedGreen,
            PosterColors.flagMutedWhite,
            PosterColors.flagMutedRed,
          ]
        : const <Color>[
            PosterColors.flagBrightGreen,
            PosterColors.flagBrightWhite,
            PosterColors.flagBrightRed,
          ];

    Widget strip = SizedBox(
      width: metrics.px(width),
      child: Column(
        children: <Widget>[
          for (final Color band in bands)
            Expanded(child: ColoredBox(color: band)),
        ],
      ),
    );

    if (innerRing) {
      strip = CustomPaint(
        foregroundPainter: _FlagRingPainter(
          inner: const Color(0x8C00081A), // rgba(0,8,26,.55)
          innerWidth: metrics.px(2),
          outline: const Color(0x4DE2EEFF), // rgba(226,238,255,.30)
          outlineWidth: metrics.px(1),
        ),
        child: strip,
      );
    }

    if (opacity >= 1) return strip;
    return Opacity(opacity: opacity, child: strip);
  }
}

class _FlagRingPainter extends CustomPainter {
  const _FlagRingPainter({
    required this.inner,
    required this.innerWidth,
    required this.outline,
    required this.outlineWidth,
  });

  final Color inner;
  final double innerWidth;
  final Color outline;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect.deflate(innerWidth / 2),
      Paint()
        ..color = inner
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerWidth,
    );
    canvas.drawRect(
      rect.inflate(outlineWidth / 2),
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );
  }

  @override
  bool shouldRepaint(_FlagRingPainter oldDelegate) {
    return oldDelegate.inner != inner ||
        oldDelegate.innerWidth != innerWidth ||
        oldDelegate.outline != outline ||
        oldDelegate.outlineWidth != outlineWidth;
  }
}

/// Card 02 — the faded 5px vertical flag strip, `right 20, top 20, bottom 20`,
/// opacity `.8`.
class FadedFlagStrip extends StatelessWidget {
  const FadedFlagStrip({super.key, this.width = 5});

  final double width;

  @override
  Widget build(BuildContext context) {
    return IrFlagStrip(
      width: width,
      muted: true,
      opacity: 0.8,
      innerRing: false,
    );
  }
}

/// Card 05 — the two-tone divider bar: 6px total, 3px dark
/// `rgba(0,8,26,.6)` over 3px light `rgba(226,238,255,.46)`.
class TwoToneDivider extends StatelessWidget {
  const TwoToneDivider({
    super.key,
    this.width,
    this.bandThickness = 3,
    this.dark = const Color(0x9900081A),
    this.light = const Color(0x75E2EEFF),
  });

  /// Length in DESIGN px. Null stretches to the parent.
  final double? width;
  final double bandThickness;
  final Color dark;
  final Color light;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double band = metrics.px(bandThickness);
    return SizedBox(
      width: width == null ? double.infinity : metrics.px(width!),
      height: band * 2,
      child: Column(
        children: <Widget>[
          SizedBox(height: band, child: ColoredBox(color: dark)),
          SizedBox(height: band, child: ColoredBox(color: light)),
        ],
      ),
    );
  }
}

/// Card 05 — the footer row: a 44×26 IR flag beside `IR · MOTORBIKE`.
class IrFlagFooter extends StatelessWidget {
  const IrFlagFooter({
    super.key,
    this.label = 'IR · MOTORBIKE',
    this.flagWidth = 44,
    this.flagHeight = 26,
    this.gap = 12,
  });

  final String label;
  final double flagWidth;
  final double flagHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: metrics.px(flagWidth),
          height: metrics.px(flagHeight),
          child: Column(
            children: const <Widget>[
              Expanded(child: ColoredBox(color: PosterColors.flagBrightGreen)),
              Expanded(child: ColoredBox(color: PosterColors.flagBrightWhite)),
              Expanded(child: ColoredBox(color: PosterColors.flagBrightRed)),
            ],
          ),
        ),
        SizedBox(width: metrics.px(gap)),
        Text(label, style: PosterType.metaWeak(metrics.f)),
      ],
    );
  }
}

/// Card 09 — the EU badge column: 34px wide, twelve `#F5D021` stars (r 1.9 on
/// a circle of r 11.5 about the centre of a 34-unit box) over a `D` in
/// Martian Mono `wght 700` 15px.
class EuBadgeColumn extends StatelessWidget {
  const EuBadgeColumn({
    super.key,
    this.width = 34,
    this.letter = 'D',
    this.ground = PosterColors.cardBlueDe,
  });

  final double width;
  final String letter;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double side = metrics.px(width);
    return ColoredBox(
      color: ground,
      child: SizedBox(
        width: side,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _EuStarsPainter(
                  starRadius: side * (1.9 / 34),
                  ringRadius: side * (11.5 / 34),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: metrics.px(6)),
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: PosterFonts.martianMono,
                  fontWeight: FontWeight.w700,
                  fontSize: 15 * metrics.f,
                  height: 1.0,
                  color: PosterColors.inkDisplay1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EuStarsPainter extends CustomPainter {
  const _EuStarsPainter({required this.starRadius, required this.ringRadius});

  final double starRadius;
  final double ringRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()..color = PosterColors.euStar;
    for (int i = 0; i < 12; i++) {
      final double angle = -math.pi / 2 + i * (math.pi / 6);
      final Offset at = centre +
          Offset(math.cos(angle) * ringRadius, math.sin(angle) * ringRadius);
      canvas.drawPath(_star(at, starRadius), paint);
    }
  }

  /// A five-pointed star, point up.
  Path _star(Offset centre, double radius) {
    final Path path = Path();
    final double inner = radius * 0.382;
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? radius : inner;
      final double angle = -math.pi / 2 + i * (math.pi / 5);
      final Offset p = centre + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_EuStarsPainter oldDelegate) {
    return oldDelegate.starRadius != starRadius ||
        oldDelegate.ringRadius != ringRadius;
  }
}

/// Card 09 — the red `FLARE — SERIAL FIELD` tag: ground `#F02C1E`, padding
/// `9 14 10`, `inset 0 2px 0 rgba(230,224,244,.6)` and
/// `inset 0 -2px 0 rgba(50,10,30,.5)`.
class RedTag extends StatelessWidget {
  const RedTag({super.key, this.label = 'SERIAL FIELD'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return CustomPaint(
      foregroundPainter: _RedTagEdgesPainter(
        top: const Color(0x99E6E0F4), // rgba(230,224,244,.6)
        bottom: const Color(0x80320A1E), // rgba(50,10,30,.5)
        thickness: metrics.px(2),
      ),
      child: ColoredBox(
        color: PosterColors.flareRed,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.px(14),
            metrics.px(9),
            metrics.px(14),
            metrics.px(10),
          ),
          child: Text(label, style: PosterType.redTag(metrics.f)),
        ),
      ),
    );
  }
}

class _RedTagEdgesPainter extends CustomPainter {
  const _RedTagEdgesPainter({
    required this.top,
    required this.bottom,
    required this.thickness,
  });

  final Color top;
  final Color bottom;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = false;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, thickness),
      paint..color = top,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - thickness, size.width, thickness),
      paint..color = bottom,
    );
  }

  @override
  bool shouldRepaint(_RedTagEdgesPainter oldDelegate) {
    return oldDelegate.top != top ||
        oldDelegate.bottom != bottom ||
        oldDelegate.thickness != thickness;
  }
}

/// Card 10 — the `#003399` vertical strip, 8px wide, `right 16, top 16,
/// bottom 16`.
class DeStrip extends StatelessWidget {
  const DeStrip({super.key, this.width = 8});

  final double width;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return SizedBox(
      width: metrics.px(width),
      child: const ColoredBox(color: PosterColors.cardBlueDe),
    );
  }
}
