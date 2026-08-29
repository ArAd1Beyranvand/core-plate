import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';

/// §4.9 — `repeating-linear-gradient(90deg, rgba(…) 0 8–10px, transparent
/// 8–10px 16–20px)`, height 2–3px.
///
/// The design uses 8/16 for 2px rules and 10/20 for 3px ones; those are the
/// two named constructors. All lengths are DESIGN px, scaled through
/// [PosterMetrics].
class DashedRule extends StatelessWidget {
  const DashedRule({
    super.key,
    required this.color,
    this.dash = 8,
    this.gap = 8,
    this.thickness = 2,
    this.width,
  });

  /// 8px dash, 8px gap (a 16px period), 2px high.
  const DashedRule.thin({super.key, required this.color, this.width})
    : dash = 8,
      gap = 8,
      thickness = 2;

  /// 10px dash, 10px gap (a 20px period), 3px high.
  const DashedRule.thick({super.key, required this.color, this.width})
    : dash = 10,
      gap = 10,
      thickness = 3;

  final Color color;

  /// Painted length of one dash, in DESIGN px.
  final double dash;

  /// Gap between dashes, in DESIGN px. The CSS period is `dash + gap`.
  final double gap;

  /// Rule height, in DESIGN px.
  final double thickness;

  /// Optional fixed length in DESIGN px. Null stretches to the parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return SizedBox(
      width: width == null ? double.infinity : metrics.px(width!),
      height: metrics.px(thickness),
      child: CustomPaint(
        painter: _DashedRulePainter(
          color: color,
          dash: metrics.px(dash),
          gap: metrics.px(gap),
        ),
      ),
    );
  }
}

/// Same 8/8 dashes as [DashedRule.thin], bent into an L that hugs [child]:
/// down its right edge and along its bottom. Sizes to the child, so the legs
/// only ever run as far as the text they wrap.
class DashedLBorder extends StatelessWidget {
  const DashedLBorder({
    super.key,
    required this.color,
    required this.child,
    this.dash = 8,
    this.gap = 8,
    this.thickness = 2,
    this.inset = defaultInset,
  });

  /// Default clearance between child and legs, in DESIGN px. Public so callers
  /// laying text around the L can predict its footprint.
  static const double defaultInset = 14;

  final Color color;
  final Widget child;

  /// Painted length of one dash, in DESIGN px.
  final double dash;

  /// Gap between dashes, in DESIGN px.
  final double gap;

  /// Leg thickness, in DESIGN px.
  final double thickness;

  /// Clearance between the child and each leg, in DESIGN px.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return CustomPaint(
      foregroundPainter: _DashedLPainter(
        color: color,
        dash: metrics.px(dash),
        gap: metrics.px(gap),
        thickness: metrics.px(thickness),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          right: metrics.px(inset + thickness),
          bottom: metrics.px(inset + thickness),
        ),
        child: child,
      ),
    );
  }
}

class _DashedLPainter extends CustomPainter {
  const _DashedLPainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.thickness,
  });

  final Color color;
  final double dash;
  final double gap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (dash <= 0) return;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final double period = dash + gap;
    final double right = size.width - thickness;
    final double bottom = size.height - thickness;

    // Vertical leg, down the right edge to the corner.
    for (double y = 0; y < size.height; y += period) {
      final double end = math.min(y + dash, size.height);
      canvas.drawRect(Rect.fromLTRB(right, y, size.width, end), paint);
    }
    // Horizontal leg, along the bottom up to the same corner.
    for (double x = 0; x < size.width; x += period) {
      final double end = math.min(x + dash, size.width);
      canvas.drawRect(Rect.fromLTRB(x, bottom, end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness;
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter({
    required this.color,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (dash <= 0 || size.width <= 0) return;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final double period = dash + gap;
    for (double x = 0; x < size.width; x += period) {
      final double end = math.min(x + dash, size.width);
      canvas.drawRect(Rect.fromLTRB(x, 0, end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRulePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap;
  }
}
