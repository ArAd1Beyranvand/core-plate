import 'package:plate_core/core_plate.dart';

import 'mali_alphabets.dart';
import 'mali_country.dart';

/// Where the ink sits on a Mali plate, in millimetres.
///
/// Mali's current series is a simple single-line format: 520×110 mm, rounded
/// corners, black on white, with the format AB 1234 MD (2 letters, 4 digits,
/// 2 letters). Measured off the Wikimedia reference image, normalised to
/// physical millimetres.
///
/// The single plate has:
/// * Rounded corner radius: ~15 mm (approximately 15% of height)
/// * Frame width: ~3 mm
/// * Serial ink positioned centred vertically and distributed horizontally
///   across the width with proportional spacing.
abstract final class _Layout {
  static const double width = 520;
  static const double height = 110;

  /// Vertical centre of the text area.
  static const double textCenter = 55;

  /// Glyph height — calculated from the 0.72 ratio: ink height is ~35 mm,
  /// so slot height should be about 49 mm.
  static const double glyphHeight = 50;

  /// Spacing: the reference shows evenly distributed spacing.
  /// Left letter pair positioned at ~45 mm from left edge.
  static const double leftLettersLeft = 45;

  /// Digits centred at ~260 mm (midpoint of the plate).
  static const double digitsLeft = 245;

  /// Right letters at ~430 mm from left edge.
  static const double rightLettersLeft = 430;

  /// Cell width for letters and digits.
  static const double cellWidth = 45;
}

/// Mali's current standard plate: black on white, format AB 1234 MD.
PlateSpec maliStandardPlate() {
  const double top = _Layout.textCenter - _Layout.glyphHeight / 2;

  return PlateSpec(
    id: 'ml.standard',
    country: MaliCountry.mali,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.height)),
    background: PlateSection.plain,
    slots: <PlateSlot>[
      // First letter
      PlateSlot(
        alphabet: MaliAlphabets.letters,
        box: PlateBox(
          _Layout.leftLettersLeft,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Second letter
      PlateSlot(
        alphabet: MaliAlphabets.letters,
        box: PlateBox(
          _Layout.leftLettersLeft + _Layout.cellWidth,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // First digit
      PlateSlot(
        alphabet: MaliAlphabets.digits,
        box: PlateBox(
          _Layout.digitsLeft,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Second digit
      PlateSlot(
        alphabet: MaliAlphabets.digits,
        box: PlateBox(
          _Layout.digitsLeft + _Layout.cellWidth,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Third digit
      PlateSlot(
        alphabet: MaliAlphabets.digits,
        box: PlateBox(
          _Layout.digitsLeft + 2 * _Layout.cellWidth,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Fourth digit
      PlateSlot(
        alphabet: MaliAlphabets.digits,
        box: PlateBox(
          _Layout.digitsLeft + 3 * _Layout.cellWidth,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Third letter
      PlateSlot(
        alphabet: MaliAlphabets.letters,
        box: PlateBox(
          _Layout.rightLettersLeft,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
      // Fourth letter
      PlateSlot(
        alphabet: MaliAlphabets.letters,
        box: PlateBox(
          _Layout.rightLettersLeft + _Layout.cellWidth,
          top,
          _Layout.cellWidth,
          _Layout.glyphHeight,
        ),
      ),
    ],
    textGroups: <PlateTextGroup>[
      PlateTextGroup(const <int>[0, 1], key: 'prefix'),
      PlateTextGroup(const <int>[2, 3, 4, 5], key: 'number'),
      PlateTextGroup(const <int>[6, 7], key: 'suffix'),
    ],
  );
}

/// All Mali plate specs, keyed by a simple name.
abstract final class MaliPlates {
  static final Map<String, PlateSpec Function()> all =
      <String, PlateSpec Function()>{
    'standard': maliStandardPlate,
  };
}
