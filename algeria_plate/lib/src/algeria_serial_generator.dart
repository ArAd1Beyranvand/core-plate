import 'dart:math';

import 'package:plate_core/plate_core.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills every slot with a random digit, then, on a civil spec, makes the
/// `type` group a class ([vehicleClass], default random) plus a year
/// 00–26, and the `wilaya` group [wilaya] or a code 01–58 (the ones issued
/// before 2027).
abstract final class AlgeriaSerialGenerator {
  static List<String?> generate(
    PlateSpec spec, {
    Random? random,
    int? vehicleClass,
    int? wilaya,
  }) {
    final Random rnd = random ?? Random();
    final List<String?> values = <String?>[
      for (int i = 0; i < spec.slots.length; i++) '${rnd.nextInt(10)}',
    ];
    void fill(String key, String text) {
      final List<int> slots = spec.indicesOfGroup(key);
      for (int i = 0; i < slots.length && i < text.length; i++) {
        values[slots[i]] = text[i];
      }
    }

    if (spec.indicesOfGroup('type').isNotEmpty) {
      final int year = rnd.nextInt(27);
      fill('type', '${vehicleClass ?? 1 + rnd.nextInt(9)}${_two(year)}');
    }
    if (spec.indicesOfGroup('wilaya').isNotEmpty) {
      fill('wilaya', _two(wilaya ?? 1 + rnd.nextInt(58)));
    }
    return values;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
