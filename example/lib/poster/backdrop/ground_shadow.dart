import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../device_preview/device_config.dart' show DeviceType;
import '../poster_scale.dart';
import '../poster_tokens.dart';
import 'poster_backdrop.dart';

/// The skewed slab under the device — the "Ground shadow" row of
/// DESIGN_SPEC.md §6 and the `groundShadow*` tokens of §1.
///
/// 900×104 at `1030,872` in design coordinates, `skewX(-34deg / -30deg /
/// -41deg)` for desktop / mobile / tablet, gradient from §1, blur 2px.
///
/// No state machine of its own (§7.2): it takes the [device] the stage
/// already reports through `onFrameDeviceChanged` and eases to that skew over
/// `DeviceTransitionDurations.frameTransform` (1500ms) with
/// `Curves.easeInOutCubic` — the shell's own morph — so slab and device change
/// shape together instead of drifting apart.
class GroundShadow extends StatelessWidget {
  const GroundShadow({
    super.key,
    required this.device,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOutCubic,
  });

  final DeviceType device;
  final Duration duration;
  final Curve curve;

  /// CSS `skewX` leans a shape the opposite way to the matrix convention, so
  /// these are negated when they reach `Matrix4.skewX`.
  static double skewDegreesFor(DeviceType device) {
    switch (device) {
      case DeviceType.desktop:
        return -34;
      case DeviceType.mobile:
        return -30;
      case DeviceType.tablet:
        return -41;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // No `begin`: the first build lands on the value, every later change
      // eases from wherever the slab currently is.
      tween: Tween<double>(end: skewDegreesFor(device)),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double degrees, Widget? child) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _GroundShadowPainter(skewDegrees: degrees),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _GroundShadowPainter extends CustomPainter {
  const _GroundShadowPainter({required this.skewDegrees});

  final double skewDegrees;

  static const double _x = 1030;
  static const double _y = 872;
  static const double _w = 900;
  static const double _h = 104;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    canvas.scale(
      size.width / kBackdropDesignWidth,
      size.height / kBackdropDesignHeight,
    );

    // Anchor at the slab's own centre so the skew leans it without sliding it
    // out from under the device.
    canvas.translate(_x + _w / 2, _y + _h / 2);
    // CSS skewX(θ) shears x by +tan(θ)·y; Matrix4.skewX takes the shear factor
    // with the opposite sign convention, hence the negation.
    canvas.transform(
      Matrix4.skewX(-math.tan(skewDegrees * math.pi / 180)).storage,
    );
    canvas.translate(-_w / 2, -_h / 2);

    const Rect slab = Rect.fromLTWH(0, 0, _w, _h);
    canvas.drawRect(
      slab,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            PosterColors.groundShadowStart,
            PosterColors.groundShadowMid,
            Color(0x00000000),
          ],
          stops: <double>[0.0, 0.6, 1.0],
        ).createShader(slab),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroundShadowPainter oldDelegate) {
    return oldDelegate.skewDegrees != skewDegrees;
  }
}

/// Sizes [GroundShadow] to the stage, for use as a `Stack` layer under the
/// device.
class GroundShadowLayer extends StatelessWidget {
  const GroundShadowLayer({super.key, required this.device});

  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return SizedBox(
      width: metrics.size.width,
      height: metrics.size.height,
      child: GroundShadow(device: device),
    );
  }
}
