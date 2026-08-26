import 'dart:math' as math;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The design canvas every §6 coordinate is measured on.
const double kBackdropDesignWidth = 1920;
const double kBackdropDesignHeight = 1080;

/// The beam wedge of DESIGN_SPEC.md §6.4, in DESIGN coordinates:
/// `polygon(0% −6%, 100% 23%, 100% 112%, 0% 66%)`.
///
/// The negative and over-100 values are intentional — the wedge deliberately
/// exceeds the stage box. P5's sweep clips to this same path, which is why it
/// is public.
Path beamWedgePath() {
  const double w = kBackdropDesignWidth;
  const double h = kBackdropDesignHeight;
  return Path()
    ..moveTo(0, -0.06 * h)
    ..lineTo(w, 0.23 * h)
    ..lineTo(w, 1.12 * h)
    ..lineTo(0, 0.66 * h)
    ..close();
}

/// The lit road behind the poster — layers 1–9 of DESIGN_SPEC.md §6,
/// bottom-up in order:
///
///  1. ground radial            6. beam colour cast (wedge)
///  2. `bg_grain_a` @256, .15   7. dark masks above/below the wedge
///  3. `bg_grain_b` @320, .44   8. two light rails, 9.26° / 14.5°
///  4. the beam wedge           9. lane dashes, 11.8°
///  5. `bg_grain_b` @250, .62 overlay (wedge)
///
/// Layer 10 — the sweep during a device hop — belongs to P5. The seam is
/// [sweep]: anything passed there is painted last, over the dashes, already
/// inside this widget's coordinate space. P5 can clip it to [beamWedgePath]
/// after scaling by `metrics.size.width / kBackdropDesignWidth` horizontally
/// and `metrics.size.height / kBackdropDesignHeight` vertically.
///
/// Everything is painted on a virtual 1920×1080 canvas that is then scaled to
/// the stage, so the wedge, the rails and the lane dashes deform together and
/// the dashes always lie on the beam. Lengths that must not deform (nothing in
/// §6 today) would use `PosterMetrics.px`.
class PosterBackdrop extends StatefulWidget {
  const PosterBackdrop({super.key, this.sweep});

  /// P5's layer 10. Painted above layer 9, in stage coordinates.
  final Widget? sweep;

  @override
  State<PosterBackdrop> createState() => _PosterBackdropState();
}

class _PosterBackdropState extends State<PosterBackdrop> {
  ui.Image? _grainA;
  ui.Image? _grainB;

  @override
  void initState() {
    super.initState();
    _loadGrain();
  }

  Future<void> _loadGrain() async {
    final ui.Image a = await _decodeAsset('assets/textures/bg_grain_a.png');
    final ui.Image b = await _decodeAsset('assets/textures/bg_grain_b.png');
    if (!mounted) {
      a.dispose();
      b.dispose();
      return;
    }
    setState(() {
      _grainA = a;
      _grainB = b;
    });
  }

