import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';
import 'poster_backdrop.dart';

/// Layer 10 of DESIGN_SPEC.md §6 — the headlight that rakes across the road
/// once per device hop.
///
/// A 400×1500 gradient band plus a 5px bright edge at `x 396`, both rotated
/// `11.8deg` (the lane-dash angle, so the sweep travels along the road rather
/// than across it), translating X from `−560` to `2400` over 1.5s
/// `cubic-bezier(.42,.02,.6,1)`, screen-blended, with opacity ramping in and
/// out over `.34s` linear.
///
/// It owns no state machine — §7.2. Derive [isHopping] from
/// `DeviceFrame.onPhaseChanged`: pass `phase == frameTransform`, so the rake
/// starts on the exact frame the device's content opacity reaches zero rather
/// than back when it only began fading. The sweep fires once on the false→true
/// edge and runs its full 1.5s on its own controller, so it outlives the
/// shorter phase window that triggered it.
class SweepLight extends StatefulWidget {
  const SweepLight({
    super.key,
    required this.isHopping,
    this.rotationOrigin = Alignment.topLeft,
  });

  /// True for any `DeviceTransitionPhase` other than `idle`.
  final bool isHopping;

  /// §6's blanket rule is `transform-origin: 0 0`, which is the default here.
  /// P5's brief says "about their centre" — the two differ only by a fixed
  /// offset along the travel, so this is a knob rather than a fork.
  final Alignment rotationOrigin;

  @override
  State<SweepLight> createState() => _SweepLightState();
}

class _SweepLightState extends State<SweepLight>
    with SingleTickerProviderStateMixin {
  static const Duration _travel = Duration(milliseconds: 1500);

  /// `cubic-bezier(.42,.02,.6,1)`.
  static const Curve _travelCurve = Cubic(0.42, 0.02, 0.60, 1.0);

  /// `.34s` of the 1.5s travel, at each end.
  static const double _fade = 340 / 1500;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _travel,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isHopping) _fire();
  }

  @override
  void didUpdateWidget(SweepLight oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the rising edge fires. While isHopping stays true the sweep runs
    // its 1.5s once and then sits at rest.
    if (widget.isHopping && !oldWidget.isHopping) _fire();
  }

  void _fire() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return IgnorePointer(
      child: SizedBox(
        width: metrics.size.width,
        height: metrics.size.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = _controller.value;
            if (t == 0 || t == 1) return const SizedBox.expand();
            return CustomPaint(
              painter: _SweepPainter(
                travel: _travelCurve.transform(t),
                opacity: _opacityAt(t),
                origin: widget.rotationOrigin,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Opacity is its own `.34s linear` ramp, independent of the travel curve.
  double _opacityAt(double t) {
    if (t < _fade) return t / _fade;
    if (t > 1 - _fade) return (1 - t) / _fade;
    return 1;
  }
}

class _SweepPainter extends CustomPainter {
  const _SweepPainter({
    required this.travel,
    required this.opacity,
    required this.origin,
  });

  /// Eased 0→1 along the `−560 → 2400` translation.
  final double travel;
  final double opacity;
  final Alignment origin;

  static const double _bandWidth = 400;
  static const double _bandHeight = 1500;
  static const double _edgeX = 396;
  static const double _edgeWidth = 5;
  static const double _fromX = -560;
  static const double _toX = 2400;
  static const double _degrees = 11.8;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    canvas.save();
    // Same design-space canvas as PosterBackdrop, so the sweep shares the
    // road's perspective exactly.
    canvas.scale(
      size.width / kBackdropDesignWidth,
      size.height / kBackdropDesignHeight,
    );

    final double x = _fromX + (_toX - _fromX) * travel;
    // The band is taller than the stage on purpose; centre it vertically so
    // the rake covers the whole road at any angle.
    final double y = (kBackdropDesignHeight - _bandHeight) / 2;

    canvas.translate(x, y);
    final Offset pivot = Offset(
      (origin.x + 1) / 2 * _bandWidth,
      (origin.y + 1) / 2 * _bandHeight,
    );
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(_degrees * math.pi / 180);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Whole sweep at one opacity, screen-blended against the road.
    final Rect band = const Rect.fromLTWH(0, 0, _bandWidth, _bandHeight);
    canvas.saveLayer(
      band.inflate(80),
      Paint()
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0).toDouble()),
    );

    // The body: a soft gradient across the band's width.
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const <Color>[
            PosterColors.sweepBodyStart,
            PosterColors.sweepBodyMid,
            PosterColors.sweepBodyEnd,
          ],
          stops: const <double>[0.0, 0.62, 1.0],
        ).createShader(band),
    );

    // The 5px bright edge at x 396, brightest at its middle.
    final Rect edge = const Rect.fromLTWH(_edgeX, 0, _edgeWidth, _bandHeight);
    final Paint edgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const <Color>[
          PosterColors.sweepEdgeStart,
          PosterColors.sweepEdgeMid,
          PosterColors.sweepEdgeEnd,
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(edge);

    // Its glow first, then the hard edge over it.
    canvas.drawRect(
      edge.inflate(6),
      Paint()
        ..color = PosterColors.sweepEdgeGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawRect(edge, edgePaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) {
    return oldDelegate.travel != travel ||
        oldDelegate.opacity != opacity ||
        oldDelegate.origin != origin;
  }
}
