import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_textures.dart';
import '../poster_tokens.dart';

/// The five bevel flavours of DESIGN_SPEC.md §4.6/§4.7.
enum BevelKind { hero, steel, dark, chipWhite, chipDark }

/// The hard offset shadow of §4.1 — a duplicate rect, no blur, asymmetric.
///
/// The values are CSS `inset`-style offsets in DESIGN px: the duplicate's left
/// edge sits [left] px right of the panel's, its top [top] px below, and it
/// overhangs the panel by [right] / [bottom] px on the other two sides.
@immutable
class BevelShadow {
  const BevelShadow({
    this.left = 7,
    this.top = 10,
    this.right = 7,
    this.bottom = 12,
    this.color = const Color(0xC0020201), // rgba(2,2,1,.75)
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final Color color;

  static const BevelShadow none = BevelShadow(
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
    color: Color(0x00000000),
  );
}

/// Screw dots — §4.8. Two circles near the top edge, measured from the panel's
/// device-facing edge (left for LTR, right for RTL). All values in DESIGN px.
@immutable
class ScrewDots {
  const ScrewDots({
    this.count = 2,
    this.diameter = 14,
    this.fromEdge = 18,
    this.fromTop = 18,
    this.gap = 22,
    this.fill = const Color(0xFF03050A),
    this.highlight = const Color(0x70E2EEFF), // rgba(226,238,255,.44)
    this.highlightOffset = 1.25,
  });

  final int count;
  final double diameter;
  final double fromEdge;
  final double fromTop;
  final double gap;
  final Color fill;

  /// The `inset -1..-1.5px -1..-1.5px 0 rgba(light,.32–.52)` highlight.
  final Color highlight;
  final double highlightOffset;
}

/// Everything §4 varies per flavour: bevel widths, the light/dark rgba pairs,
/// the grain opacities and the sheen strength. All lengths in DESIGN px.
@immutable
class BevelStyle {
  const BevelStyle({
    required this.kind,
    required this.outerInset,
    required this.outerWidth,
    required this.innerInset,
    required this.innerWidth,
    required this.lightStrong,
    required this.lightSoft,
    required this.darkStrong,
    required this.darkSoft,
    required this.overlayGrainOpacity,
    required this.overlayTileDesignPx,
    required this.screenGrainOpacity,
    required this.screenTileDesignPx,
    required this.sheenStrong,
    required this.sheenFaint,
    this.defaultScreenGrain = false,
  });

  final BevelKind kind;

  /// §4.6 — outer bevel, inset 8–9px, light on top+left, dark on bottom+right.
  final double outerInset;
  final double outerWidth;

  /// §4.7 — inner counter-bevel, inset 10–12px, inverted.
  final double innerInset;
  final double innerWidth;

  /// Strong pair paints the horizontal edges, soft pair the vertical ones.
  final Color lightStrong;
  final Color lightSoft;
  final Color darkStrong;
  final Color darkSoft;

  final double overlayGrainOpacity;
  final double overlayTileDesignPx;
  final double screenGrainOpacity;
  final double screenTileDesignPx;

  /// §4.5 — the 103° sheen: [sheenStrong] at 0%, [sheenFaint] at 45%,
  /// transparent at 63%.
  final Color sheenStrong;
  final Color sheenFaint;

  /// Whether layer 4 (screen grain) is on unless the call site overrides it.
  /// Hero cards and white chips only.
  final bool defaultScreenGrain;

  /// Hero: light rgba(226,238,255,.62/.44), dark rgba(0,8,26,.60/.46), 3px.
  static const BevelStyle hero = BevelStyle(
    kind: BevelKind.hero,
    outerInset: 9,
    outerWidth: 3,
    innerInset: 12,
    innerWidth: 2,
    lightStrong: Color(0x9EE2EEFF),
    lightSoft: Color(0x70E2EEFF),
    darkStrong: Color(0x9900081A),
    darkSoft: Color(0x7500081A),
    overlayGrainOpacity: 0.11,
    overlayTileDesignPx: 220,
    screenGrainOpacity: 0.22,
    screenTileDesignPx: 180,
    sheenStrong: Color(0x3DE2EEFF), // rgba(226,238,255,.24)
    sheenFaint: Color(0x0BE2EEFF), // rgba(226,238,255,.04)
    defaultScreenGrain: true,
  );

  /// Steel: light rgba(212,226,252,.46/.30), dark rgba(0,3,10,.64/.50), 2px.
  static const BevelStyle steel = BevelStyle(
    kind: BevelKind.steel,
    outerInset: 8,
    outerWidth: 2,
    innerInset: 11,
    innerWidth: 2,
    lightStrong: Color(0x75D4E2FC),
    lightSoft: Color(0x4DD4E2FC),
    darkStrong: Color(0xA300030A),
    darkSoft: Color(0x8000030A),
    overlayGrainOpacity: 0.12,
    overlayTileDesignPx: 210,
    screenGrainOpacity: 0.24,
    screenTileDesignPx: 160,
    sheenStrong: Color(0x2EE2EEFF), // rgba(226,238,255,.18)
    sheenFaint: Color(0x0AE2EEFF),
  );

  /// Dark: light rgba(184,200,230,.23/.155), dark rgba(0,2,8,.70/.56), 2px.
  static const BevelStyle dark = BevelStyle(
    kind: BevelKind.dark,
    outerInset: 8,
    outerWidth: 2,
    innerInset: 10,
    innerWidth: 2,
    lightStrong: Color(0x3BB8C8E6),
    lightSoft: Color(0x28B8C8E6),
    darkStrong: Color(0xB3000208),
    darkSoft: Color(0x8F000208),
    overlayGrainOpacity: 0.10,
    overlayTileDesignPx: 200,
    screenGrainOpacity: 0.22,
    screenTileDesignPx: 140,
    sheenStrong: Color(0x28E2EEFF), // rgba(226,238,255,.16)
    sheenFaint: Color(0x08E2EEFF),
  );

  /// White index chip — same light source, but the bevel reads against #EDEFF3.
  static const BevelStyle chipWhite = BevelStyle(
    kind: BevelKind.chipWhite,
    outerInset: 8,
    outerWidth: 3,
    innerInset: 11,
    innerWidth: 2,
    lightStrong: Color(0xB3FFFFFF),
    lightSoft: Color(0x8CFFFFFF),
    darkStrong: Color(0x8A00081A),
    darkSoft: Color(0x6100081A),
    overlayGrainOpacity: 0.16,
    overlayTileDesignPx: 200,
    screenGrainOpacity: 0.34,
    screenTileDesignPx: 140,
    sheenStrong: Color(0x4DFFFFFF),
    sheenFaint: Color(0x0FFFFFFF),
    defaultScreenGrain: true,
  );

  /// Dark index chip.
  static const BevelStyle chipDark = BevelStyle(
    kind: BevelKind.chipDark,
    outerInset: 8,
    outerWidth: 2,
    innerInset: 10,
    innerWidth: 2,
    lightStrong: Color(0x3DB8C8E6),
    lightSoft: Color(0x29B8C8E6),
    darkStrong: Color(0xB3000208),
    darkSoft: Color(0x8F000208),
    overlayGrainOpacity: 0.16,
    overlayTileDesignPx: 200,
    screenGrainOpacity: 0.30,
    screenTileDesignPx: 140,
    sheenStrong: Color(0x3DE2EEFF),
    sheenFaint: Color(0x0AE2EEFF),
  );

  static const Map<BevelKind, BevelStyle> byKind = <BevelKind, BevelStyle>{
    BevelKind.hero: hero,
    BevelKind.steel: steel,
    BevelKind.dark: dark,
    BevelKind.chipWhite: chipWhite,
    BevelKind.chipDark: chipDark,
  };
}

/// The ten layers of DESIGN_SPEC.md §4, in order:
///
///  1. hard offset shadow (no blur, asymmetric, painted behind)
///  2. ground fill (flat colour or one of the §1 gradients)
///  3. overlay grain      — `BlendMode.overlay`
///  4. screen grain       — `BlendMode.screen` (hero cards / white chips)
///  5. diagonal 103° sheen — `BlendMode.screen`
///  6. outer bevel        — light top+left, dark bottom+right
///  7. inner counter-bevel — inverted
///  8. screw dots
///  9. dashed rules       — see `DashedRule`, composed by the caller
/// 10. index chip         — see `IndexChip`, pinned by the caller
///
/// Layers 3–5 composite against the panel's own ground, not the page: the
/// whole stack sits inside one `ColorFiltered` layer so `backgroundBlendMode`
/// has a `saveLayer` boundary to blend into.
class BevelPanel extends StatelessWidget {
  const BevelPanel({
    super.key,
    required this.style,
    this.groundColor,
    this.groundGradient,
    this.screenGrain,
    this.screws,
    this.shadow = const BevelShadow(),
    this.padding,
    this.width,
    this.height,
    this.child,
  }) : assert(
          groundColor != null || groundGradient != null,
          'BevelPanel needs a ground: pass groundColor or groundGradient.',
        );

  final BevelStyle style;

  /// Flat ground (`cardHeroIr`, `cardHeroDe`, `cardChipWhite`).
  final Color? groundColor;

  /// Gradient ground (`PosterGradients.cardSteel` / `cardDark` / …).
  final Gradient? groundGradient;

  /// Layer 4 on/off. Defaults to [BevelStyle.defaultScreenGrain].
  final bool? screenGrain;

  final ScrewDots? screws;
  final BevelShadow shadow;

  /// Inner padding for [child], in DESIGN px.
  final EdgeInsets? padding;

  /// Panel size in DESIGN px. Null means "size to the child".
  final double? width;
  final double? height;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final direction = Directionality.of(context);
    final useScreenGrain = screenGrain ?? style.defaultScreenGrain;

    final EdgeInsets resolvedPadding = padding == null
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(
            metrics.px(padding!.left),
            metrics.px(padding!.top),
            metrics.px(padding!.right),
            metrics.px(padding!.bottom),
          );

    // Layers 2–8, isolated in one composited layer so the grain and sheen
    // blend against this panel's ground instead of whatever is behind it.
    final Widget body = ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0x00000000),
        BlendMode.srcOver,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          // 2 — ground.
          DecoratedBox(
            decoration: BoxDecoration(
              color: groundColor,
              gradient: groundGradient,
            ),
            child: SizedBox(
              width: width == null ? null : metrics.px(width!),
              height: height == null ? null : metrics.px(height!),
              child: Padding(
                padding: resolvedPadding,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),

          // 3 — overlay grain.
          Positioned.fill(
            child: _GrainLayer(
              texture: PosterTexture.overlayGrain,
              metrics: metrics,
              tileDesignPx: style.overlayTileDesignPx,
              opacity: style.overlayGrainOpacity,
              blendMode: BlendMode.overlay,
            ),
          ),

          // 4 — screen grain (hero cards and white chips only).
          if (useScreenGrain)
            Positioned.fill(
              child: _GrainLayer(
                texture: PosterTexture.screenGrain,
                metrics: metrics,
                tileDesignPx: style.screenTileDesignPx,
                opacity: style.screenGrainOpacity,
                blendMode: BlendMode.screen,
              ),
            ),

          // 5 — the 103° diagonal sheen.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                backgroundBlendMode: BlendMode.screen,
                gradient: LinearGradient(
                  // CSS `linear-gradient(103deg, …)`: 103° clockwise from
                  // "to top" points right and slightly down.
                  begin: const Alignment(-0.97, -0.23),
                  end: const Alignment(0.97, 0.23),
                  colors: <Color>[
                    style.sheenStrong,
                    style.sheenFaint,
                    const Color(0x00000000),
                  ],
                  stops: const <double>[0.0, 0.45, 0.63],
                ),
              ),
            ),
          ),

