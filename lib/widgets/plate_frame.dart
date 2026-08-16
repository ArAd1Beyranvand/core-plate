import 'package:flutter/widgets.dart';

import '../theme/plate_theme.dart';

/// The physical plate: a white face inside a thick, black, rounded border with
/// optional screw dots. All geometry is derived from [PlateTheme] ratios and
/// the laid-out height, so the widget never touches [MediaQuery].
///
/// The border and face are painted by a single [CustomPainter] (no nested
/// bordered containers or clippers, which paint visible seams at the corners).
class PlateFrame extends StatelessWidget {
  const PlateFrame({
    super.key,
    required this.aspectRatio,
    required this.child,
    this.theme,
    this.isCompleted = false,
    this.screwSlots = const [],
  });

  /// Width / height of the plate face.
  final double aspectRatio;

  /// Content painted over the white face.
  final Widget child;

  /// Colours and ratios. Falls back to [PlateTheme.of] / standard when null.
  final PlateTheme? theme;

  /// A completed plate darkens/lightens the border by ~2%. It must NOT recolour
  /// the plate face or content.
  final bool isCompleted;

  /// Horizontal slots (x ∈ [-1, 1]) at which to draw a screw dot, vertically
  /// centred. Empty means no screws. Callers enable/disable individual screws
  /// by including or omitting their x.
  final List<double> screwSlots;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: CustomPaint(
            painter: _PlateFramePainter(
              theme: effectiveTheme,
              isCompleted: isCompleted,
              screwSlots: screwSlots,
            ),
            child: LayoutBuilder(
              builder: (context, inner) {
                // Inset the child by the border thickness so content sits on
                // the white face, not under the black frame.
                final border = effectiveTheme.borderWidthRatio * inner.maxHeight;
                return Padding(
                  padding: EdgeInsets.all(border),
                  child: child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PlateFramePainter extends CustomPainter {
  _PlateFramePainter({
    required this.theme,
    required this.isCompleted,
    required this.screwSlots,
  });

  final PlateTheme theme;
  final bool isCompleted;
  final List<double> screwSlots;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final border = theme.borderWidthRatio * h;
    final outerRadius = theme.plateRadiusRatio * h;
    // Inner radius tracks the inset so the corners stay concentric.
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    // Outer rounded rect: the black frame.
    final outerRect = Offset.zero & size;
    final outerRRect =
        RRect.fromRectAndRadius(outerRect, Radius.circular(outerRadius));
    canvas.drawRRect(
      outerRRect,
      Paint()..color = _borderColor(),
    );

    // Inner rounded rect: the white face, inset by the border thickness.
    final innerRect = outerRect.deflate(border);
    final innerRRect =
        RRect.fromRectAndRadius(innerRect, Radius.circular(innerRadius));
    canvas.drawRRect(
      innerRRect,
      Paint()..color = theme.plateBackground,
    );

    _paintScrews(canvas, size, border);
  }

  /// isCompleted shifts the border ~2% lighter (never recolours the plate).
  Color _borderColor() {
    if (!isCompleted) return theme.plateBorder;
    return Color.lerp(theme.plateBorder, theme.plateBackground, 0.02) ??
        theme.plateBorder;
  }

  void _paintScrews(Canvas canvas, Size size, double border) {
    if (screwSlots.isEmpty) return;
    final radius = size.height * 0.05;
    final cy = size.height / 2;
    // Keep screws clear of the rounded corners by insetting from the edges.
    final margin = border + radius * 1.4;
    final usable = size.width - margin * 2;

    final outer = Paint()..color = theme.screwColor;
    final inner = Paint()
      ..color = Color.lerp(theme.screwColor, theme.plateBorder, 0.45) ??
          theme.screwColor;

    for (final slot in screwSlots) {
      final t = (slot.clamp(-1.0, 1.0) + 1) / 2; // -1..1 -> 0..1
      final cx = margin + usable * t;
      final center = Offset(cx, cy);
      canvas.drawCircle(center, radius, outer);
      canvas.drawCircle(center, radius * 0.5, inner);
    }
  }

  @override
  bool shouldRepaint(_PlateFramePainter old) =>
      old.theme != theme ||
      old.isCompleted != isCompleted ||
      old.screwSlots != screwSlots;
}
