import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';

/// The hero slot the editable plate sits in: a soft, recessed panel that keeps
/// the plate at its own aspect ratio however wide the window gets.
///
/// One copy of the near-identical private stage `palestine_plate/example` and
/// `yemen_plate/example` each carried; neither knew anything about its country.
class PlateStage extends StatelessWidget {
  const PlateStage({super.key, required this.spec, required this.child});

  final PlateSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: ConstrainedBox(
          // A two-line or motorcycle plate is nearly square; without a ceiling
          // it would grow to fill a desktop window and dwarf everything under
          // it.
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 260),
          child: AspectRatio(aspectRatio: spec.canvasWidth / spec.canvasHeight, child: child),
        ),
      ),
    );
  }
}
