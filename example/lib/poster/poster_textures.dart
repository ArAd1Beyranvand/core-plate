import 'package:flutter/material.dart';

import 'poster_scale.dart';

/// The four PNG tiles from DESIGN_SPEC.md §3.
enum PosterTexture { grainA, grainB, screenGrain, overlayGrain }

const Map<PosterTexture, String> _assetFor = {
  PosterTexture.grainA: 'assets/textures/bg_grain_a.png',
  PosterTexture.grainB: 'assets/textures/bg_grain_b.png',
  PosterTexture.screenGrain: 'assets/textures/tex_screen.png',
  PosterTexture.overlayGrain: 'assets/textures/tex_overlay.png',
};

/// Builds the [DecorationImage] for [texture], tiling at [tileDesignPx]
/// *design* px (the CSS `background-size`) regardless of the PNG's own
/// pixel size — scaled through [metrics] to real px — with [opacity] and
/// [blendMode] applied.
///
/// The tile is forced to [tileDesignPx] (scaled) logical px on a side by
/// decoding the source through [ResizeImage] at that target size, then
/// tiling the decoded image with [ImageRepeat.repeat].
DecorationImage textureDecoration({
  required PosterTexture texture,
  required PosterMetrics metrics,
  required double tileDesignPx,
  required double opacity,
  required BlendMode blendMode,
}) {
  final tileSize = metrics.px(tileDesignPx).round().clamp(1, 4096);
  return DecorationImage(
    image: ResizeImage(
      AssetImage(_assetFor[texture]!),
      width: tileSize,
      height: tileSize,
    ),
    repeat: ImageRepeat.repeat,
    fit: BoxFit.none,
    alignment: Alignment.topLeft,
    opacity: opacity,
    colorFilter: ColorFilter.mode(Colors.white, blendMode),
  );
}
