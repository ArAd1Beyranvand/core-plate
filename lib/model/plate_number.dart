import 'package:flutter/foundation.dart';

class PlateNumber {
  final List values;
  final List valueTypes;

  PlateNumber({required this.values, required this.valueTypes});

  PlateNumber copyWith({List? values, List? valueTypes}) {
    return PlateNumber(
      values: values ?? this.values,
      valueTypes: valueTypes ?? this.valueTypes,
    );
  }
}

abstract final class SelectableString {
  const SelectableString();
}

abstract final class SelectableInt {
  const SelectableInt();
}

enum PlateType {
  irBicycle,
  irCar,
}

/// How the plate letter is entered: a modal [picker] on touch platforms,
/// direct [keyboard] typing on desktop, or an app-supplied on-screen letter pad
/// ([hostKeypad]).
///
/// In [hostKeypad] mode the letter slot behaves like [picker] visually — it is
/// focusable and shows the active-slot underline — but tapping it never opens
/// the modal sheet. The slot only reports that it is now the active slot; the
/// host app renders its own letter pad and feeds the chosen letter back through
/// the usual bloc path.
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

extension Tool on PlateType {
  String vehicleType() {
    switch (this) {
      case PlateType.irBicycle:
        return 'bicycle';
      case PlateType.irCar:
        return 'car';
    }
  }

  String parseToString() {
    switch (this) {
      case PlateType.irBicycle:
        return 'irBicycle';
      case PlateType.irCar:
        return 'irCar';
    }
  }
}
