import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/model/plate_alphabet.dart';
import 'package:plate_number/model/plate_input_source.dart';
import 'package:plate_number/model/plate_number.dart';
import 'package:plate_number/model/slot_behavior.dart';

void main() {
  group('resolveSlotBehavior', () {
    test('display mode is always a glyph, whatever the source or alphabet', () {
      for (final input in AlphabetInput.values) {
        for (final source in PlateInputSource.values) {
          expect(
            resolveSlotBehavior(
              mode: PlateMode.display,
              input: input,
              source: source,
            ),
            SlotBehavior.glyph,
          );
        }
      }
    });

    test('typed + system -> imeField', () {
      expect(
        resolveSlotBehavior(
          mode: PlateMode.input,
          input: AlphabetInput.typed,
          source: PlateInputSource.system,
        ),
        SlotBehavior.imeField,
      );
    });

    test('typed + hardwareKeyboard -> hardwareField', () {
      expect(
        resolveSlotBehavior(
          mode: PlateMode.input,
          input: AlphabetInput.typed,
          source: PlateInputSource.hardwareKeyboard,
        ),
        SlotBehavior.hardwareField,
      );
    });

    test('typed + packageKeypad/host -> externalField', () {
      for (final source in [
        PlateInputSource.packageKeypad,
        PlateInputSource.host,
      ]) {
        expect(
          resolveSlotBehavior(
            mode: PlateMode.input,
            input: AlphabetInput.typed,
            source: source,
          ),
          SlotBehavior.externalField,
        );
      }
    });

    test('chosen + system -> sheet', () {
      expect(
        resolveSlotBehavior(
          mode: PlateMode.input,
          input: AlphabetInput.chosen,
          source: PlateInputSource.system,
        ),
        SlotBehavior.sheet,
      );
    });

    test('chosen + hardwareKeyboard -> hardwareField', () {
      expect(
        resolveSlotBehavior(
          mode: PlateMode.input,
          input: AlphabetInput.chosen,
          source: PlateInputSource.hardwareKeyboard,
        ),
        SlotBehavior.hardwareField,
      );
    });

    test('chosen + packageKeypad/host -> externalField', () {
      for (final source in [
        PlateInputSource.packageKeypad,
        PlateInputSource.host,
      ]) {
        expect(
          resolveSlotBehavior(
            mode: PlateMode.input,
            input: AlphabetInput.chosen,
            source: source,
          ),
          SlotBehavior.externalField,
        );
      }
    });
  });
}
