import 'plate_alphabet.dart';
import 'plate_input_source.dart';
import 'plate_number.dart';

/// What a slot does about input, resolved once from the three things that
/// decide it. Every rendering and gesture decision in [PlateSlotItem] is a
/// switch on this — none of them re-derives it from [PlateInputSource].
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

/// Ports the exact mapping the widget layer used to re-derive in five places:
///
/// | mode | alphabet input | source | behavior |
/// |---|---|---|---|
/// | display | any | any | [SlotBehavior.glyph] |
/// | input | typed | system | [SlotBehavior.imeField] |
/// | input | typed | hardwareKeyboard | [SlotBehavior.hardwareField] |
/// | input | typed | packageKeypad / host | [SlotBehavior.externalField] |
/// | input | chosen | system | [SlotBehavior.sheet] |
/// | input | chosen | hardwareKeyboard | [SlotBehavior.hardwareField] |
/// | input | chosen | packageKeypad / host | [SlotBehavior.externalField] |
SlotBehavior resolveSlotBehavior({
  required PlateMode mode,
  required AlphabetInput input,
  required PlateInputSource source,
}) {
  if (mode == PlateMode.display) return SlotBehavior.glyph;
  switch (source) {
    case PlateInputSource.system:
      return input == AlphabetInput.typed
          ? SlotBehavior.imeField
          : SlotBehavior.sheet;
    case PlateInputSource.hardwareKeyboard:
      return SlotBehavior.hardwareField;
    case PlateInputSource.packageKeypad:
    case PlateInputSource.host:
      return SlotBehavior.externalField;
  }
}
