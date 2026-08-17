import 'package:flutter/material.dart';

import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import '../widgets/plate_canvas.dart';

/// The car plate widget.
///
/// A thin wrapper over [PlateCanvas] bound to [PlateSpecs.irCar]. The layout,
/// focus chain and letter picker all live in the canvas; this widget only
/// preserves the historical public API.
class CarPlateNumber extends StatelessWidget {
  const CarPlateNumber({
    super.key,
    this.mode = PlateMode.input,
    this.theme,
    this.onChooseLetter,
    this.onRemove,
    this.showRemoveButton = false,
    this.letterInputMode,
    this.onActiveSlotChanged,
  });

  final PlateMode mode;
  final PlateTheme? theme;

  /// How the plate letter is entered. Null resolves to
  /// [defaultLetterInputMode] for the current platform.
  final LetterInputMode? letterInputMode;

  /// Fires whenever the active (focused) slot changes, reporting the active
  /// slot — including its alphabet, not just its position — or null when focus
  /// leaves the plate. Primarily for [LetterInputMode.hostKeypad], so an
  /// app-supplied letter pad can show itself when the letter slot becomes
  /// active — including when the focus chain lands there after the first digit
  /// group completes — and hide itself when focus moves on.
  final ValueChanged<PlateSlot?>? onActiveSlotChanged;

  /// Optional escape hatch to override the default letter-picker sheet.
  final Future<String?> Function()? onChooseLetter;

  /// Called when the (external) remove button is pressed.
  final VoidCallback? onRemove;

  /// Whether to render the remove button in a column below the plate.
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    return PlateCanvas(
      spec: PlateSpecs.irCar,
      mode: mode,
      theme: theme,
      letterInputMode: letterInputMode,
      onChooseCharacter:
          onChooseLetter == null ? null : (_) => onChooseLetter!(),
      onActiveSlotChanged: onActiveSlotChanged,
      onRemove: onRemove,
      showRemoveButton: showRemoveButton,
    );
  }
}
