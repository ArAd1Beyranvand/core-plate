import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'cuba_alphabets.dart';
import 'cuba_colors.dart';
import 'cuba_country.dart';
import 'cuba_themes.dart';

/// Where the ink sits on the 2013 plates, in millimetres.
///
/// The article gives 420×110 for cars and 200×140 for motorcycles; those are
/// the canvases. There is no clean artwork, so the car is measured off the
/// three frontal photographs (K 000 807, T 003 526, D 004 027), each plate
/// rectangle normalised to 420×110, and the motorcycle off P 28588, normalised
/// to 200×140. Figures are the mean across photographs.
abstract final class _Layout {
  // ── Car, 420 × 110 ──────────────────────────────────────────────────────
  static const double carWidth = 420;
  static const double carHeight = 110;

  /// The CUBA strip's inboard edge: the blue ends at 56.2 on K 000 807, the
  /// white strip's rule sits at 55.0 on D 004 027.
  static const double carStripEnd = 56;

  /// The rule on a white strip is one photograph pixel, ~0.4 mm.
  static const double carStripRule = 0.6;

  /// Serial ink is 77 mm tall (76.6 and 77.0) at y 20.5..97.5. Reaching it
  /// would need a ~140 mm slot on a 110 mm plate, so the slots take the full
  /// height and the ink lands at ~75% of reference. See README.
  static const double carSlotTop = 0;
  static const double carSlotHeight = carHeight;

  /// Cell stride: 46.5 and 47.1 within the two triples. Cells are flush.
  static const double carPitch = 46.8;

  /// Ink centres: letter 80; first digit of each triple 140 and 292.2 (the
  /// gap between triples is 21 mm of field against 9 within one).
  static const double carLetterLeft = 80 - carPitch / 2;
  static const double carHighLeft = 140 - carPitch / 2;
  static const double carLowLeft = 292.2 - carPitch / 2;

  /// CUBA: caps 12.8 tall (13.0, 12.4) at a 19.0 line pitch, the stack centred
  /// at (31, 55). glyphHeight = 12.8 / 0.525 (0.72 × DejaVu's cap height); the
  /// line height opens the 0.72 × 24 = 17.3 font size out to the 19 pitch.
  static const PlateBox carCaption = PlateBox(8, 10, 46, 90);
  static const double carCaptionGlyph = 24;
  static const double carCaptionLine = 1.1;

  // ── Motorcycle, 200 × 140 ───────────────────────────────────────────────
  static const double motoWidth = 200;
  static const double motoHeight = 140;

  /// The same ~3.3 mm frame as the car, on a taller plate.
  static const double motoBorderRatio = 3.3 / motoHeight;

  /// The CUBA box: a rule down from the top edge at x 42.1, meeting a rule in
  /// from the left edge at y 62.5. Both ~0.5 mm. Neither crosses the other.
  static const double motoBoxRight = 42.1;
  static const double motoBoxBottom = 62.5;
  static const double motoRule = 0.6;

  /// P is 49.8 tall at y 11.8..61.6, centred on x 100; the digits are 49.6 at
  /// y 77.1..126.7. ~95 mm slots would be needed for both rows, so each row
  /// gets half the plate and the ink lands at ~74%.
  static const double motoRowHeight = motoHeight / 2;

  /// Digit centres 29.2, 63.8, 99.1, 134.2, 169.7: a 35.1 stride.
  static const double motoPitch = 35.1;
  static const double motoLetterLeft = 100 - motoPitch / 2;
  static const double motoDigitsLeft = 29.2 - motoPitch / 2;

  /// CUBA: caps 7.0 at a 10.7 pitch, centred at (24.5, 35.1).
  static const PlateBox motoCaption = PlateBox(8, 8, 33, 54.2);
  static const double motoCaptionGlyph = 13.3;
  static const double motoCaptionLine = 1.11;
}

/// The 2013 plates: [car] (natural persons), [carLegalEntity] and
/// [motorcycle].
///
/// The two cars are one design. A legal entity's plate fills the CUBA strip
/// with the blue band and prints CUBA in white; a natural person's leaves it
/// white, rules it off and prints CUBA in the ink. Everything else — letter,
/// two digit triples, 420×110 — is shared, so both come from [_car].
///
/// The CUBA strip and the motorcycle's CUBA box are background sections, so
/// their rules run to the plate edge under the frame.
///
/// Not implemented: the 2002–2013 colour-coded series and everything before
/// it; the small laser-printed control number top right.
abstract final class CubaPlates {
  static const String _caption = 'C\nU\nB\nA';

  static final PlateSpec car = _car(
    id: 'cu.car',
    strip: const PlateSection.columns(<PlatePart>[
      PlatePart(
        PlateSection.plain,
        end: _Layout.carStripEnd,
        divider: _Layout.carStripRule,
      ),
      PlatePart(PlateSection.plain),
    ]),
    captionInk: null,
  );

