import 'package:core_plate/core_plate.dart';
import 'package:core_plate/src/model/slot_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Short aliases so every row of the table below fits on one line and reads
// like the table it is transcribed from.
const _display = PlateMode.display;
const _input = PlateMode.input;
const _typed = AlphabetInput.typed;
const _chosen = AlphabetInput.chosen;
const _system = PlateInputSource.system;
const _hardware = PlateInputSource.hardwareKeyboard;
const _keypad = PlateInputSource.packageKeypad;
const _host = PlateInputSource.host;

const _glyph = SlotBehavior.glyph;
const _ime = SlotBehavior.imeField;
const _hardwareField = SlotBehavior.hardwareField;
const _external = SlotBehavior.externalField;
const _sheet = SlotBehavior.sheet;

/// The table in `slot_behavior.dart:29-37`, transcribed by hand rather than
/// re-derived — a test that recomputes the function it is checking checks
/// nothing.
///
/// | mode | alphabet input | source | behavior |
const _table = <(PlateMode, AlphabetInput, PlateInputSource, SlotBehavior)>[
  (_display, _typed, _system, _glyph),
  (_display, _typed, _hardware, _glyph),
  (_display, _typed, _keypad, _glyph),
  (_display, _typed, _host, _glyph),
  (_display, _chosen, _system, _glyph),
  (_display, _chosen, _hardware, _glyph),
  (_display, _chosen, _keypad, _glyph),
  (_display, _chosen, _host, _glyph),

  (_input, _typed, _system, _ime),
  (_input, _typed, _hardware, _hardwareField),
  (_input, _typed, _keypad, _external),
  (_input, _typed, _host, _external),

  (_input, _chosen, _system, _sheet),
  (_input, _chosen, _hardware, _hardwareField),
  (_input, _chosen, _keypad, _external),
  (_input, _chosen, _host, _external),
];

void main() {
  group('resolveSlotBehavior', () {
    test('the table covers every combination exactly once', () {
      final combinations = <(PlateMode, AlphabetInput, PlateInputSource)>{
        for (final row in _table) (row.$1, row.$2, row.$3),
      };
      expect(_table, hasLength(16));
      expect(
        combinations,
        hasLength(
          PlateMode.values.length *
              AlphabetInput.values.length *
              PlateInputSource.values.length,
        ),
        reason: 'a dropped or duplicated row would silently stop being checked',
      );
    });

    for (final (mode, input, source, expected) in _table) {
      test(
        '${mode.name} + ${input.name} + ${source.name} -> ${expected.name}',
        () {
          expect(
            resolveSlotBehavior(mode: mode, input: input, source: source),
            expected,
          );
        },
      );
    }
  });

  group('defaultInputSource', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    const desktop = {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    };

    for (final platform in TargetPlatform.values) {
      final expected = desktop.contains(platform)
          ? PlateInputSource.hardwareKeyboard
          : PlateInputSource.system;
      test('${platform.name} -> ${expected.name}', () {
        debugDefaultTargetPlatformOverride = platform;
        expect(defaultInputSource(), expected);
      });
    }
  });
}
