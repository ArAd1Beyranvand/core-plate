import 'dart:math';

import 'package:core_plate/core_plate.dart';

import 'lebanon_letters.dart';
import 'lebanon_usage.dart';
import 'lebanon_validators.dart';

/// Makes up plate values that satisfy [LebanonValidator].
///
/// For demos, screenshots, seeded fixtures and golden tests — not for issuing
/// anything. A generated value is a well-formed value, not a registered one.
///
/// Pure Dart: no Flutter import, no widget, no plate. It reads the shape of a
/// [PlateSpec] and returns the `List<String?>` a `PlateController` or
/// `ShowPlate` takes, so the output drops straight into either.
///
/// Pass a seeded [Random] for a repeatable sequence:
///
/// ```dart
/// final values = LebanonSerialGenerator.generate(
///   LebanonPlates.oneLine,
///   random: Random(7),
/// );
/// ```
abstract final class LebanonSerialGenerator {
  /// A value for [spec] — a letter and a number, written at the slot indices
  /// the spec's own `letter` and `serial` text groups name.
  ///
  /// The returned list is `spec.slots.length` long, with every entry filled.
  ///
  /// [letter] fixes the letter; omit it and one is drawn from the letters that
  /// are currently issued — `K` is excluded, because generating a plate nobody
  /// is issued today is a surprise in a fixture. [usage] is an alternative way
  /// to fix it: a usage that pins a letter (consular `C`, diplomatic `D`) pins
  /// it here too. Passing both is an error rather than a silent precedence
  /// rule.
  ///
  /// An `MP` letter constrains the number to 1..128, so the result still passes
  /// the validator; every other letter takes a uniform number of the register's
  /// full width, with a non-zero leading digit so the value reads as the length
  /// it is.
  ///
  /// Throws [ArgumentError] if [spec] carries no `letter` and `serial` groups,
  /// which means it is not a `LebanonPlates` spec. Unlike a validator — which
  /// reports and never throws — a generator handed the wrong spec has nothing
  /// to report and nothing to return.
  static List<String?> generate(PlateSpec spec, {Random? random, LebanonLetter? letter, LebanonUsage? usage}) {
    if (letter != null && usage?.letter != null) {
      throw ArgumentError('Pass letter: or usage:, not both — they would disagree.');
    }
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> letterSlots = _require(spec, 'letter');
    final List<int> serialSlots = _require(spec, 'serial');

    final LebanonLetter chosen =
        letter ??
        (usage?.letter != null ? LebanonLetter.fromCharacter(usage!.letter!)! : _issued[rnd.nextInt(_issued.length)]);
    // A letter register is one cell on every spec here, but writing it cell by
    // cell costs nothing and keeps a derived two-cell layout working.
    for (int i = 0; i < letterSlots.length; i++) {
      values[letterSlots[i]] = i == 0 ? chosen.character : '';
    }

    final String serial = chosen == LebanonLetter.mp
        ? (1 + rnd.nextInt(LebanonValidator.maxParliamentNumber)).toString().padLeft(
            // Never wider than the register: a three-cell plate cannot show 128
            // padded to six.
            serialSlots.length.clamp(1, 3),
            '0',
          )
        : _number(serialSlots.length, rnd);

    for (int i = 0; i < serialSlots.length; i++) {
      // A short MP number in a wide register leaves the tail cells empty, which
      // is what a short plate looks like.
      values[serialSlots[i]] = i < serial.length ? serial[i] : '';
    }

    return values;
  }

  /// [count] values for [spec], each one independently generated.
  static List<List<String?>> generateMany(
    PlateSpec spec,
    int count, {
    Random? random,
    LebanonLetter? letter,
    LebanonUsage? usage,
  }) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(
      count,
      (_) => generate(spec, random: rnd, letter: letter, usage: usage),
      growable: false,
    );
  }

  /// The letters currently issued — every one but `K`.
  static final List<LebanonLetter> _issued = LebanonLetter.values
      .where((LebanonLetter l) => l.inUse)
      .toList(growable: false);

  /// [length] digits, the first of them non-zero.
  static String _number(int length, Random rnd) {
    final StringBuffer buffer = StringBuffer((1 + rnd.nextInt(9)).toString());
    for (int i = 1; i < length; i++) {
      buffer.write(rnd.nextInt(10));
    }
    return buffer.toString();
  }
}

/// The slot indices of [spec]'s text group named [key].
///
/// [PlateSpec.indicesOfGroup] returns empty when no group carries the key; a
/// generator handed such a spec has nothing to write, so it throws instead.
List<int> _require(PlateSpec spec, String key) {
  final List<int> indices = spec.indicesOfGroup(key);
  if (indices.isEmpty) {
    throw ArgumentError.value(spec.id, 'spec', 'has no text group named "$key"');
  }
  return indices;
}
