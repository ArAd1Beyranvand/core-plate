import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../input/plate_input_controller.dart';
import '../input/plate_input_machine.dart';
import '../model/plate_alphabet.dart';
import '../model/plate_box.dart';
import '../model/plate_input_source.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import '../theme/plate_theme.dart';
import '../validators/plate_validator.dart';
import 'country_panel.dart';
import 'plate_frame.dart';
import 'plate_slot_item.dart';

/// The editable plate for a [PlateSpec].
///
/// **Requires a [PlateCardBloc] above it in the tree.** `PlateCanvas` reads and
/// writes the plate's characters through `context.read<PlateCardBloc>()` and
/// has no fallback — wrap it in a `BlocProvider<PlateCardBloc>` (created with
/// the same spec) or it throws on first build. If you change [spec] on a live
/// canvas, it dispatches `SpecIsChanged` so the bloc's value list stays the
/// right length for the new spec.
///
/// `PlateCanvas` provides its own [Material], so it renders correctly without a
/// [Scaffold] ancestor.
class PlateCanvas extends StatefulWidget {
  const PlateCanvas({
    super.key,
    required this.spec,
    this.mode = PlateMode.input,
    this.theme,
    this.inputSource,
    required this.onChooseCharacter,
    this.onActiveIndexChanged,
    this.controller,
    this.validator,
    this.autoValidate = false,
  });

  final PlateSpec spec;
  final PlateMode mode;
  final PlateTheme? theme;
  final PlateInputSource? inputSource;

  /// Presents a character chooser for a `chosen`-alphabet slot and returns the
  /// picked character, or null if dismissed. Required: core ships no built-in
  /// chooser — the `plate_keypad` package's `PlateCharacterPicker.show` is the
  /// usual value, but any modal that resolves to a `String?` works.
  final Future<String?> Function(PlateAlphabet alphabet) onChooseCharacter;
  final ValueChanged<int?>? onActiveIndexChanged;
  final PlateInputController? controller;

  /// The rule this plate is judged against. Never prevents input; see
  /// [autoValidate] for when it is consulted.
  final PlateValidator? validator;

  /// When true, the canvas validates after every committed value and paints
  /// the invalid state itself. When false (the default), [validator] is
  /// consulted only when the host asks — read
  /// [PlateInputController.validation] and decide your own timing.
  final bool autoValidate;

  @override
  State<PlateCanvas> createState() => _PlateCanvasState();
}

class _PlateCanvasState extends State<PlateCanvas> {
  /// Focus, active-slot tracking and navigation for [PlateCanvas.spec]. Rebuilt
  /// whenever that spec changes; see [_installMachine].
  late PlateInputMachine _machine;

