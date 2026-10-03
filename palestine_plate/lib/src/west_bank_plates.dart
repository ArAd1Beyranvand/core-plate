import 'package:flutter/widgets.dart';
import 'package:core_plate/core_plate.dart';

import 'palestine_alphabets.dart';
import 'palestine_country.dart';
import 'palestine_usage.dart';

/// West Bank plate designs: modernCar (D·DDDD·L, since 2018) and legacyCar
/// (D·DDDD·DD, 1994–2018). Geometry measured from reference_plate.png;
/// every other form factor provisional. Host supplies theme and country via
/// `PSThemes.forUsage()` and `legacyCountryForUsage()`. Motorcycles are form
/// factors, not usage classes; identity block placed as labels/rules, not country panel.
abstract final class PSWestBankPlates {
  // -------------------------------------------------------------------------
  // Shared 520 x 110 furniture. Const lists, so the colour-scheme variants
  // below are ten lines each instead of a copy of the whole plate.
  // -------------------------------------------------------------------------

  static const List<PlateRule> _carRules = [
    PlateRule(box: PlateBox(441, 8, 5, 94)), // Vertical rule; x from reference
    PlateRule(box: PlateBox(452, 51, 46, 5)), // Horizontal rule between ف and P
  ];

  /// Identity block: no flag (flagScale: 0), two caption lines fill 94 units.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(452, 8, 46, 94), // CALIBRATE — x measured, y proportional.
    flagScale: 0,
    captionScale: 1.9,
    padding: EdgeInsets.symmetric(vertical: 5),
  );

  // -------------------------------------------------------------------------
  // Modern: D · DDDD · L
  // -------------------------------------------------------------------------

  static final List<PlateSlot> _modernCarSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(19.5, 9, 55, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 109.5,
      top: 9,
      width: 55,
      height: 92,
      pitch: 59,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.governorateLetters,
      box: PlateBox(375.5, 9, 55, 92),
    ),
  ];

  static const List<PlateLabel> _modernCarLabels = [
    PlateLabel(
      text: '-',
      box: PlateBox(71.4, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
    PlateLabel(
      text: '-',
      box: PlateBox(344.4, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
  ];

  static const List<PlateTextGroup> _modernGroups = [
    PlateTextGroup([0], key: 'region'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5], key: 'governorate'),
  ];

  /// Standard West Bank car plate (issued since July 2018).
  static final PlateSpec modernCar = PlateSpec(
    id: 'ps.wb.modern.car',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027, // Measured from reference image
    slots: _modernCarSlots,
    rules: _carRules,
    labels: _modernCarLabels,
    textGroups: _modernGroups,
  );

  // -------------------------------------------------------------------------
  // Legacy: D · DDDD · DD
  // -------------------------------------------------------------------------

  // CALIBRATE — derived, not measured; no seven-glyph reference.
  static final List<PlateSlot> _legacyCarSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.districtDigits,
      box: PlateBox(20, 9, 47, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 95,
      top: 9,
      width: 47,
      height: 92,
      pitch: 51,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(323, 9, 47, 92),
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(374, 9, 47, 92),
    ),
  ];

  static const List<PlateLabel> _legacyCarLabels = [
    PlateLabel(
      text: '-',
      box: PlateBox(64.9, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
    PlateLabel(
      text: '-',
      box: PlateBox(292.9, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
  ];

  static const List<PlateTextGroup> _legacyGroups = [
    PlateTextGroup([0], key: 'district'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5, 6], key: 'usage'),
  ];

  /// Pre-2018 West Bank car plate. Recolour by calling [legacyCountryForUsage].
  static final PlateSpec legacyCar = PlateSpec(
    id: 'ps.wb.legacy.car',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: _legacyCarSlots,
    rules: _carRules,
    labels: _legacyCarLabels,
    textGroups: _legacyGroups,
  );

  /// Identity block for legacy plate of given usage.
  static PlateCountry legacyCountryForUsage(PSUsage usage) => switch (usage) {
    PSUsage.publicTransport ||
    PSUsage.tradePlate => PSCountries.westBankWhiteInk,
    PSUsage.government || PSUsage.exempt => PSCountries.westBankRedInk,
    _ => PSCountries.westBankGreenInk,
  };

  // CALIBRATE — two-line layout provisional; no reference image.
  static const List<PlateRule> _twoLineRules = [
    PlateRule(box: PlateBox(232, 10, 5, 130)),
    PlateRule(box: PlateBox(243, 71, 50, 5)),
  ];

  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(243, 10, 50, 130),
    flagScale: 0,
    captionScale: 2.6, // Two lines fill 130-tall block
    padding: EdgeInsets.symmetric(vertical: 5),
  );

  static const List<PlateLabel> _twoLineLabels = [
    PlateLabel(text: '-', box: PlateBox(50, 30, 21, 24), glyphHeight: 33),
  ];

  /// Modern car wrapped onto two lines.
  static final PlateSpec modernCarTwoLine = PlateSpec(
    id: 'ps.wb.modern.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(16.5, 12, 34, 60),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 70.5,
        top: 12,
        width: 34,
        height: 60,
        pitch: 37,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(99, 80, 34, 60),
      ), // Line 2
    ],
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _modernGroups,
  );

  /// Legacy car wrapped onto two lines.
  static final PlateSpec legacyCarTwoLine = PlateSpec(
    id: 'ps.wb.legacy.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.districtDigits,
        box: PlateBox(16.5, 12, 34, 60),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 70.5,
        top: 12,
        width: 34,
        height: 60,
        pitch: 37,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(80.5, 80, 34, 60),
      ), // Line 2
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(117.5, 80, 34, 60),
      ),
    ],
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _legacyGroups,
  );

  /// One-line motorcycle plate (measured against separate reference image).
  /// Identity block drawn as labels/rule, not country panel, to place divider precisely.
  static final PlateSpec modernMoto = PlateSpec(
    id: 'ps.wb.modern.moto',
    country: PSCountries.westBankGreenInkBlank,
    canvasWidth: 250,
    canvasHeight: 123,
    panel: PlatePanel(
      box: PlateBox(0, 0, 0, 0),
      flagScale: 0,
      captionScale: 0,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.0325, // 4 units on 123-tall plate
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(12.5, 47, 30, 62),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 60,
        top: 47,
        width: 30,
        height: 62,
        pitch: 32,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(205, 47, 30, 62),
      ),
    ],
    rules: const [
      PlateRule(
        box: PlateBox(121, 11, 3, 28),
      ), // Vertical divider between P and ف
    ],
    labels: [
      PlateLabel(text: 'P', box: PlateBox(95.5, 10, 24, 28), glyphHeight: 28),
      PlateLabel(text: 'ف', box: PlateBox(127.5, 10, 28, 28), glyphHeight: 28),
      PlateLabel(
        text: '-',
        box: PlateBox(40.15, 65.6, 21.7, 24.8),
        glyphHeight: 34.1,
      ),
      PlateLabel(
        text: '-',
        box: PlateBox(184.65, 65.6, 21.7, 24.8),
        glyphHeight: 34.1,
      ),
    ],
    textGroups: _modernGroups,
  );

  /// Two-line motorcycle plate (165 x 165). Identity block spans bottom as band.
  // CALIBRATE — provisional; no reference image.
  static final PlateSpec modernMotoTwoLine = PlateSpec(
    id: 'ps.wb.modern.moto2l',
    country: PSCountries.westBankGreenInkInline,
    canvasWidth: 165,
    canvasHeight: 165,
    panel: PlatePanel(
      box: PlateBox(45, 118, 75, 38),
      flagScale: 0,
      captionScale: 1.5,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(12.5, 14, 24, 46),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 50.5,
        top: 14,
        width: 24,
        height: 46,
        pitch: 26,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(70.5, 64, 24, 46),
      ),
    ],
    rules: const [
      PlateRule(
        box: PlateBox(12, 113, 141, 3),
      ), // Horizontal rule above identity band
    ],
    labels: [
      PlateLabel(
        text: '-',
        box: PlateBox(35.45, 27.8, 16.1, 18.4),
        glyphHeight: 25.3,
      ),
    ],
    textGroups: _modernGroups,
  );

  /// Trade / test plate: blue field, white text, header row with `اختبار` (left)
  /// and `במבחן` (right). Header must be two labels to preserve bidi directionality.
  // CALIBRATE — provisional; no reference image.
  static final PlateSpec modernTrade = PlateSpec(
    id: 'ps.wb.modern.trade',
    country: PSCountries.westBankWhiteInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(43, 38, 48, 64),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 120,
        top: 38,
        width: 48,
        height: 64,
        pitch: 51,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(350, 38, 48, 64),
      ),
    ],
    rules: _carRules,
    labels: const [
      PlateLabel(
        text: 'اختبار',
        box: PlateBox(20, 8, 200, 26),
        glyphHeight: 26,
      ), // Arabic "test"
      PlateLabel(
        text: 'במבחן',
        box: PlateBox(230, 8, 200, 26),
        glyphHeight: 26,
      ), // Hebrew "under test"
      PlateLabel(
        text: '-',
        box: PlateBox(94.3, 57.2, 22.4, 25.6),
        glyphHeight: 35.2,
      ),
      PlateLabel(
        text: '-',
        box: PlateBox(324.3, 57.2, 22.4, 25.6),
        glyphHeight: 35.2,
      ),
    ],
    textGroups: _modernGroups,
  );

  static final List<PlateSpec> all = [
    modernCar,
    legacyCar,
    modernCarTwoLine,
    legacyCarTwoLine,
    modernMoto,
    modernMotoTwoLine,
    modernTrade,
  ];
}
