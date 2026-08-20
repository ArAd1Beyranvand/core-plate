import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_number/plate_number.dart';

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
    @Deprecated('Use inputSource') this.letterInputMode,
    this.inputSource,
    this.onActiveSlotChanged,
    this.controller,
    this.showBackdrop = false,
    this.plateWidthFactor = 0.62,
  });

  final PlateSpec spec;
  final PlateMode mode;

  /// Lets a host drive character entry from outside the plate (e.g. a custom
  /// on-screen keypad). Forwarded straight to [PlateCanvas].
  final PlateInputController? controller;

  /// How the car plate letter is entered. Null lets the plate resolve the
  /// platform default; pass [LetterInputMode.hostKeypad] when an app-supplied
  /// pad (e.g. the laptop deck's letter keys) feeds the letter in.
  @Deprecated('Use inputSource')
  final LetterInputMode? letterInputMode;

  /// How characters get into the plate. Null lets the plate resolve the
  /// platform default; pass [PlateInputSource.host] when an app-supplied pad
  /// (e.g. the laptop deck's letter keys or the tablet's [PlateKeypad]) feeds
  /// characters in. Forwarded straight to [PlateCanvas].
  final PlateInputSource? inputSource;

  /// Fires when the focused plate slot changes, reporting the active slot —
  /// including its alphabet, not just its position — or null when focus leaves
  /// the plate. Forwarded straight to [PlateCanvas].
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

  /// Fraction of the available width the plate itself occupies. The plate's
  /// own FittedBox would otherwise fill the whole glass.
  final double plateWidthFactor;

  @override
  Widget build(BuildContext context) {
    final child = _PlateDisplayBody(
      mode: mode,
      spec: spec,
      keyboard: keyboard,
      showBackdrop: showBackdrop,
      plateWidthFactor: plateWidthFactor,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      letterInputMode: letterInputMode,
      inputSource: inputSource,
      onActiveSlotChanged: onActiveSlotChanged,
      controller: controller,
    );
    if (bloc != null) {
      return BlocProvider.value(value: bloc!, child: child);
    }
    return BlocProvider(
      create: (_) => PlateCardBloc(spec),
      child: child,
    );
  }
}

class _PlateDisplayBody extends StatelessWidget {
  const _PlateDisplayBody({
    required this.mode,
    required this.spec,
    required this.keyboard,
    required this.showBackdrop,
    required this.plateWidthFactor,
    required this.activeColor,
    required this.inactiveColor,
    required this.letterInputMode,
    required this.inputSource,
    required this.onActiveSlotChanged,
    required this.controller,
  });

  final PlateMode mode;
  final PlateSpec spec;
  final Widget? keyboard;
  final bool showBackdrop;
  final double plateWidthFactor;
  final Color? activeColor;
  final Color? inactiveColor;
  final LetterInputMode? letterInputMode;
  final PlateInputSource? inputSource;
  final ValueChanged<PlateSlot?>? onActiveSlotChanged;
  final PlateInputController? controller;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlateCardBloc>();

    final inputSurface = _PlateInputSurface(
      spec: spec,
      plateWidthFactor: plateWidthFactor,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      letterInputMode: letterInputMode,
      inputSource: inputSource,
      onActiveSlotChanged: onActiveSlotChanged,
      controller: controller,
    );

    Widget body;
    if (mode == PlateMode.display) {
      body = Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Center(child: inputSurface)),
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
      body = keyboard == null
          ? inputSurface
          : Column(
              children: [
                Expanded(child: inputSurface),
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
}

/// Wraps the plate in a [PlateThemeScope] that overrides ONLY the input-field
/// underline colours; every other plate token stays standard.
class _PlateInputSurface extends StatelessWidget {
  const _PlateInputSurface({
    required this.spec,
    required this.plateWidthFactor,
    required this.activeColor,
    required this.inactiveColor,
    required this.letterInputMode,
    required this.inputSource,
    required this.onActiveSlotChanged,
    required this.controller,
  });

  final PlateSpec spec;
  final double plateWidthFactor;
  final Color? activeColor;
  final Color? inactiveColor;
  final LetterInputMode? letterInputMode;
  final PlateInputSource? inputSource;
  final ValueChanged<PlateSlot?>? onActiveSlotChanged;
  final PlateInputController? controller;

  @override
  Widget build(BuildContext context) {
    final base = PlateTheme.standard();
    final theme = base.copyWith(
      activeColor: activeColor ?? base.activeColor,
      inactiveColor: inactiveColor ?? base.inactiveColor,
    );

    final plate = PlateCanvas(
      spec: spec,
      letterInputMode: letterInputMode,
      inputSource: inputSource,
      onActiveSlotChanged: onActiveSlotChanged,
      controller: controller,
    );

    return Center(
      child: FractionallySizedBox(
        widthFactor: plateWidthFactor,
        child: PlateThemeScope(theme: theme, child: plate),
      ),
    );
  }
}
