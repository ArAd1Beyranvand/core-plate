import 'package:core_plate/core_plate.dart';

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
