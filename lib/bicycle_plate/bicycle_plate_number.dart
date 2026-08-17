import 'package:flutter/material.dart';

import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import '../widgets/plate_canvas.dart';

/// The bicycle (motorcycle) plate widget.
///
/// A thin wrapper over [PlateCanvas] bound to [PlateSpecs.irBicycle]. The
/// layout and focus chain live in the canvas; this widget only preserves the
/// historical public API.
class BicyclePlateNumber extends StatelessWidget {
  const BicyclePlateNumber({
    super.key,
    this.mode = PlateMode.input,
    this.theme,
    this.onRemove,
    this.showRemoveButton = false,
  });

  final PlateMode mode;
  final PlateTheme? theme;

  /// Called when the (external) remove button is pressed.
  final VoidCallback? onRemove;

  /// Whether to render the remove button in a column below the plate.
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    return PlateCanvas(
      spec: PlateSpecs.irBicycle,
      mode: mode,
      theme: theme,
      onRemove: onRemove,
      showRemoveButton: showRemoveButton,
    );
  }
}
