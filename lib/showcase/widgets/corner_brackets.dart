import 'package:flutter/material.dart';

/// Overlays four L-shaped 1px brackets, inset from the edges of its parent.
///
/// Pure decoration — ignores pointer events so it never intercepts taps.
class CornerBrackets extends StatelessWidget {
  const CornerBrackets({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _CornerBracketsPainter(),
        size: Size.infinite,
        child: SizedBox.expand(),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  static const double _inset = 28.0;
  static const double _arm = 46.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const left = _inset;
    const top = _inset;
    final right = size.width - _inset;
    final bottom = size.height - _inset;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + _arm)
        ..lineTo(left, top)
        ..lineTo(left + _arm, top),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - _arm, top)
        ..lineTo(right, top)
        ..lineTo(right, top + _arm),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - _arm)
        ..lineTo(left, bottom)
        ..lineTo(left + _arm, bottom),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right - _arm, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - _arm),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
