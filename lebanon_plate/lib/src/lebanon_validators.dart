import 'package:core_plate/core_plate.dart';

import 'lebanon_letters.dart';

/// Judges a Lebanese plate value.
///
/// Like every [PlateValidator] it never prevents a keystroke and never throws;
/// it reports, and the host decides what to do with the report. A slot's
/// alphabet is what restricts input, and it does so silently.
///
/// It stays quiet until the serial has something in it. The serial is the last
/// register a user reaches — the letter is slot 0 on every spec here — so by
/// the time it is non-empty there is something to judge. With nothing barring
/// input, the red state is the only feedback there is, and a plate that flashes
/// red at its first keystroke is worse than no validation at all.
///
/// ### What it checks, and what it cannot
///
/// Lebanon's grammar gives a validator very little to work with. The letter is
/// a closed set, so that is checkable. The serial is one to six digits, so its
/// shape is checkable. Its *value* is not: there is no published block
/// allocation, no check digit, and no range per town, so `B 000001` and
/// `B 999999` are equally well-formed as far as anything public says.
///
/// The one documented range in the whole system is [LebanonLetter.mp]'s: a
/// parliament plate is numbered 1..128, one per seat. That is checked.
///
/// Two things it deliberately does **not** treat as errors:
///
/// - **A letter that is no longer issued.** `K` (Baalbek) is documented as out
///   of service, and `K` plates are on the road. See [LebanonLetter.inUse].
/// - **A leading zero.** Nothing establishes whether a short number is printed
///   padded or bare, so both pass.
class LebanonValidator extends GatedPlateValidator {
  /// A stateless rule; hold one as a `const`.
  const LebanonValidator();

  @override
  String get gateGroup => 'serial';

  /// Reported when the letter cell is empty.
  static const String reasonLetterMissing = 'A plate starts with a letter.';

  /// Reported when the letter is not one Lebanon issues.
  static const String reasonLetterUnknown = 'That is not a Lebanese plate letter.';

  /// Reported when the serial holds something other than digits.
  static const String reasonSerialNotNumeric = 'The number is digits only.';

  /// Reported when the serial is empty or longer than six digits.
  static const String reasonSerialLength = 'The number is one to six digits.';

  /// Reported when an `MP` plate's number is outside 1..128.
  static const String reasonParliamentRange = 'A parliament plate is numbered 1 to 128.';

  /// The shortest and longest number a Lebanese plate carries.
  static const int minSerialLength = 1;
  static const int maxSerialLength = 6;

  /// The highest parliament plate number — one per seat.
  static const int maxParliamentNumber = 128;

  @override
  PlateValidation judge(PlateEntry entry) =>
      validateFields(letter: entry.group('letter'), serial: entry.group('serial'));

  /// The rule without a spec: pass the two registers in directly.
  ///
  /// [letter] is the character in the plate's first cell — one of
  /// [LebanonLetter.characters], including the two-glyph `MP`. [serial] is the
  /// number after it.
  static PlateValidation validateFields({required String letter, required String serial}) {
    if (letter.isEmpty) {
      return const PlateValidation.invalid(reasonLetterMissing);
    }
    final LebanonLetter? code = LebanonLetter.fromCharacter(letter);
    if (code == null) {
      return const PlateValidation.invalid(reasonLetterUnknown);
    }

    if (serial.length < minSerialLength || serial.length > maxSerialLength) {
      return const PlateValidation.invalid(reasonSerialLength);
    }
    if (!isDigits(serial)) {
      return const PlateValidation.invalid(reasonSerialNotNumeric);
    }

    if (code == LebanonLetter.mp) {
      // The one documented range in the system. `int.parse` is safe here: the
      // digit check above has already run, and six digits cannot overflow.
      final int number = int.parse(serial);
      if (number < 1 || number > maxParliamentNumber) {
        return const PlateValidation.invalid(reasonParliamentRange);
      }
    }

    return const PlateValidation.valid();
  }
}
