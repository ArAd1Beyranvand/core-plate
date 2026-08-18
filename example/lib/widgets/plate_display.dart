import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/plate_number.dart';
import 'package:plate_number/widgets/plate_canvas.dart';

import '../poster/plate_backdrop.dart';

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
    this.controller,
    this.showBackdrop = false,
  });

  final PlateSpec spec;
  final PlateMode mode;

  /// Lets a host drive character entry from outside the plate (e.g. a custom
  /// on-screen keypad). Forwarded straight to [PlateCanvas].
  final PlateInputController? controller;

  /// How the car plate letter is entered. Null lets the plate resolve the
  /// platform default; pass [LetterInputMode.hostKeypad] when an app-supplied
  /// pad (e.g. the laptop deck's letter keys) feeds the letter in.
  final LetterInputMode? letterInputMode;

  /// Fires when the focused plate slot changes, reporting the active slot —
  /// including its alphabet, not just its position — or null when focus leaves
  /// the plate. Forwarded to CarPlateNumber; ignored by the bicycle plate.
  final ValueChanged<PlateSlot?>? onActiveSlotChanged;

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

  /// Paints an ambient [PlateBackdrop] behind the plate content. Off by
  /// default, so existing call sites keep today's plain-glass look.
  final bool showBackdrop;

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

    Widget body;
    if (mode == PlateMode.display) {
      body = Padding(
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
    } else {
      final content = _buildInputWidget();
      body = keyboard == null
          ? content
          : Column(
              children: [
                Expanded(child: content),
                keyboard!,
              ],
            );
    }

    if (!showBackdrop) return body;
    return Stack(
      fit: StackFit.expand,
      children: [const Positioned.fill(child: PlateBackdrop()), body],
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
      controller: controller,
    );

    return PlateThemeScope(theme: theme, child: plate);
  }
}
