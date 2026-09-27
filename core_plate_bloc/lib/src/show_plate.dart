import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'plate_card_bloc.dart';

/// Read-only graphical plate rendering from [PlateCardBloc] state. For a bare
/// text rendering, use [PlateText] instead.
class ShowPlate extends StatelessWidget {
  const ShowPlate({super.key, this.emptyPlate, this.theme, this.country});

  final Widget? emptyPlate;

  /// The livery to paint, or null to inherit from `PlateThemeScope`. Without it
  /// every plate renders in [PlateTheme.standard()], which is wrong for most
  /// countries.
  final PlateTheme? theme;

  /// The country block to paint, overriding the state spec's. See
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

/// Plain-text plate rendering from [PlateCardBloc], the bloc counterpart of
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
