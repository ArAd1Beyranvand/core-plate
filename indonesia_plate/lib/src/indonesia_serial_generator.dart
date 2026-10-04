import 'dart:math';

import 'package:plate_core/plate_core.dart';

import 'indonesia_validators.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills the groups of an `IndonesiaPlates.car` or `motorcycle` spec. [area]
/// fixes the area code (`'B'`); otherwise one of the right length is drawn
/// from [IndonesiaAreaCodes]. Numbers have no leading zero; the expiry month
/// is 01–12.
abstract final class IndonesiaSerialGenerator {
  static const String _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static List<String?> generate(
    PlateSpec spec, {
    Random? random,
    String? area,
  }) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);
    final List<int> prefix = spec.indicesOfGroup('prefix');
    final List<String> codes = IndonesiaAreaCodes.all
        .where((c) => c.length == prefix.length)
        .toList();
    final String code = area ?? codes[rnd.nextInt(codes.length)];
    for (int i = 0; i < prefix.length && i < code.length; i++) {
      values[prefix[i]] = code[i];
    }
    final List<int> number = spec.indicesOfGroup('number');
    for (int i = 0; i < number.length; i++) {
      values[number[i]] = (i == 0 ? 1 + rnd.nextInt(9) : rnd.nextInt(10))
          .toString();
    }
    for (final int i in spec.indicesOfGroup('suffix')) {
      values[i] = _letters[rnd.nextInt(_letters.length)];
    }
    final String month = (1 + rnd.nextInt(12)).toString().padLeft(2, '0');
    final String year = (26 + rnd.nextInt(5)).toString();
    final List<int> m = spec.indicesOfGroup('month');
    final List<int> y = spec.indicesOfGroup('year');
    for (int i = 0; i < m.length; i++) {
      values[m[i]] = month[i];
    }
    for (int i = 0; i < y.length; i++) {
      values[y[i]] = year[i];
    }
    return values;
  }
}
