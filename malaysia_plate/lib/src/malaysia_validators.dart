import 'package:core_plate/core_plate.dart';

/// Judges a Malaysian registration on a `MalaysiaPlates.singleRow`, `twoRow`
/// or `ev` spec. Reports, never bars a keystroke.
///
/// Checks the series rules the article states: I and O are never issued; the
/// number runs 1–9999 with no leading zero; a Sabah (`S…`) suffix is never Q
/// or S. Z, the military prefix, is accepted — it is a real plate on the
/// standard theme. Does not check which state letters exist, nor vanity
/// series, which break every rule here.
class MalaysiaValidator extends GatedPlateValidator {
  const MalaysiaValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonPrefixMissing = 'A plate starts with letters.';
  static const String reasonNoIO =
      'I and O are not issued on Malaysian plates.';
  static const String reasonNumber = 'The number is 1 to 9999.';
  static const String reasonLeadingZero = 'The number has no leading zero.';
  static const String reasonSabahSuffix = 'A Sabah suffix is never Q or S.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    prefix: entry.group('prefix'),
    number: entry.group('number'),
    suffix: entry.group('suffix'),
  );

  static PlateValidation validateFields({
    required String prefix,
    required String number,
    String suffix = '',
  }) {
    if (prefix.isEmpty) {
      return const PlateValidation.invalid(reasonPrefixMissing);
    }
    if (RegExp('[IO]').hasMatch(prefix + suffix)) {
      return const PlateValidation.invalid(reasonNoIO);
    }
    if (number.isEmpty || number.length > 4 || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    if (number.startsWith('0')) {
      return const PlateValidation.invalid(reasonLeadingZero);
    }
    if (prefix.startsWith('S') && (suffix == 'Q' || suffix == 'S')) {
      return const PlateValidation.invalid(reasonSabahSuffix);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a `MalaysiaPlates.diplomatic` value: two two-digit numbers and a
/// mission code. The article documents no number ranges.
class MalaysiaDiplomaticValidator extends GatedPlateValidator {
  const MalaysiaDiplomaticValidator();

  @override
  String get gateGroup => 'mission';

  static const String reasonDigits = 'Both numbers are two digits.';
  static const String reasonMission = 'The code is DC, CC, UN or PA.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String country = entry.group('country');
    final String serial = entry.group('serial');
    if (country.length != 2 || serial.length != 2) {
      return const PlateValidation.invalid(reasonDigits);
    }
    if (!isDigits(country) || !isDigits(serial)) {
      return const PlateValidation.invalid(reasonDigits);
    }
    if (!const <String>[
      'DC',
      'CC',
      'UN',
      'PA',
    ].contains(entry.group('mission'))) {
      return const PlateValidation.invalid(reasonMission);
    }
    return const PlateValidation.valid();
  }
}
