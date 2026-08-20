import 'package:flutter/foundation.dart';

import 'plate_number.dart';

/// How characters get into a plate slot.
enum PlateInputSource {
  /// Bring up the platform keyboard (the IME) to enter this slot.
  system,

  /// Accept physical key presses only; the on-screen IME is suppressed.
  hardwareKeyboard,

  /// Route input through the library's own on-screen [PlateKeypad]; the IME
  /// is suppressed.
  packageKeypad,

  /// The host app supplies every character through [PlateInputController];
  /// the IME is suppressed.
  host,
}

/// The default [PlateInputSource] for the current platform: [PlateInputSource.hardwareKeyboard]
/// on desktop (windows, linux, macOS), [PlateInputSource.system] everywhere
/// else. On web, [defaultTargetPlatform] reflects the underlying OS, so this
/// switch covers web correctly too.
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

/// Maps the deprecated [LetterInputMode] onto its [PlateInputSource]
/// equivalent: [LetterInputMode.picker] to [PlateInputSource.system],
/// [LetterInputMode.keyboard] to [PlateInputSource.hardwareKeyboard], and
/// [LetterInputMode.hostKeypad] to [PlateInputSource.host].
PlateInputSource inputSourceFromLetterMode(LetterInputMode m) {
  switch (m) {
    case LetterInputMode.picker:
      return PlateInputSource.system;
    case LetterInputMode.keyboard:
      return PlateInputSource.hardwareKeyboard;
    case LetterInputMode.hostKeypad:
      return PlateInputSource.host;
  }
}
