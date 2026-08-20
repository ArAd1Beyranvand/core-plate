import 'package:flutter/material.dart';

import 'annotation_callout.dart' show CalloutSide;
import 'poster_tokens.dart';

/// Animated replacement for `ConnectorLine`: the dot pops in and the line
/// draws itself out of it on entry, and the reverse on exit. Footprint
/// matches `ConnectorLine` exactly so swapping it in causes no layout shift.
class AnimatedConnectorLine extends StatelessWidget {
  const AnimatedConnectorLine({
    super.key,
    required this.side,
    this.animation,
    this.entering = true,
    this.length = 150,
  });

  final CalloutSide side;
  final Animation<double>? animation;
  final bool entering;
  final double length;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = this.animation;

    Widget buildPainted(double dotScale, double extent) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: 40, maxWidth: length),
        child: SizedBox(
          height: 7,
          child: CustomPaint(
            painter: _ConnectorPainter(
              side: side,
              dotScale: dotScale,
              extent: extent,
            ),
          ),
        ),
      );
    }

    if (animation == null) {
      return buildPainted(1, 1);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double t = animation.value;
        double dotScale;
        double extent;
        if (entering) {
          dotScale = Curves.easeOutBack
              .transform((t / 0.35).clamp(0.0, 1.0))
              .clamp(0.0, double.infinity);
          extent = Curves.easeOutCubic
              .transform(((t - 0.25) / 0.75).clamp(0.0, 1.0));
        } else {
          extent = 1 -
              Curves.easeInCubic.transform((t / 0.70).clamp(0.0, 1.0));
          dotScale = (1 -
                  Curves.easeInBack
                      .transform(((t - 0.70) / 0.30).clamp(0.0, 1.0)))
              .clamp(0.0, double.infinity);
        }
        return buildPainted(dotScale, extent);
      },
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.side,
    required this.dotScale,
    required this.extent,
  });

  final CalloutSide side;
  final double dotScale;
  final double extent;

  static const double _dotRadius = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final bool dotOnRight = side == CalloutSide.left;
    final double cy = 3.5;
    final double dotCx = dotOnRight ? size.width - _dotRadius : _dotRadius;
    final double radius = _dotRadius * dotScale;

    if (radius > 0) {
      final Paint glowPaint = Paint()
        ..color = PosterTokens.accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(dotCx, cy), radius * 2, glowPaint);

      final Paint dotPaint = Paint()..color = PosterTokens.accent;
      canvas.drawCircle(Offset(dotCx, cy), radius, dotPaint);
    }

    final double lineSpan = size.width - (2 * _dotRadius);
    if (lineSpan > 0 && extent > 0) {
      final double drawn = lineSpan * extent;
      final double innerEdge =
          dotOnRight ? size.width - (2 * _dotRadius) : 2 * _dotRadius;
      final double startX = dotOnRight ? innerEdge : innerEdge;
      final double endX = dotOnRight ? innerEdge - drawn : innerEdge + drawn;

      final Paint linePaint = Paint()
        ..color = PosterTokens.accentDim
        ..strokeWidth = 1;
      canvas.drawLine(Offset(startX, cy), Offset(endX, cy), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return dotScale != oldDelegate.dotScale ||
        extent != oldDelegate.extent ||
        side != oldDelegate.side;
  }
}