  static final PlateSpec carLegalEntity = _car(
    id: 'cu.carLegalEntity',
    strip: const PlateSection.columns(<PlatePart>[
      PlatePart(PlateSection.fill(PlateFill.panel), end: _Layout.carStripEnd),
      PlatePart(PlateSection.plain),
    ]),
    captionInk: CubaColors.bandInk,
  );

  /// [strip] is the background; [captionInk] colours CUBA on it, null for the
  /// theme's ink.
  static PlateSpec _car({
    required String id,
    required PlateSection strip,
    required Color? captionInk,
  }) => PlateSpec(
    id: id,
    country: CubaCountry.cuba,
    canvasWidth: _Layout.carWidth,
    canvasHeight: _Layout.carHeight,
    noPanel: true,
    panel: const PlatePanel(
      box: PlateBox(0, 0, _Layout.carStripEnd, _Layout.carHeight),
    ),
    background: strip,
    labels: <PlateLabel>[
      PlateLabel(
        text: _caption,
        box: _Layout.carCaption,
        glyphHeight: _Layout.carCaptionGlyph,
        lineHeight: _Layout.carCaptionLine,
        color: captionInk,
      ),
    ],
    slots: <PlateSlot>[
      const PlateSlot(
        alphabet: CubaAlphabets.letters,
        box: PlateBox(
          _Layout.carLetterLeft,
          _Layout.carSlotTop,
          _Layout.carPitch,
          _Layout.carSlotHeight,
        ),
      ),
      for (final double left in const <double>[
        _Layout.carHighLeft,
        _Layout.carLowLeft,
      ])
        ...plateRegister(
          alphabet: CubaAlphabets.digits,
          count: 3,
          left: left,
          top: _Layout.carSlotTop,
          width: _Layout.carPitch,
          height: _Layout.carSlotHeight,
        ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0], key: 'letter'),
      PlateTextGroup(<int>[1, 2, 3], key: 'serial'),
      PlateTextGroup(<int>[4, 5, 6], key: 'serial2'),
    ],
  );

  /// The letter alone on the top row beside a ruled CUBA box, five digits
  /// across the bottom.
  static final PlateSpec motorcycle = PlateSpec(
    id: 'cu.motorcycle',
    country: CubaCountry.cuba,
    canvasWidth: _Layout.motoWidth,
    canvasHeight: _Layout.motoHeight,
    noPanel: true,
    panel: const PlatePanel(
      box: PlateBox(0, 0, _Layout.motoBoxRight, _Layout.motoBoxBottom),
    ),
    borderWidthRatioOverride: _Layout.motoBorderRatio,
    // The top row stops at the far edge of the bottom rule, so the vertical
    // rule runs down to meet it and no further; the bottom rule lives inside
    // the box's column, so it runs in from the left edge to meet the vertical.
    background: const PlateSection.rows(<PlatePart>[
      PlatePart(
        PlateSection.columns(<PlatePart>[
          PlatePart(
            PlateSection.rows(<PlatePart>[
              PlatePart(
                PlateSection.plain,
                end: _Layout.motoBoxBottom,
                divider: _Layout.motoRule,
              ),
              PlatePart(PlateSection.plain),
            ]),
            end: _Layout.motoBoxRight,
            divider: _Layout.motoRule,
          ),
          PlatePart(PlateSection.plain),
        ]),
        end: _Layout.motoBoxBottom + _Layout.motoRule / 2,
      ),
      PlatePart(PlateSection.plain),
    ]),
    labels: const <PlateLabel>[
      PlateLabel(
        text: _caption,
        box: _Layout.motoCaption,
        glyphHeight: _Layout.motoCaptionGlyph,
        lineHeight: _Layout.motoCaptionLine,
      ),
    ],
    slots: <PlateSlot>[
      const PlateSlot(
        alphabet: CubaAlphabets.letters,
        box: PlateBox(
          _Layout.motoLetterLeft,
          0,
          _Layout.motoPitch,
          _Layout.motoRowHeight,
        ),
      ),
      ...plateRegister(
        alphabet: CubaAlphabets.digits,
        count: 5,
        left: _Layout.motoDigitsLeft,
        top: _Layout.motoRowHeight,
        width: _Layout.motoPitch,
        height: _Layout.motoRowHeight,
      ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0], key: 'letter'),
      PlateTextGroup(<int>[1, 2, 3, 4, 5], key: 'serial'),
    ],
  );

  static List<PlateSpec> get all => <PlateSpec>[
    car,
    carLegalEntity,
    motorcycle,
  ];

  /// The theme every spec here is drawn in.
  static const PlateTheme theme = CubaThemes.standard;
}
