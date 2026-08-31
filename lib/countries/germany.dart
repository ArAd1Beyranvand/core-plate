import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_asset.dart';
import '../model/plate_box.dart';
import '../model/plate_country.dart';
import '../model/plate_spec.dart';

/// Germany's plate chrome. Becomes the `germany_plate` package in the split —
/// this file is a straight directory move, so it carries no reference to
/// `countries/iran.dart`.
class GermanyCountry {
  const GermanyCountry._();

  /// Germany, as it appears on a standard EU plate: a blue panel with a white
  /// "D" identifier beside the flag.
  static const PlateCountry germany = PlateCountry(
    code: 'de',
    captionLines: ['D'],
    panelColor: Color(0xFF003399),
    panelTextColor: Color(0xFFFFFFFF),
    flagAspectRatio: 5 / 3,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Germany.svg',
      package: 'plate_number',
    ),
  );
}

/// The German plate designs.
class GermanPlates {
  const GermanPlates._();

  /// A standard German car plate (e.g. "DA·X1953"): a district code of Latin
  /// letters, then the two round stickers (vehicle-inspection and federal-state
  /// seal), then the identifier's Latin letter and serial digits — read
  /// left-to-right, with no dividers and no printed labels. The stickers are
  /// [PlateDecal]s that sit in the gap between the two character groups.
  static const PlateSpec car = PlateSpec(
    id: 'de.car',
    country: GermanyCountry.germany,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the three touching edges — see IranPlates.car.
      box: PlateBox(0, 0, 56.4, 110),
    ),
    textDirection: TextDirection.ltr,
    slots: [
      // District code, e.g. "DA".
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(64, 17, 52, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(122, 17, 52, 76)),
      // Identifier: one letter then the serial digits, e.g. "X1953".
      PlateSlot(alphabet: PlateAlphabet.latinUppercase, box: PlateBox(230, 17, 52, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(288, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(338, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(388, 17, 46, 76)),
      PlateSlot(alphabet: PlateAlphabet.latinDigits, box: PlateBox(438, 17, 46, 76)),
    ],
    decals: [
      // Stacked in the gap between the district code and the identifier: the
      // orange TÜV inspection sticker on top, the federal-state seal below.
      PlateDecal(
        image: AssetImage('assets/de_inspection_sticker.png', package: 'plate_number'),
        box: PlateBox(184, 14, 38, 38),
      ),
      PlateDecal(
        image: AssetImage('assets/de_state_seal.png', package: 'plate_number'),
        box: PlateBox(184, 54, 38, 38),
      ),
    ],
    textGroups: [
      PlateTextGroup([0, 1], key: 'district'),
      PlateTextGroup([2], key: 'letters'),
      PlateTextGroup([3, 4, 5, 6], key: 'serial'),
    ],
  );
}
