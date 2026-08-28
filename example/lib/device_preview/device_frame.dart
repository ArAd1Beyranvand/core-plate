// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_config.dart';
import 'device_painters.dart';
import 'pixel_dissolve.dart';
import 'laptop_deck.dart';
import 'device_transition.dart';

/// A physical-feeling device shell that morphs between mobile, tablet and
/// desktop while its content fades out, stays hidden, and fades back in.
///
/// The laptop deck is a real tilted plane: it unfolds out of the body as part
/// of the same morph.
class DeviceFrame extends StatefulWidget {
  const DeviceFrame({
    super.key,
    required this.device,
    required this.builder,
    this.configResolver,
    this.durations = const DeviceTransitionDurations(),
    this.perspective = 900,
    this.hingeAngle = 150,
    this.scale,
    this.curve = Curves.easeInOutCubic,
    this.fadeCurve = Curves.easeInOut,
    this.onPhaseChanged,
    this.onContentSwap,
    this.deckPressedKey,
    this.onDeckKey,
  });

  /// Target form factor. Changing it starts the three-phase transition.
  final DeviceType device;

  /// Builds the page shown on the glass for a given device config.
  final Widget Function(BuildContext context, DeviceConfig config) builder;

  /// Override the built-in presets.
  final DeviceConfig Function(DeviceType type)? configResolver;

  final DeviceTransitionDurations durations;

  /// Viewer distance used to tilt the laptop deck and swing the lid.
  final double perspective;

  /// Hinge angle of the open laptop, in degrees: 0 is shut, 150 is the rest
  /// position of a laptop on a desk.
  final double hingeAngle;

  /// Fixed scale; null fits the frame to its constraints.
  final double? scale;

  final Curve curve;
  final Curve fadeCurve;
  final ValueChanged<DeviceTransitionPhase>? onPhaseChanged;

  /// Fired once per transition the instant content opacity reaches zero — i.e.
  /// as the frame morph begins, not after it. Opacity stays pinned at zero for
  /// the whole morph, so this is the earliest safe moment to swap the page's
  /// backing state (e.g. a plate's bloc) without the incoming content being
  /// seen crossing the outgoing one.
  final VoidCallback? onContentSwap;

  /// Label of a laptop key to render as held down.
  final String? deckPressedKey;

  /// Called with the tapped laptop key's reported label.
  final ValueChanged<String>? onDeckKey;

  @override
  State<DeviceFrame> createState() => _DeviceFrameState();
}

