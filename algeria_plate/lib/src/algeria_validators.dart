import 'package:plate_core/plate_core.dart';

/// The vehicle classes the first digit of the `type` group names, by digit.
/// From the article's list (its source: the 2021 plate standard).
abstract final class AlgeriaVehicleClasses {
  static const Map<String, String> names = <String, String>{
    '1': 'Private vehicle',
    '2': 'Truck',
    '3': 'Commercial vehicle',
    '4': 'Bus',
    '5': 'Tractor unit',
    '6': 'Other tractor',
    '7': 'Special vehicle',
    '8': 'Trailer',
    '9': 'Motorcycle',
  };
}

/// The wilaya codes ending a civil plate. 01–48 are the original wilayas,
/// 49–58 issued since January 2022; 59–69, for the wilayas created in
/// November 2025, are issued from January 2027 and are accepted here.
abstract final class AlgeriaWilayas {
  static const Map<String, String> names = <String, String>{
    '01': 'Adrar', '02': 'Chlef', '03': 'Laghouat', '04': 'Oum El Bouaghi', //
    '05': 'Batna', '06': 'Béjaïa', '07': 'Biskra', '08': 'Béchar',
    '09': 'Blida', '10': 'Bouïra', '11': 'Tamanrasset', '12': 'Tébessa',
    '13': 'Tlemcen', '14': 'Tiaret', '15': 'Tizi Ouzou', '16': 'Algiers',
    '17': 'Djelfa', '18': 'Jijel', '19': 'Sétif', '20': 'Saïda',
    '21': 'Skikda', '22': 'Sidi Bel Abbès', '23': 'Annaba', '24': 'Guelma',
    '25': 'Constantine', '26': 'Médéa', '27': 'Mostaganem', '28': "M'Sila",
    '29': 'Mascara', '30': 'Ouargla', '31': 'Oran', '32': 'El Bayadh',
    '33': 'Illizi', '34': 'Bordj Bou Arréridj', '35': 'Boumerdès',
    '36': 'El Tarf', '37': 'Tindouf', '38': 'Tissemsilt', '39': 'El Oued',
    '40': 'Khenchela', '41': 'Souk Ahras', '42': 'Tipaza', '43': 'Mila',
    '44': 'Aïn Defla', '45': 'Naâma', '46': 'Aïn Témouchent',
    '47': 'Ghardaïa', '48': 'Relizane', '49': 'Timimoun',
    '50': 'Bordj Badji Mokhtar', '51': 'Ouled Djellal', '52': 'Béni Abbès',
    '53': 'In Salah', '54': 'In Guezzam', '55': 'Touggourt', '56': 'Djanet',
    '57': "El M'Ghair", '58': 'El Menia', '59': 'Aflou', '60': 'Barika',
    '61': 'El Kantara', '62': 'Bir El Ater', '63': 'El Aricha',
    '64': 'Ksar Chellala', '65': 'Aïn Oussera', '66': 'Messaad',
    '67': 'Ksar El Boukhari', '68': 'Bousaâda',
    '69': 'El Abiodh Sidi Cheikh',
  };
}

/// Judges a civil Algerian registration on `AlgeriaPlates.singleLine` or
/// `twoLine`. Reports, never bars a keystroke.
///
/// Checks: a five-digit serial (leading zeros are printed); a vehicle class
/// 1–9 followed by two year digits (any — `22` and `33` mean "unknown year");
/// a wilaya code in [AlgeriaWilayas.names]. Pre-1990s serials of up to three
/// digits are not modelled.
class AlgeriaValidator extends GatedPlateValidator {
  const AlgeriaValidator();

  @override
  String get gateGroup => 'wilaya';

  static const String reasonSerial = 'The serial is five digits.';
  static const String reasonClass = 'The vehicle class is 1 to 9.';
  static const String reasonType =
      'The middle group is a class digit and two year digits.';
  static const String reasonWilaya = 'The wilaya code is 01 to 69.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    serial: entry.group('serial'),
    type: entry.group('type'),
    wilaya: entry.group('wilaya'),
  );

  static PlateValidation validateFields({
    required String serial,
    required String type,
    required String wilaya,
  }) {
    if (!isDigitsOfLength(serial, 5)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    if (!isDigitsOfLength(type, 3)) {
      return const PlateValidation.invalid(reasonType);
    }
    if (!AlgeriaVehicleClasses.names.containsKey(type[0])) {
      return const PlateValidation.invalid(reasonClass);
    }
    if (!AlgeriaWilayas.names.containsKey(wilaya)) {
      return const PlateValidation.invalid(reasonWilaya);
    }
    return const PlateValidation.valid();
  }
}

/// Judges an `AlgeriaPlates.diplomatic` value: up to three digits of serial,
/// then two two-digit codes. The article lists no code ranges.
class AlgeriaDiplomaticValidator extends GatedPlateValidator {
  const AlgeriaDiplomaticValidator();

  @override
  String get gateGroup => 'mission';

  static const String reasonDigits =
      'A diplomatic plate is a serial and two two-digit codes.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String serial = entry.group('serial');
    if (serial.isEmpty ||
        !isDigits(serial) ||
        !isDigitsOfLength(entry.group('status'), 2) ||
        !isDigitsOfLength(entry.group('mission'), 2)) {
      return const PlateValidation.invalid(reasonDigits);
    }
    return const PlateValidation.valid();
  }
}
