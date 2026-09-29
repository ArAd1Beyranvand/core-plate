import 'package:flutter/material.dart';

import '../input/plate_controller.dart';
import '../input/plate_input_machine.dart';
import '../model/plate_alphabet.dart';
import '../model/plate_box.dart';
import '../model/plate_country.dart';
import '../model/plate_input_source.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import '../theme/plate_theme.dart';
import '../validators/plate_validator.dart';
import 'country_panel.dart';
import 'plate_frame.dart';
import 'plate_selector.dart';
import 'plate_slot_item.dart';

/// The editable plate for a [PlateSpec], holding characters in a
/// [PlateController] (its own or passed via [controller]). Provides its own
/// [Material], needs no state management, and preserves characters when [spec]
/// changes per [onSpecChange].
class PlateCanvas extends StatefulWidget {
  const PlateCanvas({
    super.key,
    required this.spec,
    this.mode = PlateMode.input,
    this.theme,
    this.country,
    this.inputSource,
    required this.onChooseCharacter,
    this.onActiveIndexChanged,
    this.controller,
    this.validator,
    this.autoValidate = false,
    this.onSpecChange = PlateValuePreservation.byGroupKey,
  });

  final PlateSpec spec;
  final PlateMode mode;
  final PlateTheme? theme;

  /// Override [PlateSpec.country] at render time, like [theme]. Null keeps
  /// [PlateSpec.country].
  final PlateCountry? country;

  final PlateInputSource? inputSource;

  /// Shows a character chooser for a chosen slot; required.
  final Future<String?> Function(PlateAlphabet alphabet) onChooseCharacter;
  final ValueChanged<int?>? onActiveIndexChanged;

  /// Owns the plate's characters and focus. Omit to use a private controller.
  final PlateController? controller;

  /// Rule to judge the plate. Never prevents input.
  final PlateValidator? validator;

  /// When true, canvas validates after every commit. When false (default), read
  /// [PlateController.validation] and validate on your timing.
  final bool autoValidate;

  /// What becomes of entered characters when [spec] is swapped. Defaults to
  /// [PlateValuePreservation.byGroupKey] (keeps matching registers).
  final PlateValuePreservation onSpecChange;

  @override
  State<PlateCanvas> createState() => _PlateCanvasState();
}

class _PlateCanvasState extends State<PlateCanvas> {
  /// Focus and slot navigation; rebuilt when spec changes.
  late PlateInputMachine _machine;

  /// The canvas's writer of record; takes [BuildContext] out of long-lived
  /// closures the machine holds.
  late PlateController _controller;

  /// Whether [_controller] is ours to dispose.
  bool _ownsController = false;

  /// Cached selection theme, rebuilt only when verdict flips.
  ThemeData? _selectionTheme;
  Color? _selectionThemeColor;

  /// Cached face clip.
  _PlateFaceClipper? _faceClipper;

