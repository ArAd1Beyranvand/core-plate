import 'package:flutter/material.dart';

import '../input/plate_controller.dart';
import '../model/plate_alphabet.dart';
import '../model/plate_country.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_canvas.dart';
import 'plate_selector.dart';

Future<String?> _noCharacterChooser(PlateAlphabet _) async => null;

/// Read-only plate view, driven by a [PlateController].
///
/// Renders the real graphical plate — pixel-identical to the editable widget —
/// in [PlateMode.display]. Unlike `ShowPlate`, which reads an ancestor bloc,
/// this takes the controller it renders and an optional [theme], so a host that
/// shows several plates in different liveries needs no provider per plate.
///
/// For a bare text rendering of the plate string, use [PlateTextView].
class PlateView extends StatelessWidget {
  const PlateView({
    super.key,
    required this.controller,
    this.theme,
    this.country,
    this.emptyPlate,
  });

  final PlateController controller;

  /// The livery to paint, or null to inherit from an ancestor [PlateTheme].
  final PlateTheme? theme;

  /// The country block to paint, forwarded to [PlateCanvas.country]. Null keeps
  /// the spec's own country.
  final PlateCountry? country;

  /// What to show while the plate has no characters at all. Null — the default
  /// — renders the plate itself, blank: a controller always knows its spec, so
  /// unlike `ShowPlate` there is always a plate to draw. Pass
  /// `SizedBox.shrink()` for `ShowPlate`'s show-nothing behaviour.
  final Widget? emptyPlate;

  @override
  Widget build(BuildContext context) {
    // Narrowed to the two things that decide what this widget renders: which
    // plate, and whether it has any characters. A keystroke that neither fills
    // the first slot nor empties the last one rebuilds nothing here — the
    // canvas's own per-slot bindings paint it.
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
          // Display mode never opens a chooser; onChooseCharacter is required
          // since the keypad split, so satisfy it with one that is never called.
          onChooseCharacter: _noCharacterChooser,
        );
      },
    );
  }
}

/// Plain-text rendering of a [PlateController]'s plate, for callers who want
/// just the characters rather than the graphical plate. The controller-driven
/// counterpart of `PlateText`.
class PlateTextView extends StatelessWidget {
  const PlateTextView({
    super.key,
    required this.controller,
    this.emptyPlate,
    this.textStyle,
  });

  final PlateController controller;
  final Widget? emptyPlate;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isEmpty) return emptyPlate ?? const SizedBox.shrink();
        final spec = controller.spec;
        final values = controller.values;
        return DefaultTextStyle(
          style: textStyle ?? const TextStyle(color: Colors.black),
          child: Directionality(
            textDirection: spec.textDirection,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final g in spec.effectiveTextGroups)
                  // Bounds-checked: a group index past the end of the value
                  // list is skipped rather than thrown on, so a spec swap that
                  // shortens the plate cannot crash a frame built against the
                  // longer one.
                  if (g.indices.any(
                    (i) => i < values.length && (values[i] ?? '').isNotEmpty,
                  ))
                    Text(spec.renderGroup(g, values)),
              ],
            ),
          ),
        );
      },
    );
  }
}
