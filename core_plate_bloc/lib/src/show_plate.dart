import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'plate_card_bloc.dart';

/// Read-only plate view. Renders the real graphical plate (pixel-identical to
/// the input widget) driven straight off [PlateCardBloc] state, in
/// [PlateMode.display].
///
/// For a bare text rendering of the plate string, use [PlateText] instead.
class ShowPlate extends StatelessWidget {
  const ShowPlate({super.key, this.emptyPlate, this.theme, this.country});

  final Widget? emptyPlate;

  /// The livery to paint, or null to inherit from an ancestor `PlateThemeScope`.
  /// `PlateView` has taken one since 0.4.0; a bloc-shaped host needs it just as
  /// much — without it every plate renders in `PlateTheme.standard()`, which is
  /// wrong for any country whose plate is not black on white.
  final PlateTheme? theme;

  /// The country block to paint, overriding the state spec's own. See
  /// [PlateCanvas.country].
  final PlateCountry? country;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        if (state.plateNumber.isEmpty) {
          return emptyPlate ?? const SizedBox.shrink();
        }
        return PlateCanvas(
          spec: state.spec,
          mode: PlateMode.display,
          theme: theme,
          country: country,
          onChooseCharacter: noCharacterChooser,
        );
      },
    );
  }
}

/// Plain-text rendering of the plate string, for callers who want just the
/// characters rather than the graphical plate. The bloc-driven counterpart of
/// `PlateTextView`.
class PlateText extends StatelessWidget {
  const PlateText({super.key, this.emptyPlate, this.textStyle});

  final Widget? emptyPlate;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        if (state.plateNumber.isEmpty) {
          return emptyPlate ?? const SizedBox.shrink();
        }
        return PlateTextRow(spec: state.spec, values: state.plateNumber.values, textStyle: textStyle);
      },
    );
  }
}
