import 'package:flutter/foundation.dart';

/// An image a country package ships. [package] is the package that OWNS
/// [path], not the one rendering it.
@immutable
sealed class PlateAsset {
  const PlateAsset(this.path, {required this.package});

  /// Asset path relative to [package]'s root.
  final String path;

  /// The package that declares [path] in its `pubspec.yaml`.
  final String package;
}

/// Rasterised live at the exact device-pixel size. Preferred for flags: a
/// detailed emblem stays crisp at plate scale where a bitmap would pixelate.
class SvgPlateAsset extends PlateAsset {
  const SvgPlateAsset(super.path, {required super.package});
}

class RasterPlateAsset extends PlateAsset {
  const RasterPlateAsset(super.path, {required super.package});
}
