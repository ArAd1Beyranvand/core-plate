import 'package:flutter/widgets.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_spec.dart';

/// No-op character chooser for display mode.
Future<String?> noCharacterChooser(PlateAlphabet alphabet) async => null;

/// Text rendering of a plate: groups rendered through their alphabets.
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
            if (g.indices.any(
              (i) => i < values.length && (values[i] ?? '').isNotEmpty,
            ))
              Text(spec.renderGroup(g, values)),
        ],
      ),
    ),
  );
}