  ThemeData _selectionThemeFor(Color active) {
    final cached = _selectionTheme;
    if (cached != null && _selectionThemeColor == active) return cached;
    _selectionThemeColor = active;
    return _selectionTheme = ThemeData.light().copyWith(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: active.withValues(alpha: 0.3),
        cursorColor: active,
        selectionHandleColor: active,
      ),
    );
  }

  _PlateFaceClipper _faceClipperFor(double border, double radius) {
    final cached = _faceClipper;
    if (cached != null && cached.border == border && cached.radius == radius) {
      return cached;
    }
    return _faceClipper = _PlateFaceClipper(border: border, radius: radius);
  }

  @override
  void initState() {
    super.initState();
    _adoptController();
    _installMachine();
  }

  @override
  void didUpdateWidget(PlateCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This used to react to the controller alone, on the assumption that
    // Flutter hands a spec change a fresh State. It does not, when the host
    // swaps `spec:` on a canvas that keeps its type and position in the tree —
    // an ordinary thing for a host to do — and the machine then holds the
    // previous plate's nodes: wrong slot, or off the end of the list outright.
    if (widget.spec.id != oldWidget.spec.id) {
      // The controller holds the previous plate's values — a different slot
      // count — and migrates itself to the new spec, carrying the characters
      // across as [PlateCanvas.onSpecChange] directs.
      _controller.adoptSpec(widget.spec, preserve: widget.onSpecChange);
      oldWidget.controller?.detach(_machine);
      widget.controller?.detach(_machine);
      _machine.dispose();
      _installMachine();
    } else if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.installValidation(null);
      oldWidget.controller?.detach(_machine);
      widget.controller?.attach(_machine);
      widget.controller?.installValidation(_probeValidation);
      _adoptController(replacing: true);
    }
  }

  @override
  void dispose() {
    widget.controller?.installValidation(null);
    widget.controller?.detach(_machine);
    _machine.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Points [_controller] at the host's controller when it passed one, and at a
  /// private one otherwise.
  ///
  /// [replacing] means a live canvas has just been handed a different
  /// [PlateCanvas.controller]. A private one we stand down for a host-supplied
  /// controller is disposed; the host's own never is — it outlives us, and is
  /// routinely handed straight back on the next build.
  void _adoptController({bool replacing = false}) {
    final host = widget.controller;
    if (host == null) {
      if (replacing && _ownsController) return;
      _controller = PlateController(spec: widget.spec);
      _ownsController = true;
      return;
    }
    if (replacing && identical(_controller, host)) return;
    final stoodDown = replacing && _ownsController ? _controller : null;
    _controller = host;
    _ownsController = false;
    stoodDown?.dispose();
  }

  /// Builds the machine for the current spec and seeded active slot.
  void _installMachine() {
    assert(debugValidateSpec(widget.spec));
    final machine = PlateInputMachine(
      spec: widget.spec,
      inputSource: _resolveInputSource(),
      readValues: () => _controller.values,
      commit: (index, value) => _controller.setAt(index, value),
      onActiveIndexChanged: _reportActiveIndex,
    )..onSheetRequested = _openPicker;
    _machine = machine;
    widget.controller?.attach(machine);
    widget.controller?.installValidation(_probeValidation);
    if (machine.activeIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_machine, machine)) return;
        _reportActiveIndex(machine.activeIndex);
      });
    }
  }

  void _reportActiveIndex(int? index) {
    widget.onActiveIndexChanged?.call(index);
    widget.controller?.notifyActiveSlotChanged();
  }

  PlateEntry _entryFor(List<String?> values) => PlateEntry(
    spec: widget.spec,
    values: values,
    activeIndex: _machine.activeIndex,
  );

  PlateValidation? _probeValidation() {
    final validator = widget.validator;
    if (validator == null) return null;
    return validator.validate(_entryFor(_controller.values));
  }

  /// Publishes verdict after the frame (called from build).
  void _publishVerdict(PlateValidation verdict) {
    final controller = widget.controller;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.reportValidation(verdict);
    });
  }

  PlateInputSource _resolveInputSource() {
    return widget.inputSource ?? defaultInputSource();
  }

  /// Presents the character picker for a chosen slot.
  Future<void> _openPicker(int index) async {
    final slot = widget.spec.slots[index];
    final chosen = await widget.onChooseCharacter(slot.alphabet);
    if (chosen == null) return;
    _controller.setAt(index, chosen);
    final next = widget.spec.nextIndex(index);
    if (next != null) _machine.focusSlot(next);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final country = widget.country ?? spec.country;
    var theme = widget.theme ?? PlateTheme.of(context);
    if (spec.borderWidthRatioOverride != null) {
      theme = theme.copyWith(borderWidthRatio: spec.borderWidthRatioOverride!);
    }
    if (spec.inkOverride != null) {
      // The whole monochrome set, as [PlateSpec.inkOverride] documents: a plate
      // printed in green has a green rim and green rules, not black ones.
      final ink = spec.inkOverride!;
      theme = theme.copyWith(
        ink: ink,
        plateBorder: ink,
        dividerColor: ink,
        activeColor: ink,
      );
    }
    // PlateMode.display renders inert, picker-like slots regardless of the
    // configured source, so force [PlateInputSource.system] there.
    _machine.inputSource = widget.mode == PlateMode.input
        ? _resolveInputSource()
        : PlateInputSource.system;

    // Resolve each slot's behaviour once, here, from the three things that
    // decide it. Every gesture and rendering branch downstream is a switch on
    // this value — nothing re-derives it.
    final behaviors = <SlotBehavior>[
      for (final s in spec.slots)
        resolveSlotBehavior(
          mode: widget.mode,
          input: s.alphabet.input,
          source: _machine.inputSource,
        ),
    ];

    // The plate's face is always white, so its cursor and text-selection
    // colours are pinned to a light Material theme regardless of the host
    // app's brightness. Cached against the one colour it derives from (see
    // [_selectionThemeFor]) and scoped over the whole slot list, instead of
    // each typed slot constructing its own.
    final selectionTheme = _selectionThemeFor(theme.activeColor);

    // NOTE: this build deliberately does NOT watch the plate value.
    //
    // It used to `context.select` the whole [PlateNumber], which meant every
    // change rebuilt this entire subtree — the frame, the clip, the country
    // panel, every rule, label and decal, and all eight slots — to change one
    // character. The frame and each slot now subscribe to just the part they
    // render: [_FrameBinding] is a [ValueListenableBuilder] on
    // `controller.completed`, and [_SlotBinding] a [ValueListenableBuilder] on
    // `controller.slot(index)` — one `ValueListenable<String?>` per position.
    // So a keystroke rebuilds one slot + its mirrors, and the plate's static
    // furniture is built once. A [PlateMirror] echoes one slot's value, so
    // [_MirrorBinding] listens to `controller.slot(mirror.source)` the same
    // way — a keystroke stays local to the slot it lands in and the mirrors
    // pointed at it.
    //
    // [_ValidationBinding] is the one exception, and only under autoValidate:
    // it watches the value through a verdict (a [PlateSelector] that compares
    // by reason), so it rebuilds on a flip between valid and invalid rather
    // than on a keystroke.

    // The rounded white face, so content (e.g. the blue country panel) is
    // clipped to the same corner radius the frame paints instead of poking
    // square corners into the rounded plate. Kept in sync with PlateFrame's
    // own geometry: border thickness and inner radius both derive from the
    // plate height. Taken off the base theme: the alert only recolours the
    // underlines, so geometry cannot shift when a verdict flips.
    final border = theme.borderWidthRatio * spec.canvasHeight;
    final outerRadius = theme.plateRadiusRatio * spec.canvasHeight;
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    final clipper = _faceClipperFor(border, innerRadius);

    // THE FACE IS TWO LAYERS, AND THAT IS THE WHOLE POINT.
    //
    // Every typed slot is a TextField, and EditableText wraps itself in
    // `CompositedTransformTarget`s — real composited layers. A composited layer
    // anywhere beneath a FittedBox forces that FittedBox to stop applying its
    // scale to the canvas and push a TransformLayer instead. That takes the
    // plate out of the vector pass: the face is recorded in plate coordinates
    // and handed to the compositor to scale, which makes it a raster-cache
    // candidate — and the engine takes it, after a few still frames. That is
    // why the plate looks right the moment it appears and softens a beat
    // later, why it churns while anything upstream keeps invalidating the
    // cache, and why the first thing to go is the country flag's emblem, which
    // is only a few device pixels across.
    //
    // So the printed furniture — frame, country panel and flag, rules, labels,
    // decals — gets a FittedBox of its own with no TextField anywhere under it.
    // Nothing in that subtree composites, so its scale stays on the canvas and
    // the flag is drawn as vector at device resolution on every frame it
    // paints. It cannot be dirtied by a keystroke either: the live characters
    // live in the layer above it.
    //
    // [StackFit.passthrough] is what holds the two in register. It hands both
    // layers this canvas's own constraints unchanged, so both FittedBoxes
    // derive the same size, scale and alignment from the same plate-space
    // [SizedBox] — the geometry is identical to the single FittedBox this
    // replaced, and the stack sizes exactly as that one did.
    final artwork = _PlateArtwork(
      spec: spec,
      theme: theme,
      country: country,
      controller: _controller,
      clipper: clipper,
    );

    // The alert. With autoValidate on, the canvas judges the plate itself and
    // paints the completed-field underline in the theme's alert colour — that,
    // and nothing else: no dialog, no exception, and above all no rejected
    // keystroke. With it off the validator is never called from here; a host
    // that wants its own timing reads PlateController.validation.
    //
    // Only the input layer is inside the binding: a verdict flips
    // `activeColor`, which recolours slot underlines and nothing else, so the
    // artwork no longer rebuilds when the plate crosses between valid and
    // invalid.
    final validator = widget.validator;
    final Widget inputs = widget.autoValidate && validator != null
        ? _ValidationBinding(
            controller: _controller,
            validate: (values) => validator.validate(_entryFor(values)),
            onVerdict: _publishVerdict,
            builder: (verdict) => _PlateInputs(
              spec: spec,
              theme: verdict.isValid
                  ? theme
                  : theme.copyWith(activeColor: theme.alertColor),
              behaviors: behaviors,
              machine: _machine,
              controller: _controller,
              mode: widget.mode,
              onPick: _openPicker,
              clipper: clipper,
            ),
          )
        : _PlateInputs(
            spec: spec,
            theme: theme,
            behaviors: behaviors,
            machine: _machine,
            controller: _controller,
            mode: widget.mode,
            onPick: _openPicker,
            clipper: clipper,
          );

    final Widget face = Stack(
      fit: StackFit.passthrough,
      children: [artwork, inputs],
    );

    // Wrap in a Material so the typed slots' TextFields have the Material
    // ancestor they require. Without this a consumer must place PlateCanvas
    // under a Scaffold (or their own Material) or it throws on first build.
    // `type: transparency` adds no ink or surface colour — the plate paints
    // its own white face.
    return Theme(
      data: selectionTheme,
      child: Material(type: MaterialType.transparency, child: face),
    );
  }
}

