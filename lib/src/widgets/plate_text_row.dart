import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_spec.dart';

/// A character chooser that never chooses: for `PlateMode.display`, where
/// `PlateCanvas.onChooseCharacter` is required but is never called.
Future<String?> noCharacterChooser(PlateAlphabet alphabet) async => null;

/// The plain-text rendering of a plate: each of [spec]'s effective text groups,
/// rendered through its slots' alphabets, laid out in the plate's own reading
/// direction.
///
/// The shared body of [PlateTextView] (controller-driven) and `PlateText` from
/// `core_plate_bloc` (bloc-driven). Those two differ only in where they read
/// [spec] and [values]; everything below the read was the same 30 lines in both
/// packages.
///
/// A group with no non-empty value is omitted rather than rendered blank, and
/// an index past the end of [values] is skipped rather than thrown on — so a
/// frame built against a longer spec than the value list it is handed renders a
/// short plate instead of crashing.
class PlateTextRow extends StatelessWidget {
  const PlateTextRow({
    super.key,
    required this.spec,
    required this.values,
    this.textStyle,
  });

  final PlateSpec spec;
  final List<String?> values;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
        style: textStyle ?? const TextStyle(color: Color(0xFF000000)),
        child: Directionality(
          textDirection: spec.textDirection,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final g in spec.effectiveTextGroups)
                // Bounds-checked: a group index past the end of the value list
                // is skipped rather than thrown on, so a spec swap that
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
}
