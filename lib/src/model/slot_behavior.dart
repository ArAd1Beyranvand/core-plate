import 'plate_alphabet.dart';
import 'plate_input_source.dart';
import 'plate_number.dart';

/// What a slot does about input, resolved once. Every rendering and gesture
/// decision in `PlateSlotItem` switches on this rather than re-deriving it.
enum SlotBehavior {
  /// Read-only glyph. No focus node, no gestures. [PlateMode.display].
  glyph,

  /// TextField with the platform IME.
  imeField,

  /// TextField with the IME suppressed; physical key events are consumed.
  hardwareField,

  /// Focusable slot whose characters arrive from outside (package keypad or
  /// host). IME suppressed, cursor shown on focus, taps only claim focus.
  externalField,

  /// Tapping opens the character picker. Chosen alphabets under
  /// [PlateInputSource.system].
  sheet,
}

/// Note that [AlphabetInput.chosen] only reaches [SlotBehavior.sheet] under
/// [PlateInputSource.system]; every other source drives its own field type.
SlotBehavior resolveSlotBehavior({
  required PlateMode mode,
  required AlphabetInput input,
  required PlateInputSource source,
}) {
  if (mode == PlateMode.display) return SlotBehavior.glyph;
  switch (source) {
    case PlateInputSource.system:
      return input == AlphabetInput.typed ? SlotBehavior.imeField : SlotBehavior.sheet;
    case PlateInputSource.hardwareKeyboard:
      return SlotBehavior.hardwareField;
    case PlateInputSource.packageKeypad:
    case PlateInputSource.host:
      return SlotBehavior.externalField;
  }
}
