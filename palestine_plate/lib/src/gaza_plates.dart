import 'package:flutter/widgets.dart';
import 'package:core_plate/core_plate.dart';

import 'palestine_alphabets.dart';
import 'palestine_country.dart';

/// The Gaza plate designs.
///
/// Gaza broke away from the Palestinian Authority's numbering in 2012 and has
/// run its own design since. One grammar, `3 · DDDD · DD`:
///
/// - group 1 is **always the literal digit `3`** — not a variable region code.
///   It is inherited from the pre-2012 PA scheme, where `3` meant "Gaza Strip,
///   registered after 1995", and was deliberately kept when Gaza's numbering
///   went independent. [PSAlphabets.gazaPrefix] is a one-character alphabet, so
///   no other digit can land in that slot.
/// - group 2 is any four digits: the serial.
/// - group 3 is two digits: the usage class, which drives **glyph colour
///   only** — see `PSGazaUsage` and `PSThemes.forGazaUsageCode`.
///
/// There is **no `ف / P` block** — a Palestinian flag takes that space instead
/// — and **the field is always white**. Unlike the West Bank's public-transport
/// plate, a Gaza plate never inverts.
///
/// One graphic treatment for the car plate:
///
/// - [car2012] (2012–2021): the flag rotated a quarter turn, filling a tall
///   strip on the right, full plate height. Plain field, no watermark. **This
///   is the only one-line car design this package offers** — the 2021 revision
///   (flag the right way up, plus a watermark decal) is not, so a car plate
///   never carries a horizontal flag.
///
/// The two-line car layout ([car2012TwoLine], [car2021TwoLine]) is the
/// exception: a landscape band across the top cannot hold a vertical strip, so
/// both wrap to the horizontal flag regardless of era — see that section's doc.
///
/// [moto] is a horizontal-flag design of its own, not a rescaled car plate: it
/// is the one-line motorcycle format, watermark included, sized for a
/// motorcycle's smaller plate.
///
/// Every dimension in this file is provisional (`// CALIBRATE`): no reference
/// photograph of a Gaza plate is in this repo, unlike the West Bank template,
/// which has `palestine_plate/pics/reference_plate.png` behind it. The 520 x
/// 110 canvas, the border ratio and the seven-cell pitch are carried over from
/// the West Bank specs for visual consistency between the two designs, not
/// because a Gaza plate is attested to share them.
abstract final class PSGazaPlates {
  static const List<PlateTextGroup> _groups = [
    PlateTextGroup([0], key: 'prefix'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5, 6], key: 'usage'),
  ];

  // -------------------------------------------------------------------------
  // car2012 — vertical flag, full height, ~55 units wide.
  // -------------------------------------------------------------------------

  /// Same seven-cell x/y positions as `PSWestBankPlates.legacyCar` — see that
  /// file for how they were derived — reused here (duplicated rather than
  /// shared, since privacy in Dart is per-file: there is no `_legacyCarSlots`
  /// to import) so the two designs read at the same scale side by side.
  static const List<PlateSlot> _sevenCellSlots = [
    PlateSlot(alphabet: PSAlphabets.gazaPrefix, box: PlateBox(20, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(95, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(146, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(197, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(248, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(323, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(374, 9, 47, 92)),
  ];

  static const List<PlateLabel> _sevenCellLabels = [
    PlateLabel(text: '·', box: PlateBox(64.9, 36.6, 32.2, 36.8), glyphHeight: 50.6),
    PlateLabel(text: '·', box: PlateBox(292.9, 36.6, 32.2, 36.8), glyphHeight: 50.6),
  ];

  /// No vertical divider — the flag is positioned directly on the right.
  static const List<PlateRule> _car2012Rules = [];

  /// 2012–2021: the flag rotated so its triangle points down, filling a
  /// full-height strip on the right.
  ///
  /// `flagScale: 1` with zero padding on a box whose aspect ratio (55/110 =
  /// 1/2) already equals [PSCountries.gaza2012]'s `flagAspectRatio` — so
  /// `CountryPanel`'s own width-then-height-clamped sizing lands on exactly
  /// this box with no slack and no letterboxing. Get the two out of sync and
  /// the flag stops filling the strip.
  static const PlateSpec car2012 = PlateSpec(
    id: 'ps.gz.2012.car',
    country: PSCountries.gaza2012,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      box: PlateBox(455, 0, 55, 110),
      flagScale: 1,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: _sevenCellSlots,
    rules: _car2012Rules,
    labels: _sevenCellLabels,
    textGroups: _groups,
  );

  /// The watermark behind the digits: "فلسطين" over "Palestine", pre-faded to
  /// ~12% grey in the shipped PNG.
  ///
  /// **Not an [SvgPlateAsset].** [PlateDecal.image] wants an [ImageProvider],
  /// and `flutter_svg`'s vector picture is not one — `core_plate` renders an
  /// `SvgPlateAsset` only through [PlateFlag]. So the watermark ships as a
  /// raster (`assets/marks/palestine_watermark.png`) via [AssetImage] instead
  /// of the vector this layout would otherwise call for. Closing that gap —
  /// letting [PlateDecal] take a [PlateAsset] — is a `core_plate` change, not
  /// this package's to make.
  ///
  /// **Baked-in opacity for the same reason.** [PlateDecal] paints at full
  /// opacity; there is no fade parameter anywhere on that path. So the fade is
  /// in the pixels — see `assets/marks/PROVENANCE.md`.
  ///
  /// **Draws under the digits.** Verified against
  /// `core_plate/lib/src/widgets/plate_canvas.dart`: `spec.decals` is painted
  /// into the `Stack` before `spec.slots`, so a decal is always beneath slot
  /// content. Nothing here relies on that by accident.
  static const PlateDecal _watermark = PlateDecal(
    image: AssetImage(
      'assets/marks/palestine_watermark.png',
      package: 'palestine_plate',
    ),
    box: PlateBox(10, 9, 380, 92),
  );

  // -------------------------------------------------------------------------
  // Motorcycle — one-line, horizontal flag, plus a watermark behind the
  // digits. The only Gaza design that carries a horizontal flag on a one-line
  // plate: see the class doc for why cars do not.
  // -------------------------------------------------------------------------

  /// Tighter pitch than [_sevenCellSlots]: the horizontal flag panel is wide
  /// rather than tall, so the digit field has less width to work with. Cell 48
  /// wide, pitch 52, inter-group gap 12.
  // CALIBRATE — sized off the same proportions as the car layout; no
  // reference photograph of a Gaza motorcycle plate exists.
  static const List<PlateSlot> _motoSlots = [
    PlateSlot(alphabet: PSAlphabets.gazaPrefix, box: PlateBox(14, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(74, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(126, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(178, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(230, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(290, 9, 48, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(342, 9, 48, 92)),
  ];

  static const List<PlateLabel> _motoLabels = [
    PlateLabel(text: '·', box: PlateBox(56, 36.6, 18, 36.8), glyphHeight: 50.6),
    PlateLabel(text: '·', box: PlateBox(272, 36.6, 18, 36.8), glyphHeight: 50.6),
  ];

  static const List<PlateRule> _motoRules = [];

  /// The one-line motorcycle plate: [gaza2021]'s flag the right way up, plus
  /// the watermark decal, on the same 520 x 110 canvas the car plate uses.
  ///
  /// The panel box (110 x 55, aspect 2/1) is sized the same way [car2021] used
  /// to be: it equals [PSCountries.gaza2021]'s `flagAspectRatio` exactly, so
  /// `flagScale: 1` with zero padding fills it precisely, vertically centred
  /// on the plate (`top: (110 - 55) / 2`).
  static const PlateSpec moto = PlateSpec(
    id: 'ps.gz.moto',
    country: PSCountries.gaza2021,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      box: PlateBox(400, 27.5, 110, 55),
      flagScale: 1,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: _motoSlots,
    rules: _motoRules,
    labels: _motoLabels,
    decals: [_watermark],
    textGroups: _groups,
  );

  // -------------------------------------------------------------------------
  // Two-line 300 x 150. The flag becomes a full-width band across the top —
  // both variants use the horizontal asset here, even [car2012TwoLine]: a
  // vertical strip does not fit a landscape band, so wrapping the serial
  // forces the flag's orientation to follow it.
  // -------------------------------------------------------------------------

  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(4, 4, 292, 40),
    flagScale: 1,
    padding: EdgeInsets.zero,
  );

  static const List<PlateRule> _twoLineRules = [];

  /// Line 1 (prefix + 4-digit serial) and line 2 (2-digit usage), at the same
  /// x positions `PSWestBankPlates.legacyCarTwoLine` uses for its own two
  /// rows — duplicated for the reason [_sevenCellSlots] gives.
  static const List<PlateSlot> _twoLineSlots = [
    PlateSlot(alphabet: PSAlphabets.gazaPrefix, box: PlateBox(16.5, 53, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(70.5, 53, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(107.5, 53, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(144.5, 53, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(181.5, 53, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(80.5, 101, 34, 42)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(117.5, 101, 34, 42)),
  ];

  /// Dot geometry follows the same proportion rule as every other label in
  /// this package: box top at 30% into the row, box height 40% of it, glyph
  /// 55% of it.
  static const List<PlateLabel> _twoLineLabels = [
    PlateLabel(text: '·', box: PlateBox(49.5, 65.6, 21, 16.8), glyphHeight: 23.1),
  ];

  /// [car2012]'s grammar, wrapped onto two lines for a bumper too short for
  /// the one-line plate. See the class doc for why the flag is horizontal here
  /// despite [car2012] itself being vertical.
  static const PlateSpec car2012TwoLine = PlateSpec(
    id: 'ps.gz.2012.car2l',
    country: PSCountries.gaza2021,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: _twoLineSlots,
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _groups,
  );

  /// [car2012]'s grammar, wrapped the same way as [car2012TwoLine], plus the
  /// watermark — the two-line era split, kept even though the one-line
  /// [moto] design is now the only other place the watermark and horizontal
  /// flag appear together.
  static const PlateSpec car2021TwoLine = PlateSpec(
    id: 'ps.gz.2021.car2l',
    country: PSCountries.gaza2021,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: _twoLineSlots,
    rules: _twoLineRules,
    labels: _twoLineLabels,
    decals: [
      PlateDecal(
        image: AssetImage(
          'assets/marks/palestine_watermark.png',
          package: 'palestine_plate',
        ),
        box: PlateBox(10, 50, 282, 96),
      ),
    ],
    textGroups: _groups,
  );

  /// Every spec this class declares, in declaration order.
  static const List<PlateSpec> all = [
    car2012,
    car2012TwoLine,
    car2021TwoLine,
    moto,
  ];
}
