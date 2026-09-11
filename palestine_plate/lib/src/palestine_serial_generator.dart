import 'dart:math';

import 'package:core_plate/core_plate.dart';

import 'palestine_governorates.dart';
import 'palestine_usage.dart';

/// Synthetic Palestinian plate serials, for demos and reproducible test data.
///
/// Pure Dart — no Flutter import beyond what a plain `dart:math` `Random`
/// needs — so it runs in a unit test without a widget binding.
///
/// One generator per scheme, each seeded so a given seed always produces the
/// same sequence. Every value returned is drawn from the same legal set the
/// matching validator's `validateFields` accepts: [modernWestBank] never
/// emits `I`, `O` or a reserved Gaza letter; [legacyWestBank] never emits
/// district `0`/`2` or a usage code outside [PSLegacyUsage.codes]; [gaza]
/// never emits a prefix other than `3`. That is asserted, not just claimed —
/// see `test/palestine_serial_generator_test.dart`, which round-trips 10 000
/// of each through its validator.
///
/// Returns `List<String?>`, the same shape [PlateSpec.slots] and every
/// validator already speak, so a generated value drops straight into a
/// `PlateEntry` or a `PlateCardBloc`'s initial state.
abstract final class PSSerialGenerator {
  /// A value for [spec], a modern West Bank plate.
  ///
  /// Positions come from the spec's own `region` / `serial` / `governorate`
  /// text groups, so a new layout with the same registers in different slots
  /// generates correctly without touching this file.
  ///
  /// Throws [ArgumentError] if [spec] carries no such groups.
  static List<String?> modernWestBank(PlateSpec spec, {Random? random}) {
    final rng = random ?? Random();
    final values = List<String?>.filled(spec.slots.length, null);
    final region = _require(spec, 'region');
    final serial = _require(spec, 'serial');
    final governorate = _require(spec, 'governorate');

    for (final i in region) {
      values[i] = _digit(rng);
    }
    for (final i in serial) {
      values[i] = _digit(rng);
    }
    final letters = PSGovernorate.letters;
    for (final i in governorate) {
      values[i] = letters[rng.nextInt(letters.length)];
    }
    return values;
  }

  /// A value for [spec], a legacy West Bank plate.
  ///
  /// Positions come from the spec's own `district` / `serial` / `usage` text
  /// groups. The two-character usage code is written across the two slots of
  /// the `usage` group — identical to the old fixed layout for every existing
  /// spec, correct for one where those cells are not adjacent.
  ///
  /// Throws [ArgumentError] if [spec] carries no such groups.
  static List<String?> legacyWestBank(PlateSpec spec, {Random? random}) {
    final rng = random ?? Random();
    final values = List<String?>.filled(spec.slots.length, null);
    final district = _require(spec, 'district');
    final serial = _require(spec, 'serial');
    final usage = _require(spec, 'usage');

    final districtCodes = PSLegacyUsage.districtCodes;
    for (final i in district) {
      values[i] = districtCodes[rng.nextInt(districtCodes.length)];
    }
    for (final i in serial) {
      values[i] = _digit(rng);
    }
    _writeUsage(values, usage, PSLegacyUsage.codes[rng.nextInt(PSLegacyUsage.codes.length)]);
    return values;
  }

  /// A value for [spec], a Gaza plate.
  ///
  /// Positions come from the spec's own `prefix` / `serial` / `usage` text
  /// groups. The prefix is the literal `'3'`.
  ///
  /// Throws [ArgumentError] if [spec] carries no such groups.
  static List<String?> gaza(PlateSpec spec, {Random? random}) {
    final rng = random ?? Random();
    final values = List<String?>.filled(spec.slots.length, null);
    final prefix = _require(spec, 'prefix');
    final serial = _require(spec, 'serial');
    final usage = _require(spec, 'usage');

    for (final i in prefix) {
      values[i] = '3';
    }
    for (final i in serial) {
      values[i] = _digit(rng);
    }
    _writeUsage(values, usage, PSGazaUsage.codes[rng.nextInt(PSGazaUsage.codes.length)]);
    return values;
  }

  /// Writes each character of [code] into the successive slots of [indices].
  static void _writeUsage(List<String?> values, List<int> indices, String code) {
    final chars = code.split('');
    for (var n = 0; n < indices.length && n < chars.length; n++) {
      values[indices[n]] = chars[n];
    }
  }

  static List<int> _require(PlateSpec spec, String key) {
    final indices = spec.indicesOfGroup(key);
    if (indices.isEmpty) {
      throw ArgumentError.value(spec.id, 'spec', 'has no text group named "$key"');
    }
    return indices;
  }

  /// [values] joined with no separator — the shape a filename or a synthetic
  /// dataset row wants, as opposed to [PlateSpec.renderGroup]'s grouped,
  /// dotted rendering.
  static String toFilename(List<String?> values) => values.map((v) => v ?? '').join();

  static String _digit(Random rng) => rng.nextInt(10).toString();
}
