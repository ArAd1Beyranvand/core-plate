import 'package:core_plate/core_plate.dart';

/// Judges an ordinary registration on `TunisiaPlates.standard` or `square`.
/// Reports, never bars a keystroke.
///
/// Checks what the article states: a series of up to three digits with no
/// leading zero (series 258–261 were issued in 2026; older ones stay on the
/// road), then a four-digit registration within it, 0001–9999.
class TunisiaValidator extends GatedPlateValidator {
  const TunisiaValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonSeries = 'The series is 1 to 999.';
  static const String reasonNumber = 'The registration is four digits.';
  static const String reasonZero = 'The registration is 0001 to 9999.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    series: entry.group('series'),
    number: entry.group('number'),
  );

  static PlateValidation validateFields({
    required String series,
    required String number,
  }) {
    if (series.isEmpty ||
        series.length > 3 ||
        !isDigits(series) ||
        series.startsWith('0')) {
      return const PlateValidation.invalid(reasonSeries);
    }
    if (!isDigitsOfLength(number, 4)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    if (number == '0000') {
      return const PlateValidation.invalid(reasonZero);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a `TunisiaPlates.government` value: a two-digit ministry code
/// (03 Justice, 15 Transport, per the article) and the vehicle's number.
class TunisiaGovernmentValidator extends GatedPlateValidator {
  const TunisiaGovernmentValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonMinistry = 'The ministry code is two digits.';
  static const String reasonNumber = 'The vehicle number is digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!isDigitsOfLength(entry.group('ministry'), 2)) {
      return const PlateValidation.invalid(reasonMinistry);
    }
    if (!isDigits(entry.group('number'))) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a `TunisiaPlates.diplomatic` value: two two-digit numbers. An
/// ambassador's `CMD` plate always ends `01`; pass [chief] for that spec.
class TunisiaDiplomaticValidator extends GatedPlateValidator {
  const TunisiaDiplomaticValidator({this.chief = false});

  final bool chief;

  @override
  String get gateGroup => 'serial';

  static const String reasonDigits = 'Both numbers are two digits.';
  static const String reasonChief = "A head of mission's plate ends 01.";

  @override
  PlateValidation judge(PlateEntry entry) {
    final String serial = entry.group('serial');
    if (!isDigitsOfLength(entry.group('country'), 2) ||
        !isDigitsOfLength(serial, 2)) {
      return const PlateValidation.invalid(reasonDigits);
    }
    if (chief && serial != '01') {
      return const PlateValidation.invalid(reasonChief);
    }
    return const PlateValidation.valid();
  }
}

/// Judges the five-digit serial of a `TunisiaPlates.military` or `temporary`
/// plate.
class TunisiaSerialValidator extends GatedPlateValidator {
  const TunisiaSerialValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonSerial = 'The serial is five digits.';

  @override
  PlateValidation judge(PlateEntry entry) =>
      isDigitsOfLength(entry.group('serial'), 5)
      ? const PlateValidation.valid()
      : const PlateValidation.invalid(reasonSerial);
}