class _DeviceFrameState extends State<DeviceFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late DeviceConfig _from;
  late DeviceConfig _to;

  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;
  late Animation<double> _morphRaw;

  /// How much of the deck is revealed by the pixel dissolve: 1 = fully present,
  /// 0 = fully dissolved away. Closing folds the deck shut onto the screen then
  /// runs this 1 → 0; opening runs it 0 → 1 (still shut) once the screen has
  /// morphed, then swings the deck open.
  double _deckReveal = 1;

  /// Scales the deck's depth: it grows out of, and retracts into, the body in
  /// its own beat, after the body has finished resizing.
  double _deckT = 1;

  /// Live tilt of the deck, in degrees from the screen plane: the deck's rest
  /// position (open) is `180 - hingeAngle`, and 180° is folded flat shut onto
  /// the screen. Animated during the fold/unfold beats.
  late double _deckAngle = 180 - widget.hingeAngle;

  /// Bumped every animating tick so the pixel dissolve's wavefront reseeds per
  /// frame, giving the fizzing edge instead of a clean sweep.
  int _dissolveSeed = 0;

  DeviceTransitionPhase _phase = DeviceTransitionPhase.idle;

  /// False while a started transition still owes an [onContentSwap]; true once
  /// it has fired (or when idle). Reset when a new device arrives.
  bool _contentSwapped = true;

  DeviceConfig _resolve(DeviceType type) =>
      widget.configResolver?.call(type) ?? DevicePresets.of(type);

  @override
  void initState() {
    super.initState();
    _from = _to = _resolve(widget.device);
    _controller = AnimationController(vsync: this, duration: widget.durations.total)
      ..addListener(_onTick);
    _buildIntervals();
    _controller.value = 1;
  }

  /// Splits the one controller into the three phases, so the timings stay
  /// declarative and configurable.
  void _buildIntervals() {
    final d = widget.durations;
    final total = d.total.inMicroseconds.toDouble();
    double at(Duration x) => x.inMicroseconds / total;

    final outEnd = at(d.contentFadeOut);
    final morphStart = outEnd;
    final morphEnd = morphStart + at(d.frameTransform);
    final inStart = morphEnd + at(d.blankHold);

    _fadeOut = CurvedAnimation(
        parent: _controller, curve: Interval(0, outEnd, curve: widget.fadeCurve));
    _fadeIn = CurvedAnimation(
        parent: _controller, curve: Interval(inStart, 1, curve: widget.fadeCurve));
    _morphRaw =
        CurvedAnimation(parent: _controller, curve: Interval(morphStart, morphEnd));
  }

  void _onTick() {
    // The outgoing content is fully transparent once _fadeOut saturates, and it
    // stays that way for the whole morph — so this first invisible frame is the
    // moment to hand the page's content over to the incoming device.
    if (!_contentSwapped && _fadeOut.value >= 1) {
      _contentSwapped = true;
      widget.onContentSwap?.call();
    }
    // Reseed the dissolve wavefront while a dissolve is mid-run, so its edge
    // fizzes frame to frame.
    if (_deckReveal > 0.001 && _deckReveal < 0.999) _dissolveSeed++;
    final next = _phaseFor();
    if (next != _phase) {
      _phase = next;
      widget.onPhaseChanged?.call(next);
    }
    setState(() {});
  }

  DeviceTransitionPhase _phaseFor() {
    if (!_controller.isAnimating) return DeviceTransitionPhase.idle;
    if (_fadeOut.value < 1) return DeviceTransitionPhase.contentFadeOut;
    if (_fadeIn.value > 0) return DeviceTransitionPhase.contentFadeIn;
    return DeviceTransitionPhase.frameTransform;
  }

  @override
  void didUpdateWidget(covariant DeviceFrame old) {
    super.didUpdateWidget(old);
    if (widget.durations.total != old.durations.total) {
      _controller.duration = widget.durations.total;
      _buildIntervals();
    }
    if (widget.device != old.device) {
      // Whatever is on screen becomes the new starting point, so an
      // interrupted transition never snaps.
      _from = _currentConfig;
      _to = _resolve(widget.device);
      _contentSwapped = false;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  /// Morph progress and deck choreography. The laptop deck now physically folds
  /// rather than sliding: closing swings it shut onto the screen, glitch-
  /// dissolves it, then resizes the body; opening resizes first, glitches the
  /// shut deck back into being, then swings it open. The three beats stay
  /// strictly sequential so the body never resizes while the deck is moving.
  double get _morphT {
    final mr = _morphRaw.value;
    final wasLaptop = _from.type == DeviceType.desktop;
    final willBeLaptop = _to.type == DeviceType.desktop;

    // Rest tilt (open) vs. folded flat shut onto the screen.
    final openAngle = 180 - widget.hingeAngle;
    const shutAngle = 180.0;
    double angle(double t) => openAngle + (shutAngle - openAngle) * t;

    if (wasLaptop && !willBeLaptop) {
      // OUTRO: fold shut → pixel-dissolve out → resize.
      final fold = Curves.easeInOut.transform((mr / 0.34).clamp(0.0, 1.0));
      _deckAngle = angle(fold);
      // Linear so the blocks vanish at a steady rate across the ~0.4s beat.
      _deckReveal = 1 - ((mr - 0.34) / 0.28).clamp(0.0, 1.0);
      _deckT =
          1 - Curves.easeInOut.transform(((mr - 0.62) / 0.38).clamp(0.0, 1.0));
      return widget.curve.transform(((mr - 0.62) / 0.38).clamp(0.0, 1.0));
    }
    if (!wasLaptop && willBeLaptop) {
      // INTRO: resize → pixel-dissolve the shut deck in → swing open.
      final body = widget.curve.transform((mr / 0.38).clamp(0.0, 1.0));
      _deckT = 1;
      _deckReveal = ((mr - 0.38) / 0.28).clamp(0.0, 1.0);
      final open = Curves.easeInOut.transform(((mr - 0.66) / 0.34).clamp(0.0, 1.0));
      _deckAngle = angle(1 - open);
      return body;
    }

    _deckReveal = 1;
    _deckT = 1;
    _deckAngle = openAngle;
    return widget.curve.transform(mr);
  }

  DeviceConfig get _currentConfig => DeviceConfig.lerp(_from, _to, _morphT);

  /// 1 → 0 over the fade-out, pinned at 0 through the morph, 0 → 1 over the
  /// fade-in: the plate is never visible while the geometry is moving.
  double get _contentOpacity =>
      _fadeIn.value > 0 ? _fadeIn.value : 1 - _fadeOut.value;

  /// The old layout stays mounted until the morph's midpoint; after it, the
  /// target layout is built and faded in.
  DeviceConfig get _contentConfig => _morphRaw.value < 0.5 ? _from : _to;

  @override
  Widget build(BuildContext context) {
    final config = _currentConfig;
    final total = config.totalSize(widget.perspective);
    final body = config.bodySize;
    final hasDeck = config.deck.depth > 0.5;
    // Laptops must fit their full projected height (body + deck) so the
    // keyboard isn't clipped; other devices have no deck, so this is just
    // their body height.
    final fitHeight = hasDeck ? total.height : body.height;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fit =
              widget.scale ?? _fitScale(constraints, total.width, fitHeight);
          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: total.width * fit,
              height: fitHeight * fit,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: SizedBox(
                  width: total.width * fit,
                  height: total.height * fit,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: total.width,
                      height: total.height,
                      child: _buildDevice(context, config),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _fitScale(BoxConstraints c, double w, double h) {
    final maxW = c.hasBoundedWidth ? c.maxWidth : w;
    final maxH = c.hasBoundedHeight ? c.maxHeight : h;
    return ((maxW / w) < (maxH / h) ? maxW / w : maxH / h).clamp(0.05, 1.0);
  }

  Widget _buildDevice(BuildContext context, DeviceConfig config) {
    final body = config.bodySize;
    final screen = config.screenSize;
    final opacity = _contentOpacity;
    final deck = config.deck.scaledDepth(_deckT);
    // Live fold angle: 180° - hinge when open (rest), 180° when folded shut
    // flat onto the screen. Driven by the fold/unfold beats in [_morphT].
    final deckAngle = _deckAngle;
    // The keyboard's own depth is shallower than the screen, so a lid folded at
    // that depth wouldn't cover it. Once past edge-on (where only the plain back
    // face shows) grow the depth to at least the body height, so the shut deck
    // blankets the whole screen for the dissolve.
    final coverT = ((deckAngle - 90) / 90).clamp(0.0, 1.0);
    final renderDepth =
        deck.depth + (math.max(deck.depth, body.height) - deck.depth) * coverT;
    final projected = deck.projectedHeightAt(deckAngle, widget.perspective);
    // cross-fade the faces through edge-on so neither pops in or out.
    const band = 42.0;
    final present = deck.opacity * (deck.depth / 26).clamp(0.0, 1.0);
    final frontOpacity = ((90 - deckAngle) / band).clamp(0.0, 1.0) * present;
    final backOpacity = ((deckAngle - 90) / band).clamp(0.0, 1.0) * present;

    // folded past edge-on the deck sweeps up in FRONT of the screen
    final deckOnTop = deckAngle > 90;
    final deckLayer = <Widget>[
      if (deck.depth > 0.5)
          Positioned(
            top: body.height - 1, // hinged on the screen's bottom edge
            left: 0,
            width: body.width,
            height: projected < 0.5 ? 0.5 : projected,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: renderDepth,
              maxHeight: renderDepth,
              child: Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 1 / widget.perspective)
                  ..rotateX(-deckAngle * 3.1415926535 / 180),
                child: SizedBox(
                  width: body.width,
                  height: renderDepth,
                  // The chassis rim sits on top of, and outside, the dissolve:
                  // it reads as opaque body from the first intro frame, rather
                  // than waiting on the pixel-reveal to glitch it into view.
                  child: Stack(
                    children: [
                      // The dissolve paints square cover blocks across the full
                      // bounds, so it must be clipped to the deck's own rounded
                      // bottom corners — unclipped it squares them off for the
                      // whole fold/unfold beat.
                      ClipRRect(
                        borderRadius: laptopEdgeRadius,
                        child: PixelDissolve(
                          progress: _deckReveal,
                          seed: _dissolveSeed,
                          // Blocks that haven't revealed read as the blank screen
                          // behind the deck.
                          coverColor: const Color(0xFF07080A),
                          child: LaptopDeck(
                            frontOpacity: frontOpacity,
                            backOpacity: backOpacity,
                            pressedKey: widget.deckPressedKey,
                            onKey: widget.onDeckKey,
                          ),
                        ),
                      ),
                      const Positioned.fill(child: LaptopChassisEdge()),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!deckOnTop) ...deckLayer,
        SizedBox(
          width: body.width,
          height: body.height,
          child: CustomPaint(
            painter: DeviceBodyPainter(config: config),
            foregroundPainter: DeviceHardwarePainter(config: config),
            isComplex: true,
            willChange: _controller.isAnimating,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: config.bezel.left,
                  top: config.bezel.top,
                  width: screen.width,
                  height: screen.height,
                  child: ClipPath(
                    clipper: DeviceScreenClipper(config: config),
                    // The blank screen behind the content: while the frame
                    // morphs, this is all that shows.
                    child: ColoredBox(
                      color: const Color(0xFF07080A),
                      child: opacity <= 0.001
                          ? const SizedBox.expand()
                          : Opacity(
                              opacity: opacity.clamp(0.0, 1.0),
                              child: _ScreenContent(
                                config: _contentConfig,
                                builder: widget.builder,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (deckOnTop) ...deckLayer,
      ],
    );
  }
}

/// Lays the page out at the target device's logical size and scales it into
/// the current glass, so text and the plate never reflow mid-morph.
class _ScreenContent extends StatelessWidget {
  const _ScreenContent({required this.config, required this.builder});

  final DeviceConfig config;
  final Widget Function(BuildContext, DeviceConfig) builder;

  @override
  Widget build(BuildContext context) {
    final logical = config.screenSize;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: logical.width,
        height: logical.height,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: logical,
            padding: EdgeInsets.only(
              top: config.notchSize.height,
              bottom: config.homeIndicatorWidth > 0 ? 20 : 0,
            ),
          ),
          child: RepaintBoundary(child: builder(context, config)),
        ),
      ),
    );
  }
}
