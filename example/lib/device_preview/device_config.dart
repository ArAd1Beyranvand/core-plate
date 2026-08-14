import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Walks the body's perimeter clockwise from the top-left corner:
/// 0-.25 top, .25-.5 right, .5-.75 bottom, .75-1 left. Hardware positions are
/// stored this way so the camera and speaker stay ON the frame edge as the
/// body morphs, instead of cutting across the screen.
Offset edgePoint(double s, Size body) {
  final u = (s % 1 + 1) % 1;
  if (u < 0.25) return Offset(body.width * (u / 0.25), 0);
  if (u < 0.50) return Offset(body.width, body.height * ((u - 0.25) / 0.25));
  if (u < 0.75) {
    return Offset(body.width * (1 - (u - 0.50) / 0.25), body.height);
  }
  return Offset(0, body.height * (1 - (u - 0.75) / 0.25));
}

/// Inward normal of the edge a perimeter parameter falls on, so hardware can
/// be seated just inside the rim rather than straddling it.
Offset edgeNormal(double s) {
  final u = (s % 1 + 1) % 1;
  if (u < 0.25) return const Offset(0, 1);
  if (u < 0.50) return const Offset(-1, 0);
  if (u < 0.75) return const Offset(0, -1);
  return const Offset(1, 0);
}

/// A point on the perimeter, pushed [inset] px toward the interior.
Offset seatOnEdge(double s, Size body, double inset) =>
    edgePoint(s, body) + edgeNormal(s) * inset;

/// Interpolates two perimeter parameters the short way round.
double lerpEdge(double a, double b, double t) {
  var d = b - a;
  if (d > 0.5) {
    d -= 1;
  } else if (d < -0.5) {
    d += 1;
  }
  return a + d * t;
}

/// The three form factors the frame can morph between.
enum DeviceType { mobile, tablet, desktop }

/// The laptop deck (keyboard base). It is a real plane tilted toward the
/// viewer, so it unfolds out of the body instead of appearing: [depth] grows
/// from 0 and [angleDeg] falls from 90° (edge-on, invisible) to its rest tilt.
@immutable
class DeviceDeck {
  const DeviceDeck({
    this.depth = 0,
    this.angleDeg = 90,
    this.hingeHeight = 0,
    this.opacity = 0,
  });

  static const none = DeviceDeck();

  /// Physical depth of the deck, front to back, in logical px. Roughly the
  /// height of the lid, so shut it covers the whole back of the screen.
  final double depth;

  /// Resting tilt from the screen plane; the frame overrides this from the
  /// live hinge angle (180° is shut, 45° is a laptop open at 135°).
  final double angleDeg;

  final double hingeHeight;

  /// Fades the keys, the trackpad and the hinge shading in with the deck.
  final double opacity;

  /// Height the tilted deck actually occupies on screen, so the frame can
  /// reserve space for it while it swings open.
  double projectedHeight(double perspective) =>
      projectedHeightAt(angleDeg, perspective);

  /// Same, for an angle driven by the hinge rather than the preset. Past 90°
  /// the deck has folded up behind the screen, so it occupies nothing.
  double projectedHeightAt(double angle, double perspective) {
    if (depth <= 0) return 0;
    final a = angle * math.pi / 180;
    final z = depth * math.sin(a);
    final h = depth * math.cos(a) * (perspective / (perspective - z));
    return h < 0 ? 0 : h;
  }

  /// Same deck with its depth scaled — used to grow it out of the body in its
  /// own beat of the transition.
  DeviceDeck scaledDepth(double t) => DeviceDeck(
        depth: depth * t,
        angleDeg: angleDeg,
        hingeHeight: hingeHeight,
        opacity: opacity,
      );

  static DeviceDeck lerp(DeviceDeck a, DeviceDeck b, double t) => DeviceDeck(
        depth: lerpDouble(a.depth, b.depth, t)!,
        angleDeg: lerpDouble(a.angleDeg, b.angleDeg, t)!,
        hingeHeight: lerpDouble(a.hingeHeight, b.hingeHeight, t)!,
        opacity: lerpDouble(a.opacity, b.opacity, t)!,
      );
}

