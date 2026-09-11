import 'dart:math';

import 'package:core_plate/core_plate.dart';

import 'yemen_governorates.dart';

/// Makes up plate values that satisfy `YemenUnifiedValidator`.
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
/// final rnd = Random(7);
/// final values = YemenUnifiedSerialGenerator.generate(
///   YemenUnifiedPlates.car5,
///   random: rnd,
/// );
/// ```
abstract final class YemenUnifiedSerialGenerator {
  /// A value for [spec] — its vehicle number and its two-digit side code,
  /// positioned by the spec's own text groups.
  ///
  /// The returned list is `spec.slots.length` long, with every entry filled.
  ///
  /// Throws [ArgumentError] if [spec] carries no `number` and `sideCode`
  /// groups, which means it is not a `YemenUnifiedPlates` spec. Unlike a
  /// validator — which reports and never throws — a generator handed the wrong
  /// spec has nothing to report and nothing to return.
  ///
  /// The side code is two uniform digits. It is not drawn from the 1..22
  /// governorate numbering, because nothing establishes that the side code uses
  /// it — see the TODO in `YemenUnifiedValidator.validateFields`. Constraining
  /// it here would be that same guess, made twice.
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> number = _require(spec, 'number');
    final List<int> sideCode = _require(spec, 'sideCode');

    for (final int i in number) {
      values[i] = rnd.nextInt(10).toString();
    }
    for (final int i in sideCode) {
      values[i] = rnd.nextInt(10).toString();
    }

    return values;
  }

  /// [count] values for [spec], each one independently generated.
  static List<List<String?>> generateMany(PlateSpec spec, int count, {Random? random}) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(count, (_) => generate(spec, random: rnd), growable: false);
  }
}

/// Makes up plate values that satisfy `YemenNorthernValidator`.
///
/// The northern grammar has two real constraints, and this honours both: the
/// governorate code lands in 1..22, and the serial never begins with a zero.
/// See [YemenUnifiedSerialGenerator] for the general contract.
abstract final class YemenNorthernSerialGenerator {
  /// A value for [spec] — a governorate code and a serial, positioned by the
  /// spec's own text groups.
  ///
  /// The governorate code is drawn uniformly from the range the spec's upper
  /// register can hold: 1..22 over two cells, 1..9 over one. A two-cell
  /// register is zero-padded, because that is how the plate prints a
  /// single-digit code in a two-cell space; the serial is not, because that is
  /// how the plate does *not* print a short serial.
  ///
  /// Throws [ArgumentError] if [spec] carries no `governorate` and `serial`
  /// groups.
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);

    final List<int> governorate = _require(spec, 'governorate');
    final List<int> serial = _require(spec, 'serial');

    final int maxCode = governorate.length >= 2 ? YemenGovernorate.maxCode : 9;
    final String code = (YemenGovernorate.minCode + rnd.nextInt(maxCode - YemenGovernorate.minCode + 1))
        .toString()
        .padLeft(governorate.length, '0');
    for (int i = 0; i < governorate.length; i++) {
      values[governorate[i]] = code[i];
    }

    for (int i = 0; i < serial.length; i++) {
      // No leading zero: the first digit runs 1..9.
      values[serial[i]] = (i == 0 ? 1 + rnd.nextInt(9) : rnd.nextInt(10)).toString();
    }

    return values;
  }

  /// [count] values for [spec], each one independently generated.
  static List<List<String?>> generateMany(PlateSpec spec, int count, {Random? random}) {
    final Random rnd = random ?? Random();
    return List<List<String?>>.generate(count, (_) => generate(spec, random: rnd), growable: false);
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
