import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/plate_number.dart';
import 'package:plate_number/model/plate_spec.dart';
import 'package:plate_number/widgets/plate_canvas.dart';

class PlateDisplay extends StatelessWidget {
  const PlateDisplay({
    super.key,
    required this.spec,
    required this.mode,
    this.activeColor,
    this.inactiveColor,
    this.keyboard,
    this.bloc,
    this.letterInputMode,
    this.onActiveSlotChanged,
  });

  final PlateSpec spec;
  final PlateMode mode;

  /// How the car plate letter is entered. Null lets the plate resolve the
  /// platform default; pass [LetterInputMode.hostKeypad] when an app-supplied
  /// pad (e.g. the laptop deck's letter keys) feeds the letter in.
  final LetterInputMode? letterInputMode;

  /// Fires when the focused plate slot changes, reporting the plate index that
  /// now holds focus (2 is the letter slot) or null when focus leaves the
  /// plate. Forwarded to CarPlateNumber; ignored by the bicycle plate.
  final ValueChanged<int?>? onActiveSlotChanged;

  /// An externally-owned bloc to drive the plate. When null, this widget
  /// creates and owns its own, keeping today's self-contained behaviour.
  final PlateCardBloc? bloc;

  /// Optional fake soft keyboard rendered flush at the bottom of the screen,
  /// below the plate. Null (default) keeps today's behaviour.
  final Widget? keyboard;

  /// Accent for a completed input-field underline. The plate face itself is
  /// always white / black / blue by definition.
  final Color? activeColor;

  /// Accent for an empty/in-progress input-field underline.
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final child = Builder(builder: _buildContent);
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: child);
    }
    return BlocProvider(
      create: (_) => PlateCardBloc(spec),
      child: child,
    );
  }

  Widget _buildContent(BuildContext context) {
    final bloc = context.read<PlateCardBloc>();

    if (mode == PlateMode.display) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Center(child: _buildInputWidget())),
            const SizedBox(height: 16),
            const ShowPlate(),
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

    final content = _buildInputWidget();
    if (keyboard == null) {
      return content;
    }
    return Column(
      children: [
        Expanded(child: content),
        keyboard!,
      ],
    );
  }

  /// Wraps the plate in a [PlateThemeScope] that overrides ONLY the input-field
  /// underline colours; every other plate token stays standard.
  Widget _buildInputWidget() {
    final base = PlateTheme.standard();
    final theme = base.copyWith(
      activeColor: activeColor ?? base.activeColor,
      inactiveColor: inactiveColor ?? base.inactiveColor,
    );

    final plate = PlateCanvas(
      spec: spec,
      letterInputMode: letterInputMode,
      onActiveSlotChanged: onActiveSlotChanged,
    );

    return PlateThemeScope(theme: theme, child: plate);
  }
}
