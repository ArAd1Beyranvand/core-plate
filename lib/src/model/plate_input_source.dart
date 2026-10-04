import 'package:flutter/foundation.dart';

/// How characters get into a plate slot.
enum PlateInputSource {
  /// Bring up the platform keyboard (the IME) to enter this slot.
  system,

  /// Accept physical key presses only; the on-screen IME is suppressed.
  hardwareKeyboard,

  /// Route input through the on-screen keypad from the `plate_keypad` package;
  /// the IME is suppressed.
  packageKeypad,

  /// The host app supplies every character through [PlateController];
  /// the IME is suppressed.
  host,
}

/// Hardware keyboard on desktop, the system IME everywhere else. Web falls out
/// correctly because [defaultTargetPlatform] there reports the underlying OS.
PlateInputSource defaultInputSource() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return PlateInputSource.hardwareKeyboard;
    default:
      return PlateInputSource.system;
  }
}
