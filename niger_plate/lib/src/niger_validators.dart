import 'package:plate_core/core_plate.dart';

import 'niger_alphabets.dart';

/// Judges a `NigerPlates` value. Reports, never bars a keystroke.
///
/// What the article fixes: a region digit 1–8, one series letter, and a
/// four-digit serial.
class NigerValidator extends GatedPlateValidator {
  const NigerValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonRegion = 'The region is a digit from 1 to 8.';
  static const String reasonSeries = 'The series is one letter.';
  static const String reasonSerial = 'The serial is four digits.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    region: entry.group('region'),
    series: entry.group('series'),
    serial: entry.group('serial'),
  );

  static PlateValidation validateFields({
    required String region,
    required String series,
    required String serial,
  }) {
    if (!NigerAlphabets.region.characters.contains(region)) {
      return const PlateValidation.invalid(reasonRegion);
    }
    if (!NigerAlphabets.series.characters.contains(series)) {
      return const PlateValidation.invalid(reasonSeries);
    }
    if (!isDigitsOfLength(serial, 4)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    return const PlateValidation.valid();
  }
}

/// `12345ARN6`: five digits, the fixed `ARN`, and a region digit.
class NigerStateValidator extends GatedPlateValidator {
  const NigerStateValidator();

  @override
  String get gateGroup => 'serial';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!isDigitsOfLength(entry.group('serial'), 5)) {
      return const PlateValidation.invalid('The serial is five digits.');
    }
    if (!NigerAlphabets.region.characters.contains(entry.group('area'))) {
      return const PlateValidation.invalid(NigerValidator.reasonRegion);
    }
    return const PlateValidation.valid();
  }
}

/// Five digits.
class NigerMilitaryValidator extends GatedPlateValidator {
  const NigerMilitaryValidator();

  @override
  String get gateGroup => 'serial';

  @override
  PlateValidation judge(PlateEntry entry) =>
      isDigitsOfLength(entry.group('serial'), 5)
      ? const PlateValidation.valid()
      : const PlateValidation.invalid('The serial is five digits.');
}

/// `123CMD RN` and `123CD4 RN`: a three-digit country code, and for staff a
/// further digit the article calls the room.
class NigerDiplomaticValidator extends GatedPlateValidator {
  const NigerDiplomaticValidator();

  @override
  String get gateGroup => 'code';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!isDigitsOfLength(entry.group('code'), 3)) {
      return const PlateValidation.invalid('The country code is three digits.');
    }
    final String room = entry.group('room');
    if (room.isNotEmpty && !isDigitsOfLength(room, 1)) {
      return const PlateValidation.invalid('The room is one digit.');
    }
    return const PlateValidation.valid();
  }
}
