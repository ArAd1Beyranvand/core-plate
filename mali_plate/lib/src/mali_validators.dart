import 'package:plate_core/core_plate.dart';

/// Advisory validator for Mali plates. Mali plates follow the simple
/// format: 2 letters, 4 digits, 2 letters (XX #### XX).
class MaliValidator extends GatedPlateValidator {
  const MaliValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonFormat =
      'Format is 2 letters, 4 digits, 2 letters.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final serial = entry.group('serial');

    // Check serial length is 8
    if (serial.length != 8) {
      return const PlateValidation.invalid(reasonFormat);
    }

    return const PlateValidation.valid();
  }
}
