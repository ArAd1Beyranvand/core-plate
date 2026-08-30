import 'package:flutter/foundation.dart';

class PlateNumber {
  final List<String?> values;

  PlateNumber({required this.values});

  PlateNumber copyWith({List<String?>? values}) {
    return PlateNumber(
      values: values ?? this.values,
    );
  }

  bool isCompleted() => !values.any((e) => e == null || e == '');

  bool isEmpty() => !values.any((e) => e != null);

  /// Value equality over [values].
  ///
  /// Without this the class was identity-compared, so anything watching a
  /// [PlateNumber] — notably `context.select` in the canvas — treated every
  /// bloc emission as a change and rebuilt, even when the characters were
  /// identical.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlateNumber && listEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hashAll(values);
}

/// How the plate letter is entered: a modal [picker] on touch platforms,
/// direct [keyboard] typing on desktop, or an app-supplied on-screen pad
/// ([hostKeypad]).
///
/// [hostKeypad] means the host supplies every character for this plate, not
/// just the letter: chosen slots behave like [picker] visually — focusable,
/// showing the active-slot underline, but tapping never opens the modal sheet
/// — and typed slots (e.g. digits) render read-only so the platform keyboard
/// never appears. Either way the slot only claims focus; the host app renders
/// its own pad and feeds every character back through the usual bloc path.
enum LetterInputMode { picker, keyboard, hostKeypad }

/// The default letter input mode for the current platform: keyboard on
/// desktop, picker everywhere else.
LetterInputMode defaultLetterInputMode() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return LetterInputMode.keyboard;
    default:
      return LetterInputMode.picker;
  }
}

/// How a plate (and its items) render: [input] shows editable fields, [display]
/// shows bare glyphs on the white face like a real plate photo.
enum PlateMode {
  input,
  display,
}
