import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/plate_card_bloc.dart';
import '../input/plate_controller.dart';
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
/// **Requires a [PlateCardBloc] above it in the tree.** The canvas holds the
/// plate's characters in a [PlateController] of its own and mirrors every
/// change onto that bloc — in both directions, so a host that writes straight
/// to the bloc keeps working — but it has no fallback for the bloc's absence:
/// wrap it in a `BlocProvider<PlateCardBloc>` (created with the same spec) or
/// it throws on first build. If you change [spec] on a live canvas, it
/// dispatches `SpecIsChanged` so the bloc's value list stays the right length
/// for the new spec.
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

  /// The plate's characters, and the canvas's writer of record: every commit
  /// the machine makes, and every character the picker returns, lands here
  /// first and reaches the bloc through [_BlocBridge].
  ///
  /// This is what takes [BuildContext] out of the long-lived closures the
  /// machine holds. They used to read the bloc off `context` on every commit —
  /// a context captured by the build that installed the machine and then kept
  /// for the machine's whole life.
  late PlateController _controller;

  /// Whether [_controller] is ours to dispose. False when the host passed a
  /// [PlateController] as [PlateCanvas.controller]: that one outlives us.
  bool _ownsController = false;

  /// Keeps [_controller] and the ancestor bloc holding the same characters.
  /// Founded once the bloc is reachable (see [didChangeDependencies]) and
  /// re-founded whenever either side is replaced.
  _BlocBridge? _bridge;

  @override
  void initState() {
    super.initState();
    _adoptController();
    _installMachine();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First run here is before the first build, which is the earliest the
    // ancestor bloc is reachable — and where a canvas mounted over a
    // pre-populated bloc picks that value up. Later runs are other inherited
    // widgets changing (the plate theme, say) and find the bridge already
    // pointed at the right pair, so they cost two identity comparisons and
    // seed nothing.
    _syncBridge(seed: true);
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
      // Both stores hold the previous plate's values — a different slot count —
      // and every `values[index]` read below (slots, validation, commit) would
      // be against the wrong-length list, off the end for a shorter spec. Reset
      // both to the new spec's empty state before rebuilding the machine.
      //
      // The bridge comes down first and goes back up after: while the two sides
      // are mid-swap they hold plates of different lengths, and there is
      // nothing meaningful to carry between them. It is re-founded without a
      // seed, so the bloc's own `SpecIsChanged` emission — which lands a
      // microtask later, empty and the right length — is what the controller
      // finally agrees with.
      _bridge?.dispose();
      _bridge = null;
      context.read<PlateCardBloc>().add(SpecIsChanged(widget.spec));
      // A spec swap still clears the plate, exactly as `SpecIsChanged` does to
      // the bloc. Carrying the value across is stage 4's job, not this one's.
      _controller.adoptSpec(widget.spec, preserve: PlateValuePreservation.none);
      oldWidget.controller?.detach(_machine);
      widget.controller?.detach(_machine);
      _machine.dispose();
      _installMachine();
      _syncBridge();
    } else if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.installValidation(null);
      oldWidget.controller?.detach(_machine);
      widget.controller?.attach(_machine);
      widget.controller?.installValidation(_probeValidation);
      // Down before the swap, up after: the bridge holds a listener on the
      // controller being stood down, and that one may be disposed here.
      _bridge?.dispose();
      _bridge = null;
      _adoptController(replacing: true);
      _syncBridge(seed: true);
    }
  }

  @override
  void dispose() {
    _bridge?.dispose();
    widget.controller?.installValidation(null);
    widget.controller?.detach(_machine);
    _machine.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Points [_controller] at the host's controller when it is one that carries
  /// a value, and at a private one otherwise.
  ///
  /// [replacing] means a live canvas has just been handed a different
  /// [PlateCanvas.controller]. A private controller we already own survives
  /// that: it holds the plate's characters, and being handed a focus-only
  /// controller is no reason to drop them. A private one we stand down for a
  /// host-supplied [PlateController] is disposed; the host's own never is —
  /// it outlives us, and is routinely handed straight back on the next build.
  void _adoptController({bool replacing = false}) {
    final host = widget.controller;
    if (host is! PlateController) {
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

  /// Points the bridge at the current bloc and controller, re-founding it when
  /// either has been replaced. [seed] brings the two sides into agreement on a
  /// freshly founded pair; a re-found after a spec swap deliberately does not,
  /// since the bloc has not caught up with the new spec yet.
  void _syncBridge({bool seed = false}) {
    final bloc = context.read<PlateCardBloc>();
    final bridge = _bridge;
    if (bridge != null &&
        identical(bridge.bloc, bloc) &&
        identical(bridge.controller, _controller)) {
      return;
    }
    bridge?.dispose();
    final next = _BlocBridge(controller: _controller, bloc: bloc);
    _bridge = next;
    if (seed) next.seed();
  }

  /// Builds the machine for the current spec, hands the host's controller to
  /// it, and reports the seeded active slot. Everything a fresh mount does —
  /// which is exactly what a spec change needs too.
  void _installMachine() {
    assert(debugValidateSpec(widget.spec));
    final machine = PlateInputMachine(
      spec: widget.spec,
      inputSource: _resolveInputSource(),
      // Read through the field, not a tear-off of the controller we hold right
      // now: these closures live as long as the machine, and a host swapping
      // `controller:` replaces `_controller` underneath them without the
      // machine being rebuilt.
      readValues: () => _controller.values,
      commit: (index, value) => _controller.setAt(index, value),
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
    return validator.validate(_entryFor(_controller.values));
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
    final chosen = await widget.onChooseCharacter(slot.alphabet);
    if (chosen == null) return;
    _controller.setAt(index, chosen);
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
    // rebuilds one slot + its mirrors, and the plate's static furniture is
    // built once. A [PlateMirror] echoes one slot's value, so [_MirrorBinding]
    // subscribes to that one value the same way — a keystroke stays local to
    // the slot it lands in and the mirrors pointed at it.
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
                      for (final m in spec.mirrors)
                        _Placed(
                          box: m.box,
                          child: _MirrorBinding(
                            mirror: m,
                            alphabet:
                                m.alphabet ?? spec.slots[m.source].alphabet,
                            theme: theme,
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

/// Keeps one [PlateController] and one [PlateCardBloc] holding the same
/// characters, in both directions.
///
/// Neither side can be the only writer yet. The canvas writes to the controller
/// (that is what took [BuildContext] out of the machine's closures), the
/// bindings still render from the bloc, and real hosts write straight to the
/// bloc — the showcase's auto-typist dispatches `ValueIsChanged` itself, and
/// its second plate is driven off `bloc.stream`. So every write has to reach
/// both stores, whichever one it lands on first.
///
/// **The echo, and why it settles.** A write is reflected onto the other side,
/// which notifies, which would reflect it back. Two things stop that:
///
/// - [_syncing] drops the *synchronous* return trip. `setValues` notifies its
///   listeners during the call, so the controller's change fires while we are
///   still inside the bloc handler that caused it. This is not a mere
///   optimisation: the controller sanitises (a character its slot's alphabet
///   refuses is stored as null) and the bloc does not, so without the flag a
///   value the bloc holds and the controller declines would be echoed back as
///   an instruction to clear it — the bridge overwriting the host.
/// - The value comparisons drop the *asynchronous* return trip. `bloc.add` is
///   queued, so the emission it causes arrives a microtask later, long after
///   the flag is down; by then both sides already agree and there is nothing
///   to copy.
///
/// One write therefore settles in a single pass, and cannot oscillate.
class _BlocBridge {
  _BlocBridge({required this.controller, required this.bloc}) {
    controller.addListener(_onControllerChanged);
    _emissions = bloc.stream.listen(_onBlocState);
  }

  final PlateController controller;
  final PlateCardBloc bloc;

  late final StreamSubscription<PlateCardState> _emissions;

  /// True while this bridge is itself applying a write, so the change it is
  /// about to cause on the far side is not read back as a fresh one.
  bool _syncing = false;

  /// Brings the two sides into agreement at install time.
  ///
  /// The bloc wins, because mounting a canvas over a pre-populated bloc is the
  /// documented way to open an existing plate for editing and it must still
  /// render. The one exception is a host-supplied controller holding a value
  /// against an empty bloc, where deferring to the bloc would silently blank
  /// the host's plate; there the controller wins and the bloc is caught up.
  void seed() {
    if (bloc.state.plateNumber.isEmpty && !controller.isEmpty) {
      _onControllerChanged();
      return;
    }
    _onBlocState(bloc.state);
  }

  void _onControllerChanged() {
    if (_syncing) return;
    final values = controller.values;
    final current = bloc.state.plateNumber.values;
    _syncing = true;
    try {
      for (var i = 0; i < values.length && i < current.length; i++) {
        if ((current[i] ?? '') == (values[i] ?? '')) continue;
        bloc.add(ValueIsChanged(index: i, value: values[i]));
      }
    } finally {
      _syncing = false;
    }
  }

  void _onBlocState(PlateCardState state) {
    if (_syncing) return;
    final values = state.plateNumber.values;
    if (_agree(values, controller.values)) return;
    _syncing = true;
    try {
      controller.setValues(values);
    } finally {
      _syncing = false;
    }
  }

  /// Whether the two value lists describe the same plate. An unset slot is
  /// null on one side and '' on the other depending on which store cleared it,
  /// so they compare as the same character.
  static bool _agree(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] ?? '') != (b[i] ?? '')) return false;
    }
    return true;
  }

  void dispose() {
    controller.removeListener(_onControllerChanged);
    _emissions.cancel();
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

/// One mirror: a read-only echo of a slot's character, subscribed to that ONE
/// character exactly as [_SlotBinding] is.
///
/// It owns no focus node and no controller — a mirror is a presentation of a
/// value, not a place to type — so it never touches the input machine.
class _MirrorBinding extends StatelessWidget {
  const _MirrorBinding({
    required this.mirror,
    required this.alphabet,
    required this.theme,
  });

  final PlateMirror mirror;

  /// Resolved by the canvas: the mirror's own alphabet, or the source slot's.
  final PlateAlphabet alphabet;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final value = context.select<PlateCardBloc, String?>((b) {
      final values = b.state.plateNumber.values;
      return mirror.source < values.length ? values[mirror.source] : null;
    });

    return Center(
      child: Text(
        alphabet.render(value ?? ''),
        textAlign: TextAlign.center,
        style: theme.glyphStyle(mirror.glyphHeight, theme.ink),
      ),
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
