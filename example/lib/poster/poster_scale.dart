import 'package:flutter/widgets.dart';

/// Responsive tiers from DESIGN_SPEC.md §8.
enum PosterTier { wide, medium, compact }

const double _designWidth = 1920;
const double _designHeight = 1080;

PosterTier _tierFor(Size size) {
  if (size.width >= 1240 && size.height >= 700) return PosterTier.wide;
  if (size.width >= 760) return PosterTier.medium;
  return PosterTier.compact;
}

double _fluidFactorFor(PosterTier tier, Size size) {
  final raw = size.width / _designWidth;
  switch (tier) {
    case PosterTier.wide:
      return raw.clamp(0.52, 1.0);
    case PosterTier.medium:
      return raw.clamp(0.46, 1.0);
    case PosterTier.compact:
      // Fixed step-down: compact never lays the 1920-wide design out
      // directly, so its fluid factor is pinned rather than derived.
      return 0.34;
  }
}

/// Carries the current [tier], fluid scale factor [f] and the stage [size]
/// down to every poster widget, so nothing positions itself with raw
/// design px.
class PosterMetrics extends InheritedWidget {
  const PosterMetrics({
    super.key,
    required this.tier,
    required this.f,
    required this.size,
    required super.child,
  });

  final PosterTier tier;
  final double f;
  final Size size;

  static PosterMetrics of(BuildContext context) {
    final metrics = context.dependOnInheritedWidgetOfExactType<PosterMetrics>();
    assert(metrics != null, 'No PosterMetrics found in context');
    return metrics!;
  }

  /// Converts a design px measured on the 1920×1080 canvas to a real px
  /// under the current fluid factor.
  double px(double designPx) => designPx * f;

  /// The stage's own scale against the design canvas, *unclamped*.
  ///
  /// [f] is clamped so type and card metrics never collapse; the full-bleed
  /// backdrop has the opposite requirement — the road must always span the
  /// stage exactly — so its lengths go through this instead.
  double get stageScale => size.width / _designWidth;

  /// A horizontal design-canvas px as a real px on this stage.
  double sx(double designPx) => designPx / _designWidth * size.width;

  /// A vertical design-canvas px as a real px on this stage.
  double sy(double designPx) => designPx / _designHeight * size.height;

  /// Converts a design-space fractional box (`fx, fy, fw, fh` — each in
  /// `0..1` of the 1920×1080 canvas) to a real [Rect] within [size].
  Rect box(double fx, double fy, double fw, double fh) {
    return Rect.fromLTWH(
      fx * size.width,
      fy * size.height,
      fw * size.width,
      fh * size.height,
    );
  }

  @override
  bool updateShouldNotify(PosterMetrics oldWidget) {
    return tier != oldWidget.tier || f != oldWidget.f || size != oldWidget.size;
  }
}

/// Computes [PosterMetrics] from the incoming layout constraints and scopes
/// it over [child].
class PosterMetricsScope extends StatelessWidget {
  const PosterMetricsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : _designWidth,
          constraints.maxHeight.isFinite ? constraints.maxHeight : _designHeight,
        );
        final tier = _tierFor(size);
        final f = _fluidFactorFor(tier, size);
        return PosterMetrics(tier: tier, f: f, size: size, child: child);
      },
    );
  }
}
