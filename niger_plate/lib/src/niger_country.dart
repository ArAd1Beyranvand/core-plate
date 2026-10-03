import 'package:core_plate/core_plate.dart';

import 'niger_colors.dart';

/// Niger as two `PlateCountry`s, differing only in the map the panel paints:
/// the private plate's is a black silhouette, the commercial plate's is
/// filled with the national flag. The panel box is the map's own box, so no
/// panel colour shows around it; each aspect ratio is that box's.
abstract final class NigerCountry {
  static const PlateCountry private = PlateCountry(
    code: 'ne',
    captionLines: <String>[],
    panelColor: NigerColors.privateWhite,
    panelTextColor: NigerColors.black,
    flagAspectRatio: 45.8 / 37.4,
    flag: SvgPlateAsset('assets/maps/niger_map.svg', package: 'niger_plate'),
  );

  static const PlateCountry commercial = PlateCountry(
    code: 'ne',
    captionLines: <String>[],
    panelColor: NigerColors.commercialOrange,
    panelTextColor: NigerColors.black,
    flagAspectRatio: 52.0 / 39.7,
    flag: SvgPlateAsset(
      'assets/maps/niger_map_flag.svg',
      package: 'niger_plate',
    ),
  );

  /// For the plates that print no map: the panel is switched off by the spec.
  static const PlateCountry plain = PlateCountry(
    code: 'ne',
    captionLines: <String>[],
    panelColor: NigerColors.privateWhite,
    panelTextColor: NigerColors.black,
  );

  /// The military plate prints the flag itself at the left.
  static const PlateCountry military = PlateCountry(
    code: 'ne',
    captionLines: <String>[],
    panelColor: NigerColors.militaryBlack,
    panelTextColor: NigerColors.militaryWhite,
    flagAspectRatio: 7 / 6,
    flag: SvgPlateAsset('assets/maps/niger_flag.svg', package: 'niger_plate'),
  );
}
