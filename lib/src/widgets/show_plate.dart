import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../model/plate_number.dart';
import 'plate_canvas.dart';

/// Read-only plate view. Renders the real graphical plate (pixel-identical to
/// the input widget) driven straight off [PlateCardBloc] state, in
/// [PlateMode.display].
///
/// For a bare text rendering of the plate string, use [PlateText] instead.
class ShowPlate extends StatelessWidget {
  const ShowPlate({super.key, this.emptyPlate});

  final Widget? emptyPlate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        if (state.plateNumber.isEmpty()) {
          return _EmptyPlate(emptyPlate);
        }
        return PlateCanvas(spec: state.spec, mode: PlateMode.display);
      },
    );
  }
}

/// The shared fallback shown by [ShowPlate] and [PlateText] when the plate has
/// no value: the caller's [replacement] if given, else a plain placeholder.
///
/// "Default Widget for Empty Plate Value" is developer-facing copy sitting in a
/// shipping default; kept verbatim here because changing it is a product call.
class _EmptyPlate extends StatelessWidget {
  const _EmptyPlate(this.replacement);

  final Widget? replacement;

  @override
  Widget build(BuildContext context) {
    return replacement ??
        const Text(
          'Default Widget for Empty Plate Value',
          style: TextStyle(fontSize: 18),
        );
  }
}

/// Plain-text rendering of the plate string, for callers who want just the
/// characters rather than the graphical plate. Preserves the original
/// [ShowPlate] behaviour.
class PlateText extends StatelessWidget {
  const PlateText({super.key, this.emptyPlate, this.textStyle});

  final Widget? emptyPlate;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        if (state.plateNumber.isEmpty()) {
          return _EmptyPlate(emptyPlate);
        }
        final spec = state.spec;
        final values = state.plateNumber.values;
        return DefaultTextStyle(
          style: textStyle ?? const TextStyle(color: Colors.black),
          child: Directionality(
            textDirection: spec.textDirection,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final g in spec.effectiveTextGroups)
                  if (g.indices.any((i) => (values[i] ?? '').isNotEmpty))
                    Text(spec.renderGroup(g, values)),
              ],
            ),
          ),
        );
      },
    );
  }
}
