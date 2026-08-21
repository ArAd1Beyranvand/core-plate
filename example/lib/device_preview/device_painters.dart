// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_config.dart';

part 'device_painters.hardware.dart';

/// Silver ramp used for every metal surface, so lid, deck and buttons read as
/// one milled aluminium body.
class _Metal {
  static const highlight = Color(0xFF3E434C);
  static const light = Color(0xFF2B2F36);
  static const mid = Color(0xFF1D2026);
  static const shade = Color(0xFF262A31);
  static const deep = Color(0xFF0A0C0F);
  static const edge = Color(0xFF000000);
  static const glass = Color(0xFF07080A);
}

/// Paints the body: drop shadow, milled aluminium lid, side buttons and the
/// black screen well. Canvas size is the body size — the deck is a widget.
class DeviceBodyPainter extends CustomPainter {
  const DeviceBodyPainter({required this.config, this.ambient = 1});

  final DeviceConfig config;
  final double ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Offset.zero & size;
    final bodyRR = RRect.fromRectAndRadius(body, Radius.circular(config.bodyRadius));
    _paintShadow(canvas, body);
    _paintSideButtons(canvas, body);
    _paintLid(canvas, bodyRR);
    _paintScreenWell(canvas, body);
  }

  void _paintShadow(Canvas canvas, Rect body) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(Offset(0, config.shadowOffsetY)),
        Radius.circular(config.bodyRadius),
      ),
      Paint()
        ..color = const Color(0xFF0B0D14).withValues(alpha: 0.24 * ambient)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.shadowBlur),
    );
  }

  void _paintLid(Canvas canvas, RRect bodyRR) {
    final rect = bodyRR.outerRect;
    canvas.drawRRect(
      bodyRR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _Metal.highlight, _Metal.light, _Metal.mid,
            _Metal.light, _Metal.shade, _Metal.deep,
          ],
          stops: [0, .16, .38, .58, .82, 1],
        ).createShader(rect),
    );

    canvas.drawRRect(
      bodyRR.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.06),
            _Metal.edge.withValues(alpha: 0.55),
          ],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipRRect(bodyRR);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height * 0.45)),
    );
    canvas.restore();
  }

  void _paintScreenWell(Canvas canvas, Rect body) {
    final screen = config.bezel.deflateRect(body);
    final rr = RRect.fromRectAndRadius(screen, Radius.circular(config.screenRadius));
    canvas.drawRRect(
      rr.inflate(1.5),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(rr, Paint()..color = _Metal.glass);
  }

  void _paintSideButtons(Canvas canvas, Rect body) {
    for (final b in config.sideButtons) {
      if (b.opacity <= 0.01 || b.length <= 0.001) continue;
      final top = body.top + body.height * b.start;
      final h = body.height * b.length;
      final rect = b.side < 0
          ? Rect.fromLTWH(body.left - b.thickness + 1, top, b.thickness, h)
          : Rect.fromLTWH(body.right - 1, top, b.thickness, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(b.thickness * 0.6)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _Metal.light.withValues(alpha: b.opacity),
              _Metal.shade.withValues(alpha: b.opacity),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DeviceBodyPainter old) =>
      old.config != config || old.ambient != ambient;
}