  @override
  void initState() {
    super.initState();
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
      // Keep the bloc's state in step with the new spec. The bloc still holds
      // the previous plate's values — a different slot count — and every
      // `values[index]` read below (slots, validation, commit) would be
      // against the wrong-length list, off the end for a shorter spec. Reset
      // it to the new spec's empty state before rebuilding the machine.
      context.read<PlateCardBloc>().add(SpecIsChanged(widget.spec));
      oldWidget.controller?.detach(_machine);
      widget.controller?.detach(_machine);
      _machine.dispose();
      _installMachine();
    } else if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.installValidation(null);
      oldWidget.controller?.detach(_machine);
      widget.controller?.attach(_machine);
      widget.controller?.installValidation(_probeValidation);
    }
  }

  @override
  void dispose() {
    widget.controller?.installValidation(null);
    widget.controller?.detach(_machine);
    _machine.dispose();
    super.dispose();
  }

  /// Builds the machine for the current spec, hands the host's controller to
  /// it, and reports the seeded active slot. Everything a fresh mount does —
  /// which is exactly what a spec change needs too.
  void _installMachine() {
    assert(debugValidateSpec(widget.spec));
    final machine = PlateInputMachine(
      spec: widget.spec,
      inputSource: _resolveInputSource(),
      readValues: () => context.read<PlateCardBloc>().state.plateNumber.values,
      commit: (index, value) => context.read<PlateCardBloc>().add(
        ValueIsChanged(index: index, value: value),
      ),
      onActiveIndexChanged: _reportActiveIndex,
    )..onSheetRequested = _openPicker;
    _machine = machine;
    widget.controller?.attach(machine);
    widget.controller?.installValidation(_probeValidation);
    if (machine.activeIndex != null) {
      // The machine's seeded slot (see its constructor) is announced from here,
      // after the frame, so listeners are attached; a later focus change
      // overrides it. Guarded on the machine still being the current one, since
      // another spec change can land before the callback runs.
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

  /// The plate as it stands, for a validator to judge. [values] is passed in
  /// rather than read here so the auto-validating path can take it from the
  /// value it is already subscribed to.
  PlateEntry _entryFor(List<String?> values) => PlateEntry(
        spec: widget.spec,
        values: values,
        activeIndex: _machine.activeIndex,
      );

  /// Backs [PlateInputController.validation]. Null when there is no validator,
  /// which is what makes that getter null for a host that set none.
  PlateValidation? _probeValidation() {
    final validator = widget.validator;
    if (validator == null) return null;
    return validator.validate(
      _entryFor(context.read<PlateCardBloc>().state.plateNumber.values),
    );
  }

  /// Publishes an auto-validated verdict to the host's controller. Deferred to
  /// after the frame because it runs from a build (see [_ValidationBinding])
  /// and notifying a listener that calls `setState` mid-build is an error.
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

  /// Presents the character picker for a chosen slot. Stays here rather than in
  /// the machine: it needs a [BuildContext] and a modal route, and the machine
  /// never presents UI.
  Future<void> _openPicker(int index) async {
    final slot = widget.spec.slots[index];
    final bloc = context.read<PlateCardBloc>();
    final chosen = await widget.onChooseCharacter(slot.alphabet);
    if (chosen == null) return;
    bloc.add(ValueIsChanged(index: index, value: chosen));
    final next = widget.spec.nextIndex(index);
    if (next != null) _machine.focusSlot(next);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    var theme = widget.theme ?? PlateTheme.of(context);
    if (spec.borderWidthRatioOverride != null) {
      theme = theme.copyWith(borderWidthRatio: spec.borderWidthRatioOverride!);
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
    // app's brightness. Built once per canvas build and scoped over the whole
    // slot list, instead of each typed slot constructing its own.
    final selectionTheme = ThemeData.light().copyWith(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: theme.activeColor.withValues(alpha: 0.3),
        cursorColor: theme.activeColor,
        selectionHandleColor: theme.activeColor,
      ),
    );

    // NOTE: this build deliberately does NOT watch the plate value.
    //
    // It used to `context.select` the whole [PlateNumber], which meant every
    // bloc emission rebuilt this entire subtree — the frame, the clip, the
    // country panel, every rule, label and decal, and all eight slots — to
    // change one character. The frame and each slot now subscribe to just the
    // part they render (see [_FrameBinding] and [_SlotBinding]), so a keystroke
    // rebuilds one slot, and the plate's static furniture is built once.
    //
    // [_ValidationBinding] is the one exception, and only under autoValidate:
    // it watches the value through a verdict, so it rebuilds on a flip between
    // valid and invalid rather than on a keystroke.

    // The rounded white face, so content (e.g. the blue country panel) is
    // clipped to the same corner radius the frame paints instead of poking
    // square corners into the rounded plate. Kept in sync with PlateFrame's
    // own geometry: border thickness and inner radius both derive from the
    // plate height. Taken off the base theme: the alert only recolours the
    // underlines, so geometry cannot shift when a verdict flips.
    final border = theme.borderWidthRatio * spec.canvasHeight;
    final outerRadius = theme.plateRadiusRatio * spec.canvasHeight;
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    Widget buildFace(PlateTheme theme) => FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: spec.canvasWidth,
        height: spec.canvasHeight,
        child: Directionality(
          textDirection: spec.textDirection,
          child: Stack(
            children: [
              Positioned.fill(child: _FrameBinding(theme: theme)),
              Positioned.fill(
                child: ClipRRect(
                  clipper: _PlateFaceClipper(
                    border: border,
                    radius: innerRadius,
                  ),
                  child: Stack(
                    children: [
                      _Placed(
                        box: spec.panel.box,
                        child: CountryPanel(
                          country: spec.country,
                          theme: theme,
                          panel: spec.panel,
                        ),
                      ),
                      for (final r in spec.rules)
                        _Placed(
                          box: r.box,
                          child: ColoredBox(color: theme.dividerColor),
                        ),
                      for (final l in spec.labels)
                        _Placed(
                          box: l.box,
                          child: Text(
                            l.text,
                            textAlign: TextAlign.center,
                            style: theme.glyphStyle(l.glyphHeight, theme.ink),
                          ),
                        ),
                      for (final d in spec.decals)
                        _Placed(
                          box: d.box,
                          child: Image(image: d.image, fit: BoxFit.contain),
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
                              machine: _machine,
                              onCompleted: widget.mode == PlateMode.input
                                  ? () => _machine.advanceFrom(i)
                                  : null,
                              onPressed: behaviors[i] == SlotBehavior.sheet
                                  ? () => _openPicker(i)
                                  : null,
                            ),
                          ),
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

    // The alert. With autoValidate on, the canvas judges the plate itself and
    // paints the completed-field underline in the theme's alert colour — that,
    // and nothing else: no dialog, no exception, and above all no rejected
    // keystroke. With it off the validator is never called from here; a host
    // that wants its own timing reads PlateInputController.validation.
    final validator = widget.validator;
    final Widget face = widget.autoValidate && validator != null
        ? _ValidationBinding(
            validate: (values) => validator.validate(_entryFor(values)),
            onVerdict: _publishVerdict,
            builder: (verdict) => buildFace(
              verdict.isValid
                  ? theme
                  : theme.copyWith(activeColor: theme.alertColor),
            ),
          )
        : buildFace(theme);

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

/// The plate's face, subscribed to the verdict on the typed value rather than
/// to the value itself.
///
/// `select` returns a [PlateValidation], which compares by reason, so the
/// subtree rebuilds when the plate crosses between valid and invalid and not
/// once per keystroke — the property the showcase used to maintain by hand.
class _ValidationBinding extends StatelessWidget {
  const _ValidationBinding({
    required this.validate,
    required this.onVerdict,
    required this.builder,
  });

  final PlateValidation Function(List<String?> values) validate;
  final ValueChanged<PlateValidation> onVerdict;
  final Widget Function(PlateValidation verdict) builder;

  @override
  Widget build(BuildContext context) {
    // A `BlocSelector` folds the bloc state down to the verdict; because
    // `PlateValidation` compares by reason, the builder runs only when the
    // plate crosses between valid and invalid, not once per keystroke.
    //
    // The verdict is handed to `_VerdictListener`, which publishes it from its
    // own lifecycle callbacks (`initState` / `didUpdateWidget`) rather than
    // from `build`. `build` here no longer notifies anyone, and a rebuild that
    // leaves the verdict unchanged publishes nothing.
    return BlocSelector<PlateCardBloc, PlateCardState, PlateValidation>(
      selector: (state) => validate(state.plateNumber.values),
      builder: (context, verdict) => _VerdictListener(
        verdict: verdict,
        onVerdict: onVerdict,
        child: builder(verdict),
      ),
    );
  }
}

/// Publishes [verdict] to [onVerdict] from lifecycle callbacks — never from
/// `build` — so the side effect fires exactly once per verdict flip.
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

/// Positions a child in plate-space from a [PlateBox]. The one place the four
/// `left/top/width/height` literals turn into a [Positioned].
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

/// The plate's border and white face, subscribed only to whether the plate is
/// complete.
///
/// [PlateFrame] repaints for exactly one reason — the border shifts ~2% when
/// the last slot fills — so watching a bool means a keystroke that does not
/// complete the plate leaves the frame entirely alone.
class _FrameBinding extends StatelessWidget {
  const _FrameBinding({required this.theme});

  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final isCompleted = context.select<PlateCardBloc, bool>(
      (b) => b.state.plateNumber.isCompleted,
    );
    return PlateFrame(isCompleted: isCompleted, theme: theme);
  }
}

/// One slot, subscribed to its OWN character rather than to the whole plate.
///
/// This is what keeps a keystroke local: `select` returns a `String?`, so only
/// the slot whose character actually changed rebuilds. The other seven, the
/// country panel, the rules, the labels and the decals are untouched.
class _SlotBinding extends StatelessWidget {
  const _SlotBinding({
    required this.index,
    required this.slot,
    required this.behavior,
    required this.theme,
    required this.machine,
    required this.onCompleted,
    required this.onPressed,
  });

  final int index;
  final PlateSlot slot;
  final SlotBehavior behavior;
  final PlateTheme theme;

  /// Owns this slot's focus node and text controller. Read here rather than
  /// passed in, so a new machine (after a spec change) reaches every slot.
  final PlateInputMachine machine;
  final VoidCallback? onCompleted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final value = context.select<PlateCardBloc, String?>((b) {
      final values = b.state.plateNumber.values;
      return index < values.length ? values[index] : null;
    });

    // Keep the field's text in step with the bloc, as the canvas used to do for
    // every slot at once. This runs before this slot's own TextField builds in
    // the same frame, so notifying its controller here is safe.
    machine.syncController(index, value);

    final bloc = context.read<PlateCardBloc>();
    return PlateSlotItem(
      slot: slot,
      behavior: behavior,
      theme: theme,
      value: value,
      controller: machine.controllerAt(index),
      focusNode: machine.focusNodeAt(index),
      onChanged: (v) => bloc.add(ValueIsChanged(index: index, value: v)),
      onCompleted: onCompleted,
      onPressed: onPressed,
    );
  }
}

/// Clips plate content to the white face's rounded rectangle: the plate rect
/// inset by the border thickness, rounded by the inner corner radius. Geometry
/// mirrors [PlateFrame]'s painter so the clip and the painted face stay aligned.
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
