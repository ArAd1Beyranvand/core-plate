import 'package:flutter/widgets.dart';

import '../theme/plate_theme.dart';

/// The physical plate: a white face inside a thick, black, rounded border with
/// optional screw dots. All geometry is derived from [PlateTheme] ratios and
/// the laid-out height, so the widget never touches [MediaQuery].
///
/// The border and face are painted by a single [CustomPainter] (no nested
/// bordered containers or clippers, which paint visible seams at the corners).
class PlateFrame extends StatelessWidget {
  const PlateFrame({super.key, this.theme, this.isCompleted = false});

  /// Colours and ratios. Falls back to [PlateTheme.of] / standard when null.
  final PlateTheme? theme;

  /// A completed plate darkens/lightens the border by ~2%. It must NOT recolour
  /// the plate face or content.
  final bool isCompleted;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PlateFramePainter(
      theme: theme ?? PlateTheme.of(context),
      isCompleted: isCompleted,
    ),
    child: const SizedBox.expand(),
  );
}

class _PlateFramePainter extends CustomPainter {
  _PlateFramePainter({required this.theme, required this.isCompleted});

  final PlateTheme theme;
  final bool isCompleted;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final border = theme.borderWidthRatio * h;
    final outerRadius = theme.plateRadiusRatio * h;
    // Inner radius tracks the inset so the corners stay concentric.
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    // Outer rounded rect: the black frame.
    final outerRect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(outerRadius),
    );
    canvas.drawRRect(outerRRect, Paint()..color = _borderColor());

    // Inner rounded rect: the white face, inset by the border thickness.
    final innerRect = outerRect.deflate(border);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(innerRadius),
    );
    canvas.drawRRect(innerRRect, Paint()..color = theme.plateBackground);
  }

  /// isCompleted shifts the border ~2% lighter (never recolours the plate).
  Color _borderColor() {
    if (!isCompleted) return theme.plateBorder;
    return Color.lerp(theme.plateBorder, theme.plateBackground, 0.02) ??
        theme.plateBorder;
  }

  @override
  bool shouldRepaint(_PlateFramePainter old) =>
      old.theme != theme || old.isCompleted != isCompleted;
}
