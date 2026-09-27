import 'package:flutter/widgets.dart';

import '../theme/plate_theme.dart';

/// White face inside rounded border. Geometry from [PlateTheme] ratios and
/// height, painted by single [CustomPainter] to avoid seams.
class PlateFrame extends StatelessWidget {
  const PlateFrame({super.key, this.theme, this.isCompleted = false});

  final PlateTheme? theme;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PlateFramePainter(theme: theme ?? PlateTheme.of(context), isCompleted: isCompleted),
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
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    final outerRect = Offset.zero & size;
    final outerRRect = RRect.fromRectAndRadius(outerRect, Radius.circular(outerRadius));
    canvas.drawRRect(outerRRect, Paint()..color = _borderColor());

    final innerRect = outerRect.deflate(border);
    final innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(innerRadius));
    canvas.drawRRect(innerRRect, Paint()..color = theme.plateBackground);
  }

  Color _borderColor() {
    if (!isCompleted) return theme.plateBorder;
    return Color.lerp(theme.plateBorder, theme.plateBackground, 0.02) ?? theme.plateBorder;
  }

  @override
  bool shouldRepaint(_PlateFramePainter old) => old.theme != theme || old.isCompleted != isCompleted;
}