/// A hardware button on the side of the body.
@immutable
class SideButton {
  const SideButton({
    required this.side,
    required this.start,
    required this.length,
    this.thickness = 3,
    this.opacity = 1,
  });

  /// -1 = left edge, 1 = right edge.
  final int side;

  /// Offset from the top of the body, as a fraction of body height.
  final double start;

  /// Length, as a fraction of body height.
  final double length;

  final double thickness;
  final double opacity;

  static SideButton lerp(SideButton a, SideButton b, double t) => SideButton(
        side: t < 0.5 ? a.side : b.side,
        start: lerpDouble(a.start, b.start, t)!,
        length: lerpDouble(a.length, b.length, t)!,
        thickness: lerpDouble(a.thickness, b.thickness, t)!,
        opacity: lerpDouble(a.opacity, b.opacity, t)!,
      );

  SideButton withOpacity(double o) => SideButton(
      side: side, start: start, length: length, thickness: thickness, opacity: o);
}

/// Everything the frame needs to draw and animate one device. Every field is
/// interpolatable, so a morph is one [DeviceConfig.lerp] per frame.
@immutable
class DeviceConfig {
  const DeviceConfig({
    required this.type,
    required this.label,
    required this.bodySize,
    required this.bezel,
    required this.bodyRadius,
    required this.screenRadius,
    this.notchSize = Size.zero,
    this.notchRadius = 0,
    this.cameraEdge = 0.125,
    this.cameraRadius = 0,
    this.speakerEdge = 0.625,
    this.speakerSize = Size.zero,
    this.homeIndicatorWidth = 0,
    this.sideButtons = const <SideButton>[],
    this.deck = DeviceDeck.none,
    this.shadowBlur = 40,
    this.shadowOffsetY = 18,
  });

  final DeviceType type;
  final String label;

  /// Outer size of the body (the lid, on a laptop). The deck is drawn below it.
  final Size bodySize;

  final EdgeInsets bezel;
  final double bodyRadius;
  final double screenRadius;

  /// Notch cut into the top of the screen; grows and shrinks with the morph.
  final Size notchSize;
  final double notchRadius;

  /// Camera position along the body's perimeter — see [edgePoint].
  final double cameraEdge;
  final double cameraRadius;

  /// Earpiece position along the body's perimeter.
  final double speakerEdge;
  final Size speakerSize;
  final double homeIndicatorWidth;

  final List<SideButton> sideButtons;
  final DeviceDeck deck;

  final double shadowBlur;
  final double shadowOffsetY;

  /// Logical size of the glass — the size the page is laid out at.
  Size get screenSize => Size(
        bodySize.width - bezel.horizontal,
        bodySize.height - bezel.vertical,
      );

  Size totalSize(double perspective) => Size(
        bodySize.width,
        bodySize.height + deck.projectedHeight(perspective),
      );

  static Size _lerpSize(Size a, Size b, double t) =>
      Size(lerpDouble(a.width, b.width, t)!, lerpDouble(a.height, b.height, t)!);

