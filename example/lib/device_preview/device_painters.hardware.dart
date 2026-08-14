part of 'device_painters.dart';

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
