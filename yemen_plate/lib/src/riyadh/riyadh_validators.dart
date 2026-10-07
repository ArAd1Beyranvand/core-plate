import 'package:plate_core/plate_core.dart';

/// Judges a Riyadh plate: three letters from the seventeen the article lists and
/// one to four digits. Reports, never bars a keystroke.
///
/// Not checked: the combinations banned since 2009 (`SEX`, `ASS`, ...), since
/// the article gives only examples, not the list.
class RiyadhValidator extends GatedPlateValidator {
  const RiyadhValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonLetters = 'The register is three letters.';
  static const String reasonSerial = 'The number is one to four digits.';

  static final RegExp _letters = RegExp(r'^[ABJDRSXTEGKLZNHUV]{3}$');

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!_letters.hasMatch(entry.group('letters'))) {
      return const PlateValidation.invalid(reasonLetters);
    }
    final String serial = entry.group('serial');
    if (!isDigits(serial) || serial.length > 4) {
      return const PlateValidation.invalid(reasonSerial);
    }
    return const PlateValidation.valid();
  }
}