  /// Side buttons are matched by index; one missing on either side fades
  /// instead of popping, so the hardware travels with the body.
  static DeviceConfig lerp(DeviceConfig a, DeviceConfig b, double t) {
    final count = math.max(a.sideButtons.length, b.sideButtons.length);
    final buttons = <SideButton>[];
    for (var i = 0; i < count; i++) {
      final ba = i < a.sideButtons.length
          ? a.sideButtons[i]
          : (i < b.sideButtons.length ? b.sideButtons[i].withOpacity(0) : null);
      final bb = i < b.sideButtons.length
          ? b.sideButtons[i]
          : (i < a.sideButtons.length ? a.sideButtons[i].withOpacity(0) : null);
      if (ba == null || bb == null) continue;
      buttons.add(SideButton.lerp(ba, bb, t));
    }

    return DeviceConfig(
      type: t < 0.5 ? a.type : b.type,
      label: t < 0.5 ? a.label : b.label,
      bodySize: _lerpSize(a.bodySize, b.bodySize, t),
      bezel: EdgeInsets.lerp(a.bezel, b.bezel, t)!,
      bodyRadius: lerpDouble(a.bodyRadius, b.bodyRadius, t)!,
      screenRadius: lerpDouble(a.screenRadius, b.screenRadius, t)!,
      notchSize: _lerpSize(a.notchSize, b.notchSize, t),
      notchRadius: lerpDouble(a.notchRadius, b.notchRadius, t)!,
      cameraEdge: lerpEdge(a.cameraEdge, b.cameraEdge, t),
      cameraRadius: lerpDouble(a.cameraRadius, b.cameraRadius, t)!,
      speakerEdge: lerpEdge(a.speakerEdge, b.speakerEdge, t),
      speakerSize: _lerpSize(a.speakerSize, b.speakerSize, t),
      homeIndicatorWidth:
          lerpDouble(a.homeIndicatorWidth, b.homeIndicatorWidth, t)!,
      sideButtons: buttons,
      deck: DeviceDeck.lerp(a.deck, b.deck, t),
      shadowBlur: lerpDouble(a.shadowBlur, b.shadowBlur, t)!,
      shadowOffsetY: lerpDouble(a.shadowOffsetY, b.shadowOffsetY, t)!,
    );
  }
}

/// Built-in presets. Override any of them with [DeviceFrame.configResolver].
class DevicePresets {
  const DevicePresets._();

  static const mobile = DeviceConfig(
    type: DeviceType.mobile,
    label: 'Mobile',
    bodySize: Size(390, 844),
    bezel: EdgeInsets.all(12),
    bodyRadius: 54,
    screenRadius: 42,
    notchSize: Size(126, 32),
    notchRadius: 16,
    cameraEdge: 0.1463,
    cameraRadius: 5,
    speakerEdge: 0.1175,
    speakerSize: Size(44, 5),
    homeIndicatorWidth: 134,
    sideButtons: [
      SideButton(side: -1, start: 0.18, length: 0.035),
      SideButton(side: -1, start: 0.235, length: 0.065),
      SideButton(side: -1, start: 0.315, length: 0.065),
      SideButton(side: 1, start: 0.26, length: 0.10),
    ],
    shadowBlur: 46,
    shadowOffsetY: 20,
  );

  /// Landscape tablet — wider than tall.
  static const tablet = DeviceConfig(
    type: DeviceType.tablet,
    label: 'Tablet',
    bodySize: Size(1194, 834),
    bezel: EdgeInsets.all(16),
    bodyRadius: 38,
    screenRadius: 24,
    cameraEdge: 0.875,
    cameraRadius: 4,
    speakerEdge: 0.625,
    speakerSize: Size(64, 3),
    homeIndicatorWidth: 200,
    sideButtons: [
      SideButton(side: -1, start: 0.10, length: 0.05),
      SideButton(side: -1, start: 0.20, length: 0.07),
      SideButton(side: -1, start: 0.30, length: 0.07),
      SideButton(side: 1, start: 0.06, length: 0.06),
    ],
    shadowBlur: 54,
    shadowOffsetY: 22,
  );

  static const desktop = DeviceConfig(
    type: DeviceType.desktop,
    label: 'Desktop',
    bodySize: Size(1280, 830),
    bezel: EdgeInsets.fromLTRB(11, 22, 11, 12),
    bodyRadius: 16,
    screenRadius: 8,
    notchSize: Size(180, 22),
    notchRadius: 8,
    cameraEdge: 0.125,
    cameraRadius: 3.5,
    deck: DeviceDeck(depth: 800, angleDeg: 45, hingeHeight: 9, opacity: 1),
    shadowBlur: 60,
    shadowOffsetY: 26,
  );

  static DeviceConfig of(DeviceType type) => switch (type) {
        DeviceType.mobile => mobile,
        DeviceType.tablet => tablet,
        DeviceType.desktop => desktop,
      };
}