/// Painted furniture (frame, country panel, rules, labels, decals).
///
/// **No TextField may ever appear in this subtree** — nothing here composites,
/// so the flag is drawn at device resolution, not rasterised and resampled.
/// Static between spec changes except the frame, which follows [_FrameBinding].
class _PlateArtwork extends StatelessWidget {
  const _PlateArtwork({
    required this.spec,
    required this.theme,
    required this.country,
    required this.controller,
    required this.clipper,
  });

  final PlateSpec spec;
  final PlateTheme theme;
  final PlateCountry country;
  final PlateController controller;

  /// Shared clip geometry with [_PlateInputs].
  final _PlateFaceClipper clipper;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: spec.canvasWidth,
        height: spec.canvasHeight,
        child: Directionality(
          textDirection: spec.textDirection,
          child: Stack(
            children: [
              Positioned.fill(
                child: _FrameBinding(theme: theme, controller: controller),
              ),
              Positioned.fill(
                child: ClipRRect(
                  clipper: clipper,
                  child: Stack(
                    children: [
                      if (!spec.noPanel)
                        _Placed(
                          box: spec.panel.box,
                          child: CountryPanel(
                            country: country,
                            theme: theme,
                            panel: spec.panel,
                          ),
                        ),
                      // Under the rules, labels and decals: a band is the field
                      // the ink is printed on, not something printed over them.
                      if (spec.rightBand case final band?)
                        _Placed(
                          box: band.box,
                          child: _Band(band: band),
                        ),
                      if (spec.innerBand case final band?)
                        _Placed(
                          box: band.box,
                          child: _Band(band: band),
                        ),
                      for (final r in spec.rules)
                        _Placed(
                          box: r.box,
                          child: ColoredBox(color: theme.dividerColor),
                        ),
                      for (final l in spec.labels)
                        _Placed(
                          box: l.box,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: l.rotated ? 3 : 0,
                              child: Text(
                                l.text,
                                textAlign: TextAlign.center,
                                style: theme
                                    .glyphStyle(
                                      l.glyphHeight,
                                      l.color ?? theme.ink,
                                    )
                                    .copyWith(height: l.lineHeight),
                              ),
                            ),
                          ),
                        ),
                      for (final d in spec.decals)
                        _Placed(
                          box: d.box,
                          child: Image(image: d.image, fit: BoxFit.contain),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live characters: typed slots and mirrors. TextFields composite here; a
/// keystroke repaints only this layer, not the flag above.
class _PlateInputs extends StatelessWidget {
  const _PlateInputs({
    required this.spec,
    required this.theme,
    required this.behaviors,
    required this.machine,
    required this.controller,
    required this.mode,
    required this.onPick,
    required this.clipper,
  });

  final PlateSpec spec;
  final PlateTheme theme;
  final List<SlotBehavior> behaviors;
  final PlateInputMachine machine;
  final PlateController controller;
  final PlateMode mode;
  final void Function(int index) onPick;
  final _PlateFaceClipper clipper;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: spec.canvasWidth,
        height: spec.canvasHeight,
        child: Directionality(
          textDirection: spec.textDirection,
          child: ClipRRect(
            clipper: clipper,
            child: Stack(
              children: [
                for (var mi = 0; mi < spec.mirrors.length; mi++)
                  _Placed(
                    box: spec.mirrors[mi].box,
                    child:
                        mode == PlateMode.input &&
                            spec.mirrors[mi].editable &&
                            machine.mirrorControllerAt(mi) != null
                        ? Center(
                            child: _EditableMirrorBinding(
                              mirrorIndex: mi,
                              mirror: spec.mirrors[mi],
                              alphabet:
                                  spec.mirrors[mi].alphabet ??
                                  spec.slots[spec.mirrors[mi].source].alphabet,
                              behavior: behaviors[spec.mirrors[mi].source],
                              theme: theme,
                              machine: machine,
                              controller: controller,
                              onCompleted: mode == PlateMode.input
                                  ? () => machine.advanceFrom(
                                      spec.mirrors[mi].source,
                                    )
                                  : null,
                            ),
                          )
                        : _MirrorBinding(
                            mirror: spec.mirrors[mi],
                            alphabet:
                                spec.mirrors[mi].alphabet ??
                                spec.slots[spec.mirrors[mi].source].alphabet,
                            theme: theme,
                            controller: controller,
                          ),
                  ),
                for (var i = 0; i < spec.slots.length; i++)
                  _Placed(
                    box: spec.slots[i].box,
                    child: Center(
                      child: _SlotBinding(
                        index: i,
                        slot: spec.slots[i],
                        behavior: behaviors[i],
                        theme: theme,
                        machine: machine,
                        controller: controller,
                        onCompleted: mode == PlateMode.input
                            ? () => machine.advanceFrom(i)
                            : null,
                        onPressed: behaviors[i] == SlotBehavior.sheet
                            ? () => onPick(i)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subscribed to verdict, not value, so rebuilds only on valid/invalid flip.
class _ValidationBinding extends StatelessWidget {
  const _ValidationBinding({
    required this.controller,
    required this.validate,
    required this.onVerdict,
    required this.builder,
  });

  final PlateController controller;
  final PlateValidation Function(List<String?> values) validate;
  final ValueChanged<PlateValidation> onVerdict;
  final Widget Function(PlateValidation verdict) builder;

  @override
  Widget build(BuildContext context) {
    return PlateSelector<PlateValidation>(
      controller: controller,
      selector: (c) => validate(c.values),
      builder: (context, verdict) => _VerdictListener(
        verdict: verdict,
        onVerdict: onVerdict,
        child: builder(verdict),
      ),
    );
  }
}

/// Publishes verdict from lifecycle callbacks (not build).
class _VerdictListener extends StatefulWidget {
  const _VerdictListener({
    required this.verdict,
    required this.onVerdict,
    required this.child,
  });

  final PlateValidation verdict;
  final ValueChanged<PlateValidation> onVerdict;
  final Widget child;

  @override
  State<_VerdictListener> createState() => _VerdictListenerState();
}

class _VerdictListenerState extends State<_VerdictListener> {
  @override
  void initState() {
    super.initState();
    widget.onVerdict(widget.verdict);
  }

  @override
  void didUpdateWidget(_VerdictListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verdict != oldWidget.verdict) {
      widget.onVerdict(widget.verdict);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Positions a child from a [PlateBox].
class _Placed extends StatelessWidget {
  const _Placed({required this.box, required this.child});

  final PlateBox box;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: box.left,
    top: box.top,
    width: box.width,
    height: box.height,
    child: child,
  );
}

/// Border and face, subscribed to completion (repaints only when last slot fills).
class _FrameBinding extends StatelessWidget {
  const _FrameBinding({required this.theme, required this.controller});

  final PlateTheme theme;
  final PlateController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.completed,
      builder: (context, isCompleted, _) =>
          PlateFrame(isCompleted: isCompleted, theme: theme),
    );
  }
}

/// One slot, subscribed only to its own character (keeps keystrokes local).
class _SlotBinding extends StatelessWidget {
  const _SlotBinding({
    required this.index,
    required this.slot,
    required this.behavior,
    required this.theme,
    required this.machine,
    required this.controller,
    required this.onCompleted,
    required this.onPressed,
  });

  final int index;
  final PlateSlot slot;
  final SlotBehavior behavior;
  final PlateTheme theme;
  final PlateInputMachine machine;
  final PlateController controller;
  final VoidCallback? onCompleted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.slot(index),
      builder: (context, value, _) {
        machine.syncController(index, value);
        return PlateSlotItem(
          slot: slot,
          behavior: behavior,
          theme: theme,
          value: value,
          controller: machine.controllerAt(index),
          focusNode: machine.focusNodeAt(index),
          onChanged: (v) => controller.setAt(index, v),
          onCompleted: onCompleted,
          onBackspace: machine.backspaceCharacter,
          onPressed: onPressed,
        );
      },
    );
  }
}

/// Read-only echo of a slot's character (no focus, no controller).
class _MirrorBinding extends StatelessWidget {
  const _MirrorBinding({
    required this.mirror,
    required this.alphabet,
    required this.theme,
    required this.controller,
  });

  final PlateMirror mirror;
  final PlateAlphabet alphabet;
  final PlateTheme theme;
  final PlateController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.slot(mirror.source),
      builder: (context, value, _) => Center(
        child: Text(
          alphabet.render(value ?? ''),
          textAlign: TextAlign.center,
          style: theme.glyphStyle(mirror.glyphHeight, theme.ink),
        ),
      ),
    );
  }
}

/// Editable mirror: a second input field bound to the source slot's value.
class _EditableMirrorBinding extends StatelessWidget {
  const _EditableMirrorBinding({
    required this.mirrorIndex,
    required this.mirror,
    required this.alphabet,
    required this.behavior,
    required this.theme,
    required this.machine,
    required this.controller,
    required this.onCompleted,
  });

  final int mirrorIndex;
  final PlateMirror mirror;
  final PlateAlphabet alphabet;
  final SlotBehavior behavior;
  final PlateTheme theme;
  final PlateInputMachine machine;
  final PlateController controller;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.slot(mirror.source),
      builder: (context, value, _) {
        machine.syncMirrorController(mirrorIndex, alphabet, value);
        return PlateSlotItem(
          slot: PlateSlot(
            alphabet: alphabet,
            box: PlateBox(0, 0, mirror.box.width, mirror.glyphHeight),
          ),
          behavior: behavior,
          theme: theme,
          value: value,
          controller: machine.mirrorControllerAt(mirrorIndex),
          focusNode: machine.mirrorFocusNodeAt(mirrorIndex)!,
          onChanged: (v) => controller.setAt(mirror.source, v),
          onCompleted: onCompleted,
          onBackspace: machine.backspaceCharacter,
        );
      },
    );
  }
}

/// Clips to white face's rounded rect; geometry mirrors [PlateFrame].
class _PlateFaceClipper extends CustomClipper<RRect> {
  const _PlateFaceClipper({required this.border, required this.radius});

  final double border;
  final double radius;

  @override
  RRect getClip(Size size) {
    // Deflate slightly less than the border thickness: the content layer
    // (country panel, dividers, slots) is painted on top of PlateFrame's own
    // white face, which is deflated by the *full* border. Clipping content to
    // that exact same rect leaves a hairline white seam at the border/panel
    // boundary once the whole plate is scaled by the outer FittedBox — the
    // two independently-rasterised anti-aliased edges don't composite
    // pixel-for-pixel. Letting content bleed `_overlap` further out (under
    // the border paint, which stays on top of nothing — it's the same
    // layer's edge) removes the seam with no visible change to border width.
    final inner = (Offset.zero & size).deflate(border - _overlap);
    return RRect.fromRectAndRadius(inner, Radius.circular(radius));
  }

  static const _overlap = 0.75;

  @override
  bool shouldReclip(_PlateFaceClipper old) =>
      old.border != border || old.radius != radius;
}

/// A [PlateBand]'s fill, rounded per [PlateBand.topCornerRadius] and
/// [PlateBand.bottomCornerRadius]. A `BoxDecoration` border radius rather than
/// a `ClipPath` — the clip-based version left a seam where it met the plate's
/// own rounded corner.
class _Band extends StatelessWidget {
  const _Band({required this.band});

  final PlateBand band;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: band.color,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(band.topCornerRadius),
          bottom: Radius.circular(band.bottomCornerRadius),
        ),
      ),
    );
  }
}
