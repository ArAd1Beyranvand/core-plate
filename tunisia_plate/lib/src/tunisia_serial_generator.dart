import 'dart:math';

import 'package:plate_core/core_plate.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills every digit slot of any `TunisiaPlates` spec. A `series` group has no
/// leading zero and, at three digits, is drawn from the 2008–2026 series the
/// article lists (131–261); a diplomatic `serial` is never `00`.
abstract final class TunisiaSerialGenerator {
  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);
    for (final PlateTextGroup group in spec.textGroups) {
      final int n = group.indices.length;
      final String digits = switch (group.key) {
        'series' when n == 3 => (131 + rnd.nextInt(131)).toString(),
        'series' =>
          (pow(10, n - 1) + rnd.nextInt(9 * pow(10, n - 1).toInt())).toString(),
        _ => (1 + rnd.nextInt(pow(10, n).toInt() - 1)).toString().padLeft(
          n,
          '0',
        ),
      };
      for (int i = 0; i < n; i++) {
        values[group.indices[i]] = digits[i];
      }
    }
    return values;
  }
}
