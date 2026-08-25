import 'package:flutter/material.dart';

import 'poster_tokens.dart'; // PosterTokens.accent

/// Which side of the device a callout sits on.
///
/// TODO(P8): annotation_callout.dart, the previous owner of this enum, was
/// removed in the poster demolition; this is a temporary local stand-in
/// until P8 rebuilds the callout content model.
enum CalloutSide { left, right }

/// How a set of callouts leaves and the next set arrives.
enum CalloutMotif {
  /// SWEEP. Exit: slides horizontally off its own side of the screen.
  /// Entry: slides in horizontally from that same side and settles.
  sweep,

  /// TRAPDOOR. Exit: a slot opens beneath the callout and it falls through,
  /// fading. Entry: a slot opens above its resting place and it drops out of it.
  trapdoor,

  /// SIPHON. Exit: the callout collapses along its connector toward the dot,
  /// shrinking to a point on the line. Entry: it is emitted back out of the dot
  /// and expands into place.
  siphon,
}

/// SWEEP — Transform.translate on X, plus Opacity.
class SweepTransition extends StatelessWidget {
  const SweepTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  /// Distance to travel off screen, comfortably past the 360px rail.
  static const double _distance = 520;

  @override
  Widget build(BuildContext context) {
    final double sign = side == CalloutSide.left ? -1 : 1;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        double dx;
        double opacity;
        if (entering) {
          final double eased = Curves.easeOutCubic.transform(t);
          dx = sign * _distance * (1 - eased);
          // Opacity 0 -> 1 over the FIRST 40% only.
          opacity = (t / 0.4).clamp(0.0, 1.0);
        } else {
          final double eased = Curves.easeInCubic.transform(t);
          dx = sign * _distance * eased;
          // Opacity 1 -> 0 over the LAST 40% only.
          opacity = (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
        }
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}

/// TRAPDOOR — a slot that opens, and the text falling through it.
class TrapdoorTransition extends StatelessWidget {
  const TrapdoorTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        double slotFactor;
        double dy;
        double opacity;

        if (entering) {
          // Slot opens over the first 25%.
          slotFactor = (t / 0.25).clamp(0.0, 1.0);
          // Child drops (Y -90 -> 0, fade 0 -> 1) over the middle.
          final double drop =
              ((t - 0.25) / (0.80 - 0.25)).clamp(0.0, 1.0);
          final double eased = Curves.easeOutQuad.transform(drop);
          dy = -90 * (1 - eased);
          opacity = eased;
          // Slot closes over the final 20%.
          if (t > 0.8) {
            slotFactor = (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
          }
        } else {
          // Slot opens over the first 30%.
          slotFactor = (t / 0.3).clamp(0.0, 1.0);
          // Child falls (Y 0 -> +90, fade 1 -> 0) over the remaining 70%.
          final double fall = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
          final double eased = Curves.easeInQuad.transform(fall);
          dy = 90 * eased;
          opacity = 1 - eased;
          // Slot closes back over the final 15%.
          if (t > 0.85) {
            slotFactor = (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
          }
        }

        // Entry aligns the slot to the TOP; exit to the BOTTOM.
        final Alignment slotAlign =
            entering ? Alignment.topCenter : Alignment.bottomCenter;

        return ClipRect(
          child: Stack(
            children: [
              Align(
                alignment: slotAlign,
                child: _TrapdoorSlot(widthFactor: slotFactor),
              ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The horizontal bar the trapdoor child falls through.
class _TrapdoorSlot extends StatelessWidget {
  const _TrapdoorSlot({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor.clamp(0.0, 1.0),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: PosterTokens.accent.withValues(alpha: 0.55),
          boxShadow: const [
            BoxShadow(
              color: PosterTokens.accent,
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// SIPHON — Transform composing scale and translate toward the connector dot.
class SiphonTransition extends StatelessWidget {
  const SiphonTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The dot sits on the device-facing edge: RIGHT for left callouts,
    // LEFT for right callouts.
    final Alignment scaleAlign = side == CalloutSide.left
        ? const Alignment(1, 0.12)
        : const Alignment(-1, 0.12);
    // The X nudge aims toward the dot.
    final double sign = side == CalloutSide.left ? 1 : -1;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        double scale;
        double opacity;
        double dx;

        if (entering) {
          // Scale 0.04 -> 1, opacity 0 -> 1 over the FIRST 55%.
          final double p = (t / 0.55).clamp(0.0, 1.0);
          final double eased = Curves.easeOutBack.transform(p);
          scale = (0.04 + (1 - 0.04) * eased).clamp(0.0, double.infinity);
          opacity = p.clamp(0.0, 1.0);
          // X nudge ∓18 -> 0.
          dx = (-sign * 18) * (1 - eased);
        } else {
          // Scale 1 -> 0.04, opacity 1 -> 0 over the LAST 55%.
          final double p = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
          final double eased = Curves.easeInBack.transform(p);
          scale = (1 - (1 - 0.04) * eased).clamp(0.0, double.infinity);
          opacity = (1 - p).clamp(0.0, 1.0);
          // X nudge 0 -> ±18 toward the dot.
          dx = (sign * 18) * eased;
        }

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            alignment: scaleAlign,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}

/// Dispatcher so callers never switch on [CalloutMotif] themselves.
class CalloutTransition extends StatelessWidget {
  const CalloutTransition({
    super.key,
    required this.motif,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final CalloutMotif motif;
  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (motif) {
      CalloutMotif.sweep => SweepTransition(
          animation: animation,
          entering: entering,
          side: side,
          child: child,
        ),
      CalloutMotif.trapdoor => TrapdoorTransition(
          animation: animation,
          entering: entering,
          side: side,
          child: child,
        ),
      CalloutMotif.siphon => SiphonTransition(
          animation: animation,
          entering: entering,
          side: side,
          child: child,
        ),
    };
  }
}
