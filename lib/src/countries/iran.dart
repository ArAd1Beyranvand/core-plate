import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_asset.dart';
import '../model/plate_box.dart';
import '../model/plate_country.dart';
import '../model/plate_spec.dart';

/// Iran's plate chrome. Becomes the `iran_plate` package in the split — this
/// file is a straight directory move, so it carries no reference to
/// `countries/germany.dart`.
class IranCountry {
  const IranCountry._();

  /// The Islamic Republic of Iran, as it appears on a standard plate: a blue
  /// panel with white "I.R." / "IRAN" text beside the flag.
  static const PlateCountry iran = PlateCountry(
    code: 'ir',
    captionLines: ['I.R.', 'IRAN'],
    panelColor: Color(0xFF16479D),
    panelTextColor: Color(0xFFFFFFFF),
    flagAspectRatio: 7 / 4,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Iran.svg',
      package: 'plate_number',
    ),
  );
}

/// The Persian alphabets a plate slot can be drawn over.
class PersianAlphabets {
  const PersianAlphabets._();

  static const PlateAlphabet digits = PlateAlphabet(
    id: 'fa.digits',
    characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: {
      '0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴',
      '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹',
    },
  );

  static const PlateAlphabet plateLetters = PlateAlphabet(
    id: 'fa.plateLetters',
    characters: [
      'ب', 'ح', 'د', 'س', 'ص', 'ط', 'ق', 'ل',
      'م', 'ن', 'و', 'ه', 'ی', 'ت', 'ژ', 'گ',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );
}

/// The Iranian plate designs.
class IranPlates {
  const IranPlates._();

  static const PlateSpec car = PlateSpec(
    id: 'ir.car',
    country: IranCountry.iran,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the three touching edges (left/top/bottom)
      // instead of sitting flush at the border thickness (0.04 * canvasHeight =
      // 4.4). The panel is clipped back to the rounded plate face by
      // _PlateFaceClipper, so extending it under the frame just makes the blue
      // paint right up to the clip boundary — killing the thin white seam that
      // a flush edge leaves when the FittedBox scale lands the panel edge and
      // the border edge on different physical pixels. Right edge (56.4) stays
      // interior and is unchanged.
      box: PlateBox(0, 0, 56.4, 110),
    ),
    textDirection: TextDirection.rtl,
    slots: [
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(65, 17, 47, 76)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(120, 17, 47, 76)),
      PlateSlot(alphabet: PersianAlphabets.plateLetters, box: PlateBox(175, 17, 55, 76)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(238, 17, 47, 76)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(293, 17, 47, 76)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(348, 17, 47, 76)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(428, 40, 32, 52)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(466, 40, 32, 52)),
    ],
    rules: [
      // The province divider runs the full height of the plate face (top edge
      // to bottom edge), meeting the border at both ends — no empty gaps.
      PlateRule(box: PlateBox(404, 4.4, 5, 101.2)),
    ],
    labels: [
      PlateLabel(text: 'ایران', box: PlateBox(412, 18, 103, 16), glyphHeight: 16),
    ],
    textGroups: [
      PlateTextGroup([0, 1]),
      PlateTextGroup([2]),
      PlateTextGroup([3, 4, 5]),
      PlateTextGroup([6, 7], prefix: 'IR '),
    ],
  );

  static const PlateSpec bicycle = PlateSpec(
    id: 'ir.bicycle',
    country: IranCountry.iran,
    canvasWidth: 175,
    canvasHeight: 110,
    panel: PlatePanel(
      // Overlap the border on the two touching edges (left/top) instead of
      // sitting flush at the border thickness (0.05 * canvasHeight = 5.5); the
      // panel is clipped back to the plate face, so this kills the thin white
      // seam a flush edge leaves. See car. Right (63.7) and bottom (53.7)
      // edges are interior and unchanged.
      //
      // Panel width is sized to wrap the flag (the widest element) plus the
      // left/right margins below, instead of a slack fraction: flagScale is 1.0
      // so the flag fills its box exactly and panelWidth = padding + flag
      // width.
      box: PlateBox(0, 0, 47, 53.7),
      flagScale: 1.0,
      captionScale: 0.25,
      // Bigger left margin than top/bottom: matches a real bicycle plate's
      // panel, where the flag+caption block sits clear of the frame on the
      // left but only needs breathing room, not a deep inset, top and bottom.
      // Extra margin all around keeps the smaller flag/caption clear of the
      // panel edges instead of crowding the blue block.
      padding: EdgeInsets.fromLTRB(15, 16, 6, 6),
    ),
    textDirection: TextDirection.rtl,
    borderWidthRatioOverride: 0.05,
    slots: [
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(74, 13, 22, 36)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(104, 13, 22, 36)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(134, 13, 22, 36)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(8, 58, 27, 44)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(41, 58, 27, 44)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(74, 58, 27, 44)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(107, 58, 27, 44)),
      PlateSlot(alphabet: PersianAlphabets.digits, box: PlateBox(140, 58, 27, 44)),
    ],
  );
}
