import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';

/// The plate's background: the face divided into [PlateSection] regions, the
/// dividers between them, and the border drawn last over all of it.
///
/// One [CustomPainter] in that order is what keeps a coloured region flush
/// with the border. A region runs out under the border rather than stopping
/// at its inner edge, so the only edge between them is the border's own, and
/// there is no second anti-aliased edge for the field to show through.
class PlateFrame extends StatelessWidget {
  const PlateFrame({
    super.key,
    this.theme,
    this.isCompleted = false,
    this.background = PlateSection.plain,
    this.panelColor = const Color(0x00000000),
  });

  final PlateTheme? theme;
  final bool isCompleted;
  final PlateSection background;

  /// What [PlateFill.panel] resolves to: the rendered country's panel colour.
  final Color panelColor;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PlateFramePainter(
      theme: theme ?? PlateTheme.of(context),
      isCompleted: isCompleted,
      background: background,
      panelColor: panelColor,
    ),
    child: const SizedBox.expand(),
  );
}

class _PlateFramePainter extends CustomPainter {
  _PlateFramePainter({
    required this.theme,
    required this.isCompleted,
    required this.background,
    required this.panelColor,
  });

  final PlateTheme theme;
  final bool isCompleted;
  final PlateSection background;
  final Color panelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final border = theme.borderWidthRatio * h;
    final outerRadius = theme.plateRadiusRatio * h;
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    final outerRect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(outerRect, Radius.circular(outerRadius));
    final inner = RRect.fromRectAndRadius(outerRect.deflate(border), Radius.circular(innerRadius));

    // Halfway into the border: far enough out that the border's inner edge
    // lies over a region, not past one; far enough in that a region's edge
    // never reaches the plate's outer anti-aliased rim.
    final face = outer.deflate(border / 2);
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawRRect(face, Paint()..color = theme.plateBackground);
    final dividers = <Rect>[];
    _paintSection(canvas, background, outerRect, dividers);
    final dividerPaint = Paint()..color = theme.dividerColor;
    for (final d in dividers) {
      canvas.drawRect(d, dividerPaint);
    }
    canvas.restore();

    canvas.drawDRRect(outer, inner, Paint()..color = _borderColor());
  }

  void _paintSection(Canvas canvas, PlateSection section, Rect r, List<Rect> dividers) {
    if (section.isLeaf) {
      final fill = section.fill!;
      // The field is already down; painting it again would only add a second
      // anti-aliased edge along each neighbour's boundary.
      if (fill.isField) return;
      if (fill.isStripes) {
        _paintStripes(canvas, fill, r, section.shape);
        return;
      }
      final paint = Paint()
        ..color = fill.resolve(field: theme.plateBackground, panel: panelColor, divider: theme.dividerColor);
      final shape = section.shape;
      if (shape == null) {
        canvas.drawRect(r, paint);
      } else {
        canvas.save();
        canvas.translate(r.left, r.top);
        canvas.drawPath(shape.getClip(r.size), paint);
        canvas.restore();
      }
      return;
    }
    final across = section.axis == Axis.horizontal;
    var start = across ? r.left : r.top;
    final last = section.parts.length - 1;
    for (var i = 0; i <= last; i++) {
      final part = section.parts[i];
      final end = i == last ? (across ? r.right : r.bottom) : part.end!;
      final child = across ? Rect.fromLTRB(start, r.top, end, r.bottom) : Rect.fromLTRB(r.left, start, r.right, end);
      _paintSection(canvas, part.section, child, dividers);
      if (part.divider > 0 && i != last) {
        final half = part.divider / 2;
        dividers.add(
          across
              ? Rect.fromLTRB(end - half, r.top, end + half, r.bottom)
              : Rect.fromLTRB(r.left, end - half, r.right, end + half),
        );
      }
      start = end;
    }
  }

  /// Each stripe is a rect in a frame turned about [r]'s centre, long enough
  /// to cover [r] at any angle, and clipped back to [r] (or its [shape]).
  void _paintStripes(Canvas canvas, PlateFill fill, Rect r, CustomClipper<Path>? shape) {
    final stripes = fill.stripes!;
    final c = r.center;
    final reach = r.longestSide;
    final cos = math.cos(fill.angle);
    canvas.save();
    if (shape == null) {
      canvas.clipRect(r);
    } else {
      canvas.clipPath(shape.getClip(r.size).shift(r.topLeft));
    }
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-fill.angle);
    var top = -reach;
    for (var i = 0; i < stripes.length; i++) {
      // A stop is where the boundary meets the centreline; in the turned frame
      // that is its perpendicular distance from the centre.
      final bottom = i < fill.stops.length ? (fill.stops[i] - c.dy) * cos : reach;
      final stripe = stripes[i];
      if (!stripe.isField) {
        final color = stripe.resolve(field: theme.plateBackground, panel: panelColor, divider: theme.dividerColor);
        canvas.drawRect(Rect.fromLTRB(-reach, top, reach, bottom), Paint()..color = color);
      }
      top = bottom;
    }
    canvas.restore();
  }

  Color _borderColor() {
    if (!isCompleted) return theme.plateBorder;
    return Color.lerp(theme.plateBorder, theme.plateBackground, 0.02) ?? theme.plateBorder;
  }

  @override
  bool shouldRepaint(_PlateFramePainter old) =>
      old.theme != theme ||
      old.isCompleted != isCompleted ||
      old.background != background ||
      old.panelColor != panelColor;
}