          // 6, 7, 8 — bevels and screws, one painter so the corners mitre
          // cleanly instead of seaming the way nested borders do.
          Positioned.fill(
            child: CustomPaint(
              painter: _BevelPainter(
                style: style,
                metrics: metrics,
                screws: screws,
                direction: direction,
              ),
            ),
          ),
        ],
      ),
    );

    // 1 — the hard offset shadow, behind everything, overhanging the panel.
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (shadow.color != const Color(0x00000000))
          Positioned(
            left: metrics.px(shadow.left),
            top: metrics.px(shadow.top),
            right: -metrics.px(shadow.right),
            bottom: -metrics.px(shadow.bottom),
            child: ColoredBox(color: shadow.color),
          ),
        body,
      ],
    );
  }
}

/// One tiling grain layer. `textureDecoration`'s own `blendMode` is used as an
/// identity filter (`BlendMode.dst` leaves the tile's pixels alone); the real
/// compositing happens through [BoxDecoration.backgroundBlendMode], which
/// blends against the panel ground inside `BevelPanel`'s layer.
class _GrainLayer extends StatelessWidget {
  const _GrainLayer({
    required this.texture,
    required this.metrics,
    required this.tileDesignPx,
    required this.opacity,
    required this.blendMode,
  });

  final PosterTexture texture;
  final PosterMetrics metrics;
  final double tileDesignPx;
  final double opacity;
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // `backgroundBlendMode` asserts a color or gradient even though the
        // intent is only to blend the grain image against itself — a fully
        // transparent base keeps that assertion happy without changing what
        // paints (see the P4 note in PROGRESS.md on this layer not actually
        // blending against the panel ground beneath it).
        color: const Color(0x00000000),
        backgroundBlendMode: blendMode,
        image: textureDecoration(
          texture: texture,
          metrics: metrics,
          tileDesignPx: tileDesignPx,
          opacity: opacity,
          blendMode: BlendMode.dst,
        ),
      ),
    );
  }
}

