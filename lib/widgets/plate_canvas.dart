import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../model/plate_alphabet.dart';
import '../bloc/plate_card_bloc.dart';
import '../theme/plate_theme.dart';
import '../tools.dart';
import 'plate_slot_item.dart';
import 'plate_items.dart';
import 'plate_frame.dart';
import 'country_panel.dart';
import '../car_plate/letter_picker.dart';

class PlateCanvas extends StatefulWidget {
  const PlateCanvas({
    super.key,
    required this.spec,
    this.mode = PlateMode.input,
    this.theme,
    this.letterInputMode,
    this.onChooseCharacter,
    this.onActiveSlotChanged,
    this.onRemove,
    this.showRemoveButton = false,
  });

  final PlateSpec spec;
  final PlateMode mode;
  final PlateTheme? theme;
  final LetterInputMode? letterInputMode;
  final Future<String?> Function(PlateAlphabet alphabet)? onChooseCharacter;
  final ValueChanged<int?>? onActiveSlotChanged;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  @override
  State<PlateCanvas> createState() => _PlateCanvasState();
}

class _PlateCanvasState extends State<PlateCanvas> {
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, TextEditingController> _controllers = {};

  int? _activeSlot;
  late LetterInputMode _letterInputMode;

  @override
  void initState() {
    super.initState();
    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();
    for (final slot in widget.spec.slots) {
      _focusNodes[slot.index] = FocusNode()..addListener(_handleFocusChange);
      if (slot.alphabet.input == AlphabetInput.typed) {
        _controllers[slot.index] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.removeListener(_handleFocusChange);
      f.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    int? active;
    for (final entry in _focusNodes.entries) {
      if (entry.value.hasFocus) {
        active = entry.key;
        break;
      }
    }
    if (active != _activeSlot) {
      _activeSlot = active;
      widget.onActiveSlotChanged?.call(active);
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
        _letterInputMode == LetterInputMode.picker) {
      _openPicker(nextSlot);
    } else {
      _focusNodes[next]?.requestFocus();
    }
  }

  Future<void> _openPicker(PlateSlot slot) async {
    final bloc = context.read<PlateCardBloc>();
    final chosen = widget.onChooseCharacter != null
        ? await widget.onChooseCharacter!(slot.alphabet)
        : await showModalBottomSheet<String>(
            context: context,
            builder: (_) => _CharacterPickerSheet(alphabet: slot.alphabet),
          );
    if (chosen == null) return;
    bloc.add(ValueIsChanged(index: slot.index, value: chosen));
    if (slot.next != null) _focusNodes[slot.next!]?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    var theme = widget.theme ?? PlateTheme.of(context);
    if (spec.borderWidthRatioOverride != null) {
      theme = theme.copyWith(borderWidthRatio: spec.borderWidthRatioOverride!);
    }
    _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode();

    final plate =
        context.select<PlateCardBloc, PlateNumber>((b) => b.state.plateNumber);
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
              Positioned(
                left: spec.panelLeft,
                top: spec.panelTop,
                width: spec.panelWidth,
                height: spec.panelHeight,
                child: CountryPanel(country: spec.country, theme: theme),
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
                    style: PlateDigit.styleFor(l.glyphHeight, theme.ink),
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
                      onChanged: (v) =>
                          bloc.add(ValueIsChanged(index: s.index, value: v)),
                      onCompleted: widget.mode == PlateMode.input
                          ? () => _advance(s)
                          : null,
                      onPressed: (widget.mode == PlateMode.input &&
                              s.alphabet.input == AlphabetInput.chosen &&
                              _letterInputMode == LetterInputMode.picker)
                          ? () => _openPicker(s)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.showRemoveButton) return fitted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fitted,
        IconButton(
          onPressed: widget.onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _CharacterPickerSheet extends StatefulWidget {
  const _CharacterPickerSheet({required this.alphabet});

  final PlateAlphabet alphabet;

  @override
  State<_CharacterPickerSheet> createState() => _CharacterPickerSheetState();
}

class _CharacterPickerSheetState extends State<_CharacterPickerSheet> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: LetterPicker(
              onSelectedItemChanged: (i) => _index = i,
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(widget.alphabet.characters[_index]),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
