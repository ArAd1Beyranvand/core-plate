import 'package:flutter/material.dart';

import '../input/plate_controller.dart';
import '../model/plate_country.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_canvas.dart';
import 'plate_selector.dart';
import 'plate_text_row.dart';

/// Read-only plate view driven by a [PlateController], with optional theme
/// and country overrides. For text-only rendering, use [PlateTextView].
class PlateView extends StatelessWidget {
  const PlateView({super.key, required this.controller, this.theme, this.country, this.emptyPlate});

  final PlateController controller;
  final PlateTheme? theme;
  final PlateCountry? country;
  final Widget? emptyPlate;

  @override
  Widget build(BuildContext context) {
    return PlateSelector<(PlateSpec, bool)>(
      controller: controller,
      selector: (c) => (c.spec, c.isEmpty),
      builder: (context, state) {
        final (spec, isEmpty) = state;
        final empty = emptyPlate;
        if (isEmpty && empty != null) return empty;
        return PlateCanvas(
          spec: spec,
          mode: PlateMode.display,
          theme: theme,
          country: country,
          controller: controller,
          onChooseCharacter: noCharacterChooser,
        );
      },
    );
  }
}

/// Text-only rendering of a [PlateController]'s plate characters.
class PlateTextView extends StatelessWidget {
  const PlateTextView({super.key, required this.controller, this.emptyPlate, this.textStyle});

  final PlateController controller;
  final Widget? emptyPlate;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.isEmpty
          ? (emptyPlate ?? const SizedBox.shrink())
          : PlateTextRow(spec: controller.spec, values: controller.values, textStyle: textStyle),
    );
  }
}
