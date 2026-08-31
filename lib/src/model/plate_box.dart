import 'package:flutter/widgets.dart';

/// A rectangle in plate-space: the same coordinate system slots, rules, labels,
/// decals and the country panel all live in, with the origin at the plate's
/// top-left and units matching [PlateSpec.canvasWidth]/[canvasHeight].
@immutable
class PlateBox {
  const PlateBox(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
  double get right => left + width;
  double get bottom => top + height;
  Rect get rect => Rect.fromLTWH(left, top, width, height);
}
