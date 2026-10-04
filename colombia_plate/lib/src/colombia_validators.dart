import 'package:plate_core/core_plate.dart';

import 'colombia_plates.dart';

/// Judges a `ColombiaPlates.standard` value. Reports, never bars a keystroke.
///
/// Checks what the article states for each series: how many letters and
/// digits, and the letters it always starts with (`O` official, `R`
/// trailer, `T` tank truck, `CC`, `OI`, `AT`).
class ColombiaValidator extends GatedPlateValidator {
  const ColombiaValidator([this.series = ColombiaSeries.private]);

  final ColombiaSeries series;

  @override
  String get gateGroup => series.digitsFirst ? 'letters' : 'number';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    series,
    letters: entry.group('letters'),
    number: entry.group('number'),
  );

  static PlateValidation validateFields(
    ColombiaSeries series, {
    required String letters,
    required String number,
  }) {
    if (!RegExp('^[A-Z]{${series.letters}}\$').hasMatch(letters)) {
      return PlateValidation.invalid(
        'The series is ${series.letters} letter${series.letters == 1 ? '' : 's'}.',
      );
    }
    if (!letters.startsWith(series.fixed)) {
      return PlateValidation.invalid(
        '${series.english} plates start with ${series.fixed}.',
      );
    }
    if (!isDigitsOfLength(number, series.digits)) {
      return PlateValidation.invalid('The number is ${series.digits} digits.');
    }
    return const PlateValidation.valid();
  }
}

/// Judges a `ColombiaPlates.police` value: two digits, then four.
class ColombiaPoliceValidator extends GatedPlateValidator {
  const ColombiaPoliceValidator();

  @override
  String get gateGroup => 'number';

  static const String reason = 'The number is two digits and four digits.';

  @override
  PlateValidation judge(PlateEntry entry) =>
      isDigitsOfLength(entry.group('unit'), 2) &&
          isDigitsOfLength(entry.group('number'), 4)
      ? const PlateValidation.valid()
      : const PlateValidation.invalid(reason);
}

/// Judges a `ColombiaPlates.diplomatic` value: a type letter, the mission's
/// two-letter country initials, three digits.
class ColombiaDiplomaticValidator extends GatedPlateValidator {
  const ColombiaDiplomaticValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonLetters = 'A type letter and two country initials.';
  static const String reasonNumber = 'The number is three digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!RegExp(r'^[A-Z]$').hasMatch(entry.group('type')) ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(entry.group('country'))) {
      return const PlateValidation.invalid(reasonLetters);
    }
    if (!isDigitsOfLength(entry.group('number'), 3)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}
