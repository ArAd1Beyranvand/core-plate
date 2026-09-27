import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_spec.dart';

/// A character chooser that never chooses: for `PlateMode.display`, where
/// `PlateCanvas.onChooseCharacter` is required but is never called.
Future<String?> noCharacterChooser(PlateAlphabet alphabet) async => null;

/// Plain-text rendering of a plate: each effective text group rendered through
/// its slots' alphabets, in the plate's reading direction. The shared body of
/// [PlateTextView] and `PlateText` from `core_plate_bloc`.
///
/// Groups with no non-empty value are omitted. Indices past the end of [values]
/// are skipped, so a spec swap cannot crash a frame built against the longer one.
class PlateTextRow extends StatelessWidget {
  const PlateTextRow({super.key, required this.spec, required this.values, this.textStyle});

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
            if (g.indices.any((i) => i < values.length && (values[i] ?? '').isNotEmpty))
              Text(spec.renderGroup(g, values)),
        ],
      ),
    ),
  );
}
