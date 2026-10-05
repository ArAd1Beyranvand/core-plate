import 'dart:math';

import 'package:plate_core/plate_core.dart';

import 'vietnam_missions.dart';

/// Generates plausible values for fixtures and demos. Pure Dart.
///
/// Fills every text group a Vietnam spec has: province 11–99, a series
/// letter (a digit allowed in the second cell of a motorcycle series), a
/// unit code, a number, and a mission code that is never 336–340.
abstract final class VietnamSerialGenerator {
  static const String _series = 'ABCDEFGHKLMNPRSTUVXYZ';
  static const String _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';

  static List<String?> generate(PlateSpec spec, {Random? random}) {
    final Random rnd = random ?? Random();
    final List<String?> values = List<String?>.filled(spec.slots.length, null);
    String pick(String pool) => pool[rnd.nextInt(pool.length)];

    final List<int> province = spec.indicesOfGroup('province');
    if (province.length == 2) {
      final String p = (11 + rnd.nextInt(89)).toString();
      values[province[0]] = p[0];
      values[province[1]] = p[1];
    } else {
      for (final int i in province) {
        values[i] = pick(_digits);
      }
    }
    for (final int i in spec.indicesOfGroup('series')) {
      values[i] = pick(_series);
    }
    // A motorcycle series' second cell is a letter or a digit.
    for (final int i in spec.indicesOfGroup('series2')) {
      values[i] = rnd.nextBool() ? pick(_digits) : pick(_series);
    }
    for (final int i in spec.indicesOfGroup('unit')) {
      values[i] = pick(_letters);
    }
    for (final int i in spec.indicesOfGroup('status')) {
      values[i] = pick(_letters);
    }
    final List<int> mission = spec.indicesOfGroup('mission');
    if (mission.isNotEmpty) {
      String code;
      do {
        code = (100 + rnd.nextInt(900)).toString();
      } while (VietnamMissions.isRefused(code));
      for (int i = 0; i < mission.length; i++) {
        values[mission[i]] = code[i];
      }
    }
    for (final String key in <String>['number', 'number2', 'number3']) {
      for (final int i in spec.indicesOfGroup(key)) {
        values[i] = pick(_digits);
      }
    }
    return values;
  }
}
