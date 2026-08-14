import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_config.dart';

/// Silver ramp used for every metal surface, so lid, deck and buttons read as
/// one milled aluminium body.
class _Metal {
  static const highlight = Color(0xFF33373E);
  static const light = Color(0xFF23262C);
  static const mid = Color(0xFF171A1F);
  static const shade = Color(0xFF20242A);
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

/// Paints the hardware above the glass: notch, camera stack, earpiece grille
/// and home indicator. Canvas size is the body size.
class DeviceHardwarePainter extends CustomPainter {
  const DeviceHardwarePainter({required this.config, this.detailOpacity = 1});

  final DeviceConfig config;
  final double detailOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Offset.zero & size;
    final screen = config.bezel.deflateRect(body);
    _paintNotch(canvas, screen);
    _paintSpeaker(canvas, body);
    _paintCamera(canvas, body);
    _paintHomeIndicator(canvas, screen);
  }

  void _paintNotch(Canvas canvas, Rect screen) {
    final n = config.notchSize;
    if (n.width < 2 || n.height < 1) return;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(screen.center.dx - n.width / 2, screen.top, n.width, n.height),
        bottomLeft: Radius.circular(config.notchRadius),
        bottomRight: Radius.circular(config.notchRadius),
      ),
      Paint()..color = _Metal.glass,
    );
  }

  void _paintCamera(Canvas canvas, Rect body) {
    final r = config.cameraRadius;
    if (r < 0.4) return;
    // seat the lens just inside the rim rather than straddling it
    final c = body.topLeft + seatOnEdge(config.cameraEdge, body.size, r * 1.9);
    final o = detailOpacity;
    canvas.drawCircle(c, r * 1.35,
        Paint()..color = const Color(0xFF16181D).withValues(alpha: 0.9 * o));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            const Color(0xFF2B3550).withValues(alpha: o),
            const Color(0xFF0A0C12).withValues(alpha: o),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c.translate(-r * 0.32, -r * 0.34), math.max(r * 0.22, 0.6),
        Paint()..color = Colors.white.withValues(alpha: 0.75 * o));
  }

  void _paintSpeaker(Canvas canvas, Rect body) {
    final s = config.speakerSize;
    if (s.width < 2 || s.height < 0.6) return;
    final c = body.topLeft +
        seatOnEdge(config.speakerEdge, body.size, math.max(s.height, 1) * 1.4);
    final rect = Rect.fromCenter(center: c, width: s.width, height: s.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s.height)),
      Paint()..color = const Color(0xFF181B21).withValues(alpha: 0.95 * detailOpacity),
    );
    final dotR = math.min(s.height * 0.22, 0.9);
    if (dotR > 0.35) {
      final count = (s.width / (dotR * 4)).floor();
      final paint = Paint()
        ..color = const Color(0xFF3C424C).withValues(alpha: 0.7 * detailOpacity);
      for (var i = 0; i < count; i++) {
        canvas.drawCircle(Offset(rect.left + dotR * 2 + i * dotR * 4, c.dy), dotR, paint);
      }
    }
  }

  void _paintHomeIndicator(Canvas canvas, Rect screen) {
    final w = config.homeIndicatorWidth;
    if (w < 4) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(screen.center.dx, screen.bottom - 9), width: w, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55 * detailOpacity),
    );
  }

  @override
  bool shouldRepaint(covariant DeviceHardwarePainter old) =>
      old.config != config || old.detailOpacity != detailOpacity;
}

/// Clips page content to the glass: a rounded rect with the notch cut out.
/// Radius and notch both animate with the config.
class DeviceScreenClipper extends CustomClipper<Path> {
  const DeviceScreenClipper({required this.config});

  final DeviceConfig config;

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    final screen = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(config.screenRadius)));
    final n = config.notchSize;
    if (n.width < 2 || n.height < 1) return screen;
    final notch = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rect.center.dx - n.width / 2, -1, n.width, n.height + 1),
          bottomLeft: Radius.circular(config.notchRadius),
          bottomRight: Radius.circular(config.notchRadius),
        ),
      );
    return Path.combine(PathOperation.difference, screen, notch);
  }

  @override
  bool shouldReclip(covariant DeviceScreenClipper old) => old.config != config;
}
