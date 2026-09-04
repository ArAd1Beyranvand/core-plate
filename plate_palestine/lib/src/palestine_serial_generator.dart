import 'dart:math';

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
  /// A modern West Bank plate: `[region, s1, s2, s3, s4, governorateLetter]`.
  static List<String?> modernWestBank(Random rng) {
    final letters = PSGovernorate.letters;
    return [
      _digit(rng),
      ..._digits(rng, 4),
      letters[rng.nextInt(letters.length)],
    ];
  }

  /// A legacy West Bank plate: `[district, s1, s2, s3, s4, u1, u2]`.
  static List<String?> legacyWestBank(Random rng) {
    final district = PSLegacyUsage.districtCodes;
    final usage = PSLegacyUsage.codes;
    return [
      district[rng.nextInt(district.length)],
      ..._digits(rng, 4),
      ...usage[rng.nextInt(usage.length)].split(''),
    ];
  }

  /// A Gaza plate: `['3', s1, s2, s3, s4, u1, u2]`.
  static List<String?> gaza(Random rng) {
    final usage = PSGazaUsage.codes;
    return [
      '3',
      ..._digits(rng, 4),
      ...usage[rng.nextInt(usage.length)].split(''),
    ];
  }

  /// [values] joined with no separator — the shape a filename or a synthetic
  /// dataset row wants, as opposed to [PlateSpec.renderGroup]'s grouped,
  /// dotted rendering.
  static String toFilename(List<String?> values) =>
      values.map((v) => v ?? '').join();

  static String _digit(Random rng) => rng.nextInt(10).toString();

  static List<String> _digits(Random rng, int count) => [
    for (var i = 0; i < count; i++) _digit(rng),
  ];
}
