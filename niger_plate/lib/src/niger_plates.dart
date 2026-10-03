import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'niger_alphabets.dart';
import 'niger_colors.dart';
import 'niger_country.dart';

/// Where the ink sits, in plate coordinates. Measured off the Wikipedia
/// artwork (`НІГЕР_НОМЕР_1.gif`, `НІГЕР_НОМЕР_2.gif`, 669×144) by normalising
/// each image to the 520×110 mm the article gives. The artwork is drawn at
/// 4.65, not 4.73, so x is stretched by 1.2%.
///
/// The plate is one row, no rules: region digit and series letter, a mark,
/// four serial digits, and the map over `RN` at the right.
///
/// Measured ink, which the goldens are checked against (private / commercial):
///   digits           y 19.1..91.7 (cap 72.6) / 17.6..91.7 (74.1, outlined)
///   region digit     centre 43.5; series letter centre 98 (pitch 54.5)
///   serial           centres 232.4 285.7 339.1 391.7 / 229.8 284.1 339.2 393.7
///   map              x 442.3..488.1 y 17.6..55.0 / x 432.2..484.2 y 16.8..56.5
///   RN               x 450.0..483.5 y 71.8..91.7 / x 446.2..473.4 y 66.5..90.1
///
/// core sets a glyph at `0.72 * box height`, so ink is about 52% of the box.
/// The 72.6 of cap ink would need a 140-tall box on a 110 canvas; the box is
/// the whole canvas height instead and the digits come out ~79% of the
/// reference.
abstract final class _Layout {
  static const double width = 520;
  static const double height = 110;

  static const double digitHeight = height;
  static const double regionLeft = 16.25;
  static const double regionPitch = 54.5;
  static const double serialPitch = 53.9;
  static const double serialLeft = 204.1;
  static const int serialDigits = 4;
}

/// What differs between the two artworks: the country (and so the map the
/// panel paints), the box that map and the `RN` under it occupy, and the
/// mark between the series letter and the serial.
class _Livery {
  const _Livery({
    required this.id,
    required this.country,
    required this.map,
    required this.rn,
    required this.rnGlyph,
    required this.mark,
    required this.markColor,
    required this.markRadius,
  });

  final String id;
  final PlateCountry country;
  final PlateBox map;

  /// Centred on the measured ink of the `RN`; the box is wider than the ink
  /// because a label spills rather than wraps.
  final PlateBox rn;
  final double rnGlyph;
  final PlateBox mark;
  final Color markColor;
  final double markRadius;
}

abstract final class NigerPlates {
  static const _Livery _private = _Livery(
    id: 'ne.2005.private',
    country: NigerCountry.private,
    map: PlateBox(442.3, 17.6, 45.8, 37.4),
    rn: PlateBox(441.75, 62.0, 50, 40),
    rnGlyph: 38,
    // The grey dot: 26 across, x 155.5..181.9, y 64.2..90.1.
    mark: PlateBox(155.5, 64.2, 26.4, 25.9),
    markColor: NigerColors.dot,
    markRadius: 13,
  );

  static const _Livery _commercial = _Livery(
    id: 'ne.2005.commercial',
    country: NigerCountry.commercial,
    map: PlateBox(432.2, 16.8, 52.0, 39.7),
    rn: PlateBox(433.6, 48.3, 50, 60),
    rnGlyph: 45,
    // The silver square: 20 across, x 157.0..177.2, y 44.3..64.2. The
    // artwork rims it in a darker orange, which is not drawn.
    mark: PlateBox(157.0, 44.3, 20.2, 19.9),
    markColor: NigerColors.seal,
    markRadius: 2,
  );

  static PlateSpec _build(_Livery livery) => PlateSpec(
    id: livery.id,
    country: livery.country,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    panel: PlatePanel(box: livery.map, padding: EdgeInsets.zero),
    bands: <PlateBand>[
      PlateBand(
        box: livery.mark,
        color: livery.markColor,
        topCornerRadius: livery.markRadius,
        bottomCornerRadius: livery.markRadius,
      ),
    ],
    labels: <PlateLabel>[
      PlateLabel(text: 'RN', box: livery.rn, glyphHeight: livery.rnGlyph),
    ],
    slots: <PlateSlot>[
      const PlateSlot(
        alphabet: NigerAlphabets.region,
        box: PlateBox(
          _Layout.regionLeft,
          0,
          _Layout.regionPitch,
          _Layout.digitHeight,
        ),
      ),
      const PlateSlot(
        alphabet: NigerAlphabets.series,
        box: PlateBox(
          _Layout.regionLeft + _Layout.regionPitch,
          0,
          _Layout.regionPitch,
          _Layout.digitHeight,
        ),
      ),
      ...plateRegister(
        alphabet: NigerAlphabets.digits,
        count: _Layout.serialDigits,
        left: _Layout.serialLeft,
        top: 0,
        width: _Layout.serialPitch,
        height: _Layout.digitHeight,
      ),
    ],
    textGroups: <PlateTextGroup>[
      const PlateTextGroup(<int>[0], key: 'region'),
      const PlateTextGroup(<int>[1], key: 'series'),
      PlateTextGroup(
        List<int>.generate(_Layout.serialDigits, (i) => 2 + i),
        key: 'serial',
      ),
    ],
  );

  static final PlateSpec privateSpec = _build(_private);
  static final PlateSpec commercialSpec = _build(_commercial);
}
