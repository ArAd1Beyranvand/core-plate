import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/plate_box.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/plate_alphabet.dart';
import '../model/plate_input_source.dart';
import '../bloc/plate_card_bloc.dart';
import '../theme/plate_theme.dart';
import 'plate_slot_item.dart';
import 'plate_frame.dart';
import 'country_panel.dart';
import 'plate_character_picker.dart';
import '../input/plate_input_controller.dart';

class PlateCanvas extends StatefulWidget {
  const PlateCanvas({
    super.key,
    required this.spec,
    this.mode = PlateMode.input,
    this.theme,
    this.letterInputMode,
    this.inputSource,
    this.onChooseCharacter,
    this.onActiveIndexChanged,
    this.controller,
  });

  final PlateSpec spec;
  final PlateMode mode;
  final PlateTheme? theme;
  @Deprecated('Use inputSource')
  final LetterInputMode? letterInputMode;
  final PlateInputSource? inputSource;
  final Future<String?> Function(PlateAlphabet alphabet)? onChooseCharacter;
  final ValueChanged<int?>? onActiveIndexChanged;
  final PlateInputController? controller;

  @override
  State<PlateCanvas> createState() => _PlateCanvasState();
}

class _PlateCanvasState extends State<PlateCanvas> implements PlateInputTarget {
  // Indexed by slot position: slot identity *is* list order, so a dense list
  // says that in the type instead of leaving it to convention. Null controller
  // entries are chosen-alphabet slots, which have no text field.
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController?> _controllers = [];

  int? _activeIndex;
  late LetterInputMode _letterInputMode;
  late PlateInputSource _inputSource;

