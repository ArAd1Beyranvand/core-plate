import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.onActiveSlotChanged,
    this.controller,
  });

  final PlateSpec spec;
  final PlateMode mode;
  final PlateTheme? theme;
  @Deprecated('Use inputSource')
  final LetterInputMode? letterInputMode;
  final PlateInputSource? inputSource;
  final Future<String?> Function(PlateAlphabet alphabet)? onChooseCharacter;
  final ValueChanged<PlateSlot?>? onActiveSlotChanged;
  final PlateInputController? controller;

  @override
  State<PlateCanvas> createState() => _PlateCanvasState();
}

class _PlateCanvasState extends State<PlateCanvas> implements PlateInputTarget {
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, TextEditingController> _controllers = {};

  PlateSlot? _activeSlot;
  late LetterInputMode _letterInputMode;
  late PlateInputSource _inputSource;

  @override
  void initState() {
    super.initState();
    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();
    _inputSource = _resolveInputSource();
    for (final slot in widget.spec.slots) {
      _focusNodes[slot.index] = FocusNode()..addListener(_handleFocusChange);
      if (slot.alphabet.input == AlphabetInput.typed) {
        _controllers[slot.index] = TextEditingController();
      }
    }
    // Seed the active slot to the first one before any focus lands, so a host
    // that renders its own keypad off [activeSlot] (e.g. picking a digit vs.
    // letters pad from the slot's alphabet) starts on the alphabet the first
    // slot actually takes — instead of defaulting to one type and visibly
    // switching the instant focus reaches slot 0. Reported after the first
    // frame so listeners are attached; a later focus change overrides it.
    _activeSlot =
        widget.spec.slots.isNotEmpty ? widget.spec.slots.first : null;
    widget.controller?.attach(this);
    if (_activeSlot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onActiveSlotChanged?.call(_activeSlot);
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
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
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
    PlateSlot? active;
    for (final entry in _focusNodes.entries) {
      if (entry.value.hasFocus) {
        active = widget.spec.slotAt(entry.key);
        break;
      }
    }
    // PlateSlot has no == override, so compare by index identity.
    if (active?.index != _activeSlot?.index) {
      _activeSlot = active;
      widget.onActiveSlotChanged?.call(active);
      widget.controller?.notifyActiveSlotChanged();
    }
  }

  void _advance(PlateSlot slot) {
    final next = slot.next;
    if (next == null) {
      _focusNodes[slot.index]?.unfocus();
      return;
    }
    final nextSlot = widget.spec.slotAt(next);
    if (nextSlot == null) return;
    if (nextSlot.alphabet.input == AlphabetInput.chosen &&
        _inputSource == PlateInputSource.system) {
      _openPicker(nextSlot);
    } else {
      _focusNodes[next]?.requestFocus();
    }
  }

  Future<void> _openPicker(PlateSlot slot) async {
    final bloc = context.read<PlateCardBloc>();
    final chosen = widget.onChooseCharacter != null
        ? await widget.onChooseCharacter!(slot.alphabet)
        : await PlateCharacterPicker.show(context, slot.alphabet);
    if (chosen == null) return;
    bloc.add(ValueIsChanged(index: slot.index, value: chosen));
    if (slot.next != null) _focusNodes[slot.next!]?.requestFocus();
  }

  @override
  PlateSlot? get activeSlot => _activeSlot;

  @override
  void submitCharacter(String c) {
    final slot = _activeSlot;
    if (slot == null || !slot.alphabet.accepts(c)) return;
    context.read<PlateCardBloc>().add(
      ValueIsChanged(index: slot.index, value: c),
    );
    _advance(slot);
  }

  @override
  void backspaceCharacter() {
    final slot = _activeSlot;
    if (slot == null) return;
    final values = context.read<PlateCardBloc>().state.plateNumber.values;
    final current = values[slot.index];
    final target = (current == null || current.isEmpty)
        ? _previousSlot(slot)
        : slot;
    if (target == null) return;
    context.read<PlateCardBloc>().add(
      ValueIsChanged(index: target.index, value: ''),
    );
    _focusNodes[target.index]?.requestFocus();
  }

  PlateSlot? _previousSlot(PlateSlot slot) {
    for (final s in widget.spec.slots) {
      if (s.next == slot.index) return s;
    }
    return null;
  }

  @override
  void focusFirstEmptySlot() {
    final values = context.read<PlateCardBloc>().state.plateNumber.values;
    for (final s in widget.spec.slots) {
      final v = values[s.index];
      if (v == null || v.isEmpty) {
        _focusNodes[s.index]?.requestFocus();
        return;
      }
    }
    _focusNodes[widget.spec.slots.first.index]?.requestFocus();
  }

  @override
  void focusSlot(int index) {
    _focusNodes[index]?.requestFocus();
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

    final plate = context.select<PlateCardBloc, PlateNumber>(
      (b) => b.state.plateNumber,
    );
    final bloc = context.read<PlateCardBloc>();

    for (final slot in spec.slots) {
      final c = _controllers[slot.index];
      if (c == null) continue;
      final v = plate.values[slot.index] ?? '';
      if (c.text != v) {
        c.value = TextEditingValue(
          text: v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      }
    }

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
              Positioned.fill(
                child: PlateFrame(
                  isCompleted: plate.isCompleted(),
                  theme: theme,
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  clipper: _PlateFaceClipper(
                    border: border,
                    radius: innerRadius,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: spec.panelLeft,
                        top: spec.panelTop,
                        width: spec.panelWidth,
                        height: spec.panelHeight,
                        child:
                            CountryPanel(
                              country: spec.country,
                              theme: theme,
                              flagScale: spec.flagScale,
                              captionScale: spec.captionScale,
                              padding: spec.panelPadding,
                            ),
                      ),
                      for (final r in spec.rules)
                        Positioned(
                          left: r.left,
                          top: r.top,
                          width: r.width,
                          height: r.height,
                          child: ColoredBox(color: theme.dividerColor),
                        ),
                      for (final l in spec.labels)
                        Positioned(
                          left: l.left,
                          top: l.top,
                          width: l.width,
                          height: l.height,
                          child: Text(
                            l.text,
                            textAlign: TextAlign.center,
                            style: theme.glyphStyle(l.glyphHeight, theme.ink),
                          ),
                        ),
                      for (final d in spec.decals)
                        Positioned(
                          left: d.left,
                          top: d.top,
                          width: d.width,
                          height: d.height,
                          child: Image(image: d.image, fit: BoxFit.contain),
                        ),
                      for (final s in spec.slots)
                        Positioned(
                          left: s.left,
                          top: s.top,
                          width: s.width,
                          height: s.height,
                          child: Center(
                            child: PlateSlotItem(
                              slot: s,
                              mode: widget.mode,
                              theme: theme,
                              value: plate.values[s.index],
                              controller: _controllers[s.index],
                              focusNode: _focusNodes[s.index]!,
                              letterInputMode: widget.mode == PlateMode.input
                                  ? _letterInputMode
                                  : LetterInputMode.picker,
                              inputSource: _inputSource,
                              onChanged: (v) => bloc
                                  .add(ValueIsChanged(index: s.index, value: v)),
                              onCompleted: widget.mode == PlateMode.input
                                  ? () => _advance(s)
                                  : null,
                              onPressed:
                                  (widget.mode == PlateMode.input &&
                                      s.alphabet.input ==
                                          AlphabetInput.chosen &&
                                      _inputSource == PlateInputSource.system)
                                  ? () => _openPicker(s)
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