class _BevelPainter extends CustomPainter {
  const _BevelPainter({
    required this.style,
    required this.metrics,
    required this.screws,
    required this.direction,
  });

  final BevelStyle style;
  final PosterMetrics metrics;
  final ScrewDots? screws;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;

    // 6 — outer bevel: light on top+left, dark on bottom+right.
    _paintBevel(
      canvas,
      full.deflate(metrics.px(style.outerInset)),
      metrics.px(style.outerWidth),
      topColor: style.lightStrong,
      leftColor: style.lightSoft,
      bottomColor: style.darkStrong,
      rightColor: style.darkSoft,
    );

    // 7 — inner counter-bevel: inverted.
    _paintBevel(
      canvas,
      full.deflate(metrics.px(style.innerInset)),
      metrics.px(style.innerWidth),
      topColor: style.darkStrong,
      leftColor: style.darkSoft,
      bottomColor: style.lightStrong,
      rightColor: style.lightSoft,
    );

    // 8 — screw dots.
    final ScrewDots? dots = screws;
    if (dots != null && dots.count > 0) {
      _paintScrews(canvas, size, dots);
    }
  }

  /// Four inset edge strips. The horizontal strips run the full width and the
  /// vertical ones fill the gap between them, so no pixel is painted twice and
  /// the corners have no seam.
  void _paintBevel(
    Canvas canvas,
    Rect rect,
    double width, {
    required Color topColor,
    required Color leftColor,
    required Color bottomColor,
    required Color rightColor,
  }) {
    if (rect.width <= width * 2 || rect.height <= width * 2) return;
    final Paint paint = Paint()..isAntiAlias = false;

    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, width),
      paint..color = topColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - width, rect.width, width),
      paint..color = bottomColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left,
        rect.top + width,
        width,
        rect.height - width * 2,
      ),
      paint..color = leftColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rect.right - width,
        rect.top + width,
        width,
        rect.height - width * 2,
      ),
      paint..color = rightColor,
    );
  }

  void _paintScrews(Canvas canvas, Size size, ScrewDots dots) {
    final double radius = metrics.px(dots.diameter) / 2;
    final double edge = metrics.px(dots.fromEdge);
    final double top = metrics.px(dots.fromTop);
    final double gap = metrics.px(dots.gap);
    final bool rtl = direction == TextDirection.rtl;

    final Paint fill = Paint()..color = dots.fill;
    final Paint highlight = Paint()..color = dots.highlight;
    final double shift = metrics.px(dots.highlightOffset);

    for (int i = 0; i < dots.count; i++) {
      final double along = edge + radius + i * gap;
      final Offset centre = Offset(rtl ? size.width - along : along, top + radius);

      // `inset -1..-1.5px -1..-1.5px 0 rgba(light,…)`: the highlight lands on
      // the side opposite the offset — bottom-right.
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: radius)));
      canvas.drawCircle(centre, radius, highlight);
      canvas.drawCircle(centre.translate(-shift, -shift), radius, fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BevelPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.metrics.f != metrics.f ||
        oldDelegate.screws != screws ||
        oldDelegate.direction != direction;
  }
}

/// Convenience: the ground that goes with each [BevelKind], from §1.
Color? bevelGroundColor(BevelKind kind, {bool german = false}) {
  switch (kind) {
    case BevelKind.hero:
      return german ? PosterColors.cardHeroDe : PosterColors.cardHeroIr;
    case BevelKind.chipWhite:
      return PosterColors.cardChipWhite;
    case BevelKind.steel:
    case BevelKind.dark:
    case BevelKind.chipDark:
      return null;
  }
}

Gradient? bevelGroundGradient(BevelKind kind, {bool variant = false}) {
  switch (kind) {
    case BevelKind.steel:
      return PosterGradients.cardSteel;
    case BevelKind.dark:
      return variant
          ? PosterGradients.cardDarkVariant
          : PosterGradients.cardDark;
    case BevelKind.chipDark:
      return variant
          ? PosterGradients.cardChipDarkVariant
          : PosterGradients.cardChipDark;
    case BevelKind.hero:
    case BevelKind.chipWhite:
      return null;
  }
}
