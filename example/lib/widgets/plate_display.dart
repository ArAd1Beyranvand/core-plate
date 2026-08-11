import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/bicycle_plate/index.dart';
import 'package:plate_number/car_plate/index.dart';
import 'package:plate_number/widgets/show_plate.dart';

enum ShowcaseMode { input, display }

class PlateDisplay extends StatelessWidget {
  const PlateDisplay({
    super.key,
    required this.plateType,
    required this.mode,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.spacingScale,
  });

  final PlateType plateType;
  final ShowcaseMode mode;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final double? spacingScale;

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = spacingScale ?? 6;
    final effectiveActive = activeColor ?? Colors.blueAccent;
    final effectiveInactive = inactiveColor ?? Colors.blueGrey;
    final effectiveBg = backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A2E)
            : Colors.white);

    return BlocProvider(
      create: (_) => PlateCardBloc(plateType),
      child: Builder(
        builder: (context) {
          final bloc = context.read<PlateCardBloc>();

          if (mode == ShowcaseMode.display) {
            return Padding(
              padding: EdgeInsets.all(effectiveSpacing * 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: _buildInputWidget(
                        effectiveActive,
                        effectiveInactive,
                        effectiveBg,
                        effectiveSpacing,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ShowPlate(
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => bloc.add(RemovePlateCard()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            );
          }

          return _buildInputWidget(
            effectiveActive,
            effectiveInactive,
            effectiveBg,
            effectiveSpacing,
          );
        },
      ),
    );
  }

  Widget _buildInputWidget(
    Color active,
    Color inactive,
    Color bg,
    double spacing,
  ) {
    switch (plateType) {
      case PlateType.irCar:
        return CarPlateNumber(
          activeColor: active,
          inactiveColor: inactive,
          backgroundColor: bg,
          spacingScale: spacing,
        );
      case PlateType.irBicycle:
        return BicyclePlateNumber(
          activeColor: active,
          inactiveColor: inactive,
          backgroundColor: bg,
          spacingScale: spacing,
        );
    }
  }
}