  static Future<ui.Image> _decodeAsset(String key) async {
    final ByteData data = await rootBundle.load(key);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _grainA?.dispose();
    _grainB?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    return SizedBox(
      width: metrics.size.width,
      height: metrics.size.height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: _BackdropPainter(grainA: _grainA, grainB: _grainB),
          ),
          // Layer 10 — P5's sweep. Nothing here yet.
          if (widget.sweep != null) Positioned.fill(child: widget.sweep!),
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.grainA, required this.grainB});

  final ui.Image? grainA;
  final ui.Image? grainB;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    // Work in design space for the whole backdrop: the wedge percentages, the
    // rails and the dashes then deform together with the stage box.
    canvas.scale(
      size.width / kBackdropDesignWidth,
      size.height / kBackdropDesignHeight,
    );

    const Rect stage = Rect.fromLTWH(
      0,
      0,
      kBackdropDesignWidth,
      kBackdropDesignHeight,
    );
    // The rails and the wedge overhang the stage; give every full-bleed fill
    // enough slack that nothing shows a seam at the edges.
    final Rect bleed = stage.inflate(kBackdropDesignHeight * 0.5);

    _paintGroundRadial(canvas, stage, bleed);

    // 2 — bg_grain_a @256px, .15, normal.
    _paintGrain(canvas, bleed, grainA, 256, 0.15, BlendMode.srcOver);
    // 3 — bg_grain_b @320px, .44, normal.
    _paintGrain(canvas, bleed, grainB, 320, 0.44, BlendMode.srcOver);

    final Path wedge = beamWedgePath();

    // 4 — the beam wedge, screen-blended.
    canvas.save();
    canvas.clipPath(wedge);
    _paintBeam(canvas, wedge.getBounds());
    canvas.restore();

    // 5 — bg_grain_b @250px, .62, overlay, same wedge.
    canvas.save();
    canvas.clipPath(wedge);
    _paintGrain(canvas, bleed, grainB, 250, 0.62, BlendMode.overlay);
    canvas.restore();

    // 6 — the colour cast, same wedge.
    canvas.drawPath(wedge, Paint()..color = PosterColors.beamTint);

    // 7 — the dark masks above and below the wedge.
    _paintMasks(canvas);

    // 8 — the two light rails.
    _paintRail(canvas, dy: -65, length: 1946, thickness: 3, degrees: 9.26);
    _paintRail(canvas, dy: 713, length: 1984, thickness: 3, degrees: 14.5);

    // 9 — the lane dashes.
    _paintLaneDashes(canvas);

    canvas.restore();
  }

  /// 1 — `radial-gradient(1500×920 at 74% 50%)` over the page black.
  void _paintGroundRadial(Canvas canvas, Rect stage, Rect bleed) {
    canvas.drawRect(bleed, Paint()..color = PosterColors.groundRadialEdge);

    final Offset centre = Offset(0.74 * stage.width, 0.50 * stage.height);
    const double rx = 750; // 1500 wide
    const double ry = 460; // 920 tall

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(1, ry / rx);
    final Rect circle = Rect.fromCircle(center: Offset.zero, radius: rx);
    canvas.drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            PosterColors.groundRadialCore,
            PosterColors.groundRadialMid,
            PosterColors.groundRadialEdge,
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ).createShader(circle),
    );
    canvas.restore();
  }

  /// A repeating grain tile drawn at [tileDesignPx] design px a side,
  /// composited with [blend] against everything already painted.
  ///
  /// `poster_textures.dart`'s `textureDecoration` cannot be used here: its
  /// `ColorFilter.mode(Colors.white, blend)` recolours the tile instead of
  /// blending it, and `DecorationImage` has no blend-against-destination at
  /// all. An `ImageShader` plus a `saveLayer` does both correctly.
  void _paintGrain(
    Canvas canvas,
    Rect rect,
    ui.Image? image,
    double tileDesignPx,
    double opacity,
    BlendMode blend,
  ) {
    if (image == null) return;
    final Matrix4 tile = Matrix4.identity()
      ..scaleByDouble(
        tileDesignPx / image.width,
        tileDesignPx / image.height,
        1,
        1,
      );
    final ui.ImageShader shader = ui.ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      tile.storage,
    );
    canvas.saveLayer(
      rect,
      Paint()
        ..blendMode = blend
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.restore();
  }

  /// 4 — inside the wedge: a radial highlight at 1430,545 (900×520), a 99°
  /// linear wash, and a blurred 1990×64 bar at 0,380 rotated 12.9° about its
  /// own top-left origin. All screen-blended.
  void _paintBeam(Canvas canvas, Rect wedgeBounds) {
    // The 99° linear wash. CSS angles run clockwise from "to top", so 99°
    // points right and very slightly down.
    const double rad99 = 99 * math.pi / 180;
    final Offset dir = Offset(math.sin(rad99), -math.cos(rad99));
    final Offset centre = wedgeBounds.center;
    final double reach =
        (wedgeBounds.width * dir.dx).abs() + (wedgeBounds.height * dir.dy).abs();
    canvas.drawRect(
      wedgeBounds,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          centre - dir * (reach / 2),
          centre + dir * (reach / 2),
          <Color>[
            const Color(0x00000000),
            PosterColors.beamMid,
            const Color(0x00000000),
          ],
          <double>[0.0, 0.52, 1.0],
        ),
    );

    // The radial highlight, 900×520 at 1430,545.
    const Offset hot = Offset(1430, 545);
    const double rx = 450;
    const double ry = 260;
    canvas.save();
    canvas.translate(hot.dx, hot.dy);
    canvas.scale(1, ry / rx);
    canvas.drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.radial(
          Offset.zero,
          rx,
          <Color>[PosterColors.beamHi, const Color(0x00000000)],
          <double>[0.0, 1.0],
        ),
    );
    canvas.restore();

    // The blurred bar: 1990×64 at 0,380, rotate(12.9deg) about 0,0.
    canvas.save();
    canvas.translate(0, 380);
    canvas.rotate(12.9 * math.pi / 180);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1990, 64),
      Paint()
        ..blendMode = BlendMode.screen
        ..color = PosterColors.beamHi
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
    canvas.restore();
  }

  /// 7 — `polygon(0% −6%, 100% 23%, 100% −40%, 0% −40%)` above the wedge and
  /// `polygon(0% 66%, 100% 112%, 100% 145%, 0% 145%)` below it.
  void _paintMasks(Canvas canvas) {
    const double w = kBackdropDesignWidth;
    const double h = kBackdropDesignHeight;
    final Paint paint = Paint()..color = PosterColors.roadMask;

    canvas.drawPath(
      Path()
        ..moveTo(0, -0.06 * h)
        ..lineTo(w, 0.23 * h)
        ..lineTo(w, -0.40 * h)
        ..lineTo(0, -0.40 * h)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0.66 * h)
        ..lineTo(w, 1.12 * h)
        ..lineTo(w, 1.45 * h)
        ..lineTo(0, 1.45 * h)
        ..close(),
      paint,
    );
  }

  /// 8 — a light rail: a thin bar at `0,dy`, rotated about its own top-left
  /// corner (`transform-origin: 0 0`), screen-blended, brightest at its core.
  void _paintRail(
    Canvas canvas, {
    required double dy,
    required double length,
    required double thickness,
    required double degrees,
  }) {
    canvas.save();
    canvas.translate(0, dy);
    canvas.rotate(degrees * math.pi / 180);
    final Rect bar = Rect.fromLTWH(0, 0, length, thickness);
    canvas.drawRect(
      bar,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          bar.topLeft,
          bar.topRight,
          <Color>[
            const Color(0x00000000),
            PosterColors.railLightCore,
            PosterColors.railLightMid,
            const Color(0x00000000),
          ],
          <double>[0.0, 0.28, 0.72, 1.0],
        ),
    );
    // A soft halo so the rail reads as light, not as a drawn line.
    canvas.drawRect(
      bar,
      Paint()
        ..blendMode = BlendMode.screen
        ..color = PosterColors.railLightMid
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
  }

  /// 9 — `−60,322`, `2100×9`, `rotate(11.8deg)`, dashes 104 on / 68 off
  /// (`repeating-linear-gradient(90deg, … 0 104px, transparent 104px 172px)`).
  void _paintLaneDashes(Canvas canvas) {
    const double dash = 104;
    const double period = 172;
    const double width = 2100;
    const double thickness = 9;

    canvas.save();
    canvas.translate(-60, 322);
    canvas.rotate(11.8 * math.pi / 180);
    final Paint paint = Paint()..color = PosterColors.roadStripe;
    for (double x = 0; x < width; x += period) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, math.min(dash, width - x), thickness),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) {
    return oldDelegate.grainA != grainA || oldDelegate.grainB != grainB;
  }
}
