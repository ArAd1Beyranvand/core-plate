import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bicycle_plate/bicycle_plate_number.dart';
import '../bloc/plate_card_bloc.dart';
import '../car_plate/car_plate_number.dart';
import '../model/plate_number.dart';
import '../tools.dart';

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
          return emptyPlate ??
              const Text(
                'Default Widget for Empty Plate Value',
                style: TextStyle(fontSize: 18),
              );
        }
        if (state.plateType == PlateType.irCar) {
          return const IrCarShow();
        }
        if (state.plateType == PlateType.irBicycle) {
          return const IrBicycleShow();
        }
        return const Placeholder();
      },
    );
  }
}

/// The read-only car plate: the real plate face in [PlateMode.display], driven
/// off the ambient [PlateCardBloc].
class IrCarShow extends StatelessWidget {
  const IrCarShow({super.key});

  @override
  Widget build(BuildContext context) {
    return const CarPlateNumber(mode: PlateMode.display);
  }
}

/// The read-only bicycle plate: the real plate face in [PlateMode.display],
/// driven off the ambient [PlateCardBloc].
class IrBicycleShow extends StatelessWidget {
  const IrBicycleShow({super.key});

  @override
  Widget build(BuildContext context) {
    return const BicyclePlateNumber(mode: PlateMode.display);
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
          return emptyPlate ??
              const Text(
                'Default Widget for Empty Plate Value',
                style: TextStyle(fontSize: 18),
              );
        }
        if (state.plateType == PlateType.irCar) {
          return IrCarText(
            values: state.plateNumber.values,
            textStyle: textStyle,
          );
        }
        if (state.plateType == PlateType.irBicycle) {
          return IrBicycleText(
            values: state.plateNumber.values,
            textStyle: textStyle,
          );
        }
        return const Placeholder();
      },
    );
  }
}

class IrCarText extends StatelessWidget {
  const IrCarText({super.key, required this.values, this.textStyle});

  final List values;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: textStyle ?? const TextStyle(color: Colors.black),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (values[7] != null || values[6] != null)
              Text('IR ${values[6] ?? ""}${values[7] ?? ""}'),
            Text('${values[3] ?? ""}${values[4] ?? ""}${values[5] ?? ""}'),
            Text(values[2] ?? ""),
            Text('${values[0] ?? ""}${values[1] ?? ""}', style: textStyle),
          ],
        ),
      ),
    );
  }
}

class IrBicycleText extends StatelessWidget {
  const IrBicycleText({super.key, this.textStyle, required this.values});

  final TextStyle? textStyle;
  final List values;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: textStyle ?? const TextStyle(color: Colors.black),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List<Text>.generate(
            8,
            (index) => Text(values[7 - index] ?? ""),
          ),
        ),
      ),
    );
  }
}