  @override
  void initState() {
    super.initState();
    assert(debugValidateSpec(widget.spec));
    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();
    _inputSource = _resolveInputSource();
    for (var i = 0; i < widget.spec.slots.length; i++) {
      _focusNodes.add(FocusNode()..addListener(_handleFocusChange));
      _controllers.add(
        widget.spec.slots[i].alphabet.input == AlphabetInput.typed
            ? TextEditingController()
            : null,
      );
    }
    // Seed the active slot to the first one before any focus lands, so a host
    // that renders its own keypad off [activeIndex] (e.g. picking a digit vs.
    // letters pad from the slot's alphabet) starts on the alphabet the first
    // slot actually takes — instead of defaulting to one type and visibly
    // switching the instant focus reaches slot 0. Reported after the first
    // frame so listeners are attached; a later focus change overrides it.
    _activeIndex = widget.spec.slots.isNotEmpty ? 0 : null;
    widget.controller?.attach(this);
    if (_activeIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onActiveIndexChanged?.call(_activeIndex);
        widget.controller?.notifyActiveSlotChanged();
      });
    }
  }

  @override
  void didUpdateWidget(PlateCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    for (final c in _controllers) {
      c?.dispose();
    }
    for (final f in _focusNodes) {
      f.removeListener(_handleFocusChange);
      f.dispose();
    }
    super.dispose();
  }

  PlateInputSource _resolveInputSource() {
    return widget.inputSource ??
        (widget.letterInputMode != null
            ? inputSourceFromLetterMode(widget.letterInputMode!)
            : defaultInputSource());
  }

  void _handleFocusChange() {
    int? active;
    for (var i = 0; i < _focusNodes.length; i++) {
      if (_focusNodes[i].hasFocus) {
        active = i;
        break;
      }
    }
    if (active != _activeIndex) {
      _activeIndex = active;
      widget.onActiveIndexChanged?.call(active);
      widget.controller?.notifyActiveSlotChanged();
    }
  }

  void _advance(int index) {
    final next = widget.spec.nextIndex(index);
    if (next == null) {
      _focusNodes[index].unfocus();
      return;
    }
    final nextSlot = widget.spec.slots[next];
    if (nextSlot.alphabet.input == AlphabetInput.chosen &&
        _inputSource == PlateInputSource.system) {
      _openPicker(next);
    } else {
      _focusNodes[next].requestFocus();
    }
  }

  Future<void> _openPicker(int index) async {
    final slot = widget.spec.slots[index];
    final bloc = context.read<PlateCardBloc>();
    final chosen = widget.onChooseCharacter != null
        ? await widget.onChooseCharacter!(slot.alphabet)
        : await PlateCharacterPicker.show(context, slot.alphabet);
    if (chosen == null) return;
    bloc.add(ValueIsChanged(index: index, value: chosen));
    final next = widget.spec.nextIndex(index);
    if (next != null) _focusNodes[next].requestFocus();
  }

  @override
  int? get activeIndex => _activeIndex;

  @override
  void submitCharacter(String c) {
    final index = _activeIndex;
    if (index == null || !widget.spec.slots[index].alphabet.accepts(c)) return;
    context.read<PlateCardBloc>().add(ValueIsChanged(index: index, value: c));
    _advance(index);
  }

  @override
  void backspaceCharacter() {
    final index = _activeIndex;
    if (index == null) return;
    final values = context.read<PlateCardBloc>().state.plateNumber.values;
    final current = values[index];
    final target = (current == null || current.isEmpty)
        ? widget.spec.previousIndex(index)
        : index;
    if (target == null) return;
    context.read<PlateCardBloc>().add(
      ValueIsChanged(index: target, value: ''),
    );
    _focusNodes[target].requestFocus();
  }

  @override
  void focusFirstEmptySlot() {
    final values = context.read<PlateCardBloc>().state.plateNumber.values;
    for (var i = 0; i < widget.spec.slots.length; i++) {
      final v = values[i];
      if (v == null || v.isEmpty) {
        _focusNodes[i].requestFocus();
        return;
      }
    }
    _focusNodes.first.requestFocus();
  }

  @override
  void focusSlot(int index) {
    if (index < 0 || index >= _focusNodes.length) return;
    _focusNodes[index].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    var theme = widget.theme ?? PlateTheme.of(context);
    if (spec.borderWidthRatioOverride != null) {
      theme = theme.copyWith(borderWidthRatio: spec.borderWidthRatioOverride!);
    }
    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();
    // PlateMode.display renders inert, picker-like slots regardless of the
    // configured source, so force [PlateInputSource.system] there.
    _inputSource = widget.mode == PlateMode.input
        ? _resolveInputSource()
        : PlateInputSource.system;

    // NOTE: this build deliberately does NOT watch the plate value.
    //
    // It used to `context.select` the whole [PlateNumber], which meant every
    // bloc emission rebuilt this entire subtree — the frame, the clip, the
    // country panel, every rule, label and decal, and all eight slots — to
    // change one character. The frame and each slot now subscribe to just the
    // part they render (see [_FrameBinding] and [_SlotBinding]), so a keystroke
    // rebuilds one slot, and the plate's static furniture is built once.

    // The rounded white face, so content (e.g. the blue country panel) is
    // clipped to the same corner radius the frame paints instead of poking
    // square corners into the rounded plate. Kept in sync with PlateFrame's
    // own geometry: border thickness and inner radius both derive from the
    // plate height.
    final border = theme.borderWidthRatio * spec.canvasHeight;
    final outerRadius = theme.plateRadiusRatio * spec.canvasHeight;
    final innerRadius = (outerRadius - border).clamp(0.0, outerRadius);

    final fitted = FittedBox(
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
                              mode: widget.mode,
                              theme: theme,
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              letterInputMode: widget.mode == PlateMode.input
                                  ? _letterInputMode
                                  : LetterInputMode.picker,
                              inputSource: _inputSource,
                              onCompleted: widget.mode == PlateMode.input
                                  ? () => _advance(i)
                                  : null,
                              onPressed:
                                  (widget.mode == PlateMode.input &&
                                      spec.slots[i].alphabet.input ==
                                          AlphabetInput.chosen &&
                                      _inputSource == PlateInputSource.system)
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

    return fitted;
  }
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
      (b) => b.state.plateNumber.isCompleted(),
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
    required this.mode,
    required this.theme,
    required this.controller,
    required this.focusNode,
    required this.letterInputMode,
    required this.inputSource,
    required this.onCompleted,
    required this.onPressed,
  });

  final int index;
  final PlateSlot slot;
  final PlateMode mode;
  final PlateTheme theme;

  /// Backs the slot's [TextField]; null for chosen slots.
  final TextEditingController? controller;
  final FocusNode focusNode;
  final LetterInputMode letterInputMode;
  final PlateInputSource inputSource;
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
    final field = controller;
    if (field != null) {
      final text = value ?? '';
      if (field.text != text) {
        field.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    final bloc = context.read<PlateCardBloc>();
    return PlateSlotItem(
      slot: slot,
      mode: mode,
      theme: theme,
      value: value,
      controller: field,
      focusNode: focusNode,
      letterInputMode: letterInputMode,
      inputSource: inputSource,
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
