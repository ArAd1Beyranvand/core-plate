import 'package:flutter/foundation.dart';

/// An image a country package ships, named so it survives the package split:
/// [package] is the package that OWNS [path], not the one rendering it.
///
/// Every country now ships a vector (or raster) of its own flag rather than
/// leaning on a shared flag package: one less transitive dependency for every
/// consumer, and one rendering path instead of two.
@immutable
sealed class PlateAsset {
  const PlateAsset(this.path, {required this.package});

  /// Asset path relative to [package]'s root.
  final String path;

  /// The package that declares [path] in its `pubspec.yaml`.
  final String package;
}

/// A vector asset, rasterised live at the exact device-pixel size. Preferred
/// for flags: a detailed emblem (fine script around a border, say) that a
/// pre-quantized bitmap format would read as pixelation at plate scale stays
/// crisp when the raw vector is drawn.
class SvgPlateAsset extends PlateAsset {
  const SvgPlateAsset(super.path, {required super.package});
}

/// A bitmap asset (PNG and friends).
class RasterPlateAsset extends PlateAsset {
  const RasterPlateAsset(super.path, {required super.package});
}
