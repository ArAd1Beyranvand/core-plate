import 'package:flutter/material.dart';

import '../theme/poster_tokens.dart';

/// Paints the poster background: a subtle vertical gradient, a faint square
/// grid, and a soft radial vignette darkening the corners.
class GridBackdrop extends StatelessWidget {
  const GridBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PosterTokens.bgTop, PosterTokens.bg],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
        child: SizedBox.expand(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const double _cell = 72.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint square grid — accent at ~3% alpha.
    final gridPaint = Paint()
      ..color = PosterTokens.accent.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Soft radial vignette darkening the corners.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * 0.75;
    final vignette = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x00000000), Color(0x99000000)],
        stops: [0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
