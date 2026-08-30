import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_input_source.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';

/// Material themes for the text-selection colours, cached by active colour.
///
/// [ThemeData.light] is one of the most expensive constructors in the
/// framework — it derives a full colour scheme, a full text theme and every
/// Material sub-theme. This widget was calling it once per typed slot on every
/// build, so an eight-slot plate paid for eight of them on every keystroke,
/// and the enclosing [Theme] then ran `ThemeData`'s field-by-field
/// `updateShouldNotify` comparison eight more times.
///
/// The result depends only on the active colour, and a plate uses two or three
/// of those in its whole life, so they are built once and reused.
final Map<Color, ThemeData> _selectionThemes = <Color, ThemeData>{};

ThemeData _selectionTheme(Color active) {
  return _selectionThemes.putIfAbsent(
    active,
    () => ThemeData.light().copyWith(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: active.withValues(alpha: 0.3),
        cursorColor: active,
        selectionHandleColor: active,
      ),
    ),
  );
}

/// One plate position, driven entirely by its [PlateSlot].
///
/// This replaces the old `IntegerPlateItem`/`StringPlateItem` pair: those two
/// differed only in which characters they accepted and how the character
/// arrived, which is a property of the slot's [PlateAlphabet], not a reason for
/// two widgets. The behaviour is a straight port of both.
///
/// The widget never reads the bloc. Its [value] arrives as a parameter — the
/// plate is the only thing that talks to the bloc.
class PlateSlotItem extends StatelessWidget {
  const PlateSlotItem({
    super.key,
    required this.slot,
    required this.mode,
    required this.value,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
    required this.inputSource,
    this.theme,
    this.letterInputMode = LetterInputMode.picker,
    this.onPressed,
  });

  final PlateSlot slot;
  final PlateMode mode;

  /// The current canonical (storage-form) value, or null/empty when unset.
  final String? value;

  /// Backs the [TextField] for typed slots. Null for chosen slots.
  final TextEditingController? controller;

  final FocusNode focusNode;

  /// Commits a canonical character, or '' to clear.
  final ValueChanged<String> onChanged;

  /// Fires after a non-empty commit.
  final VoidCallback? onCompleted;

  final PlateTheme? theme;

  final LetterInputMode letterInputMode;

  /// How characters arrive for this slot. Supersedes [letterInputMode] where
  /// the two disagree.
  final PlateInputSource inputSource;

  /// Opens the picker; chosen slots in [LetterInputMode.picker] only.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);

    if (mode == PlateMode.display) {
      final v = value ?? '';
      return SizedBox(
        width: slot.box.width,
        height: slot.box.height,
        child: v.isEmpty
            ? null
            : Center(
                child: Text(
                  slot.alphabet.render(v),
                  textAlign: TextAlign.center,
                  style: effectiveTheme.glyphStyle(slot.box.height, effectiveTheme.ink),
                ),
              ),
      );
    }

    if (slot.alphabet.input == AlphabetInput.typed) {
      return _buildTypedField(effectiveTheme);
    }

    return _buildChosenSlot(effectiveTheme);
  }

  /// The former [IntegerPlateItem]: a real [TextField] restyled to a bare glyph
  /// with a thin underline.
  Widget _buildTypedField(PlateTheme effectiveTheme) {
    final field = controller!;

    // TODO(persian-input): the controller keeps ASCII so the bloc stays ASCII;
    // a two-way TextInputFormatter that displays Persian while storing ASCII is
    // fiddly to get right (cursor/selection), so the field shows ASCII for now.
    final isEmpty = field.text.isEmpty;
    final underlineColor = isEmpty
        ? effectiveTheme.inactiveColor
        : effectiveTheme.activeColor;

    // Digits get the numeric keyboard; any other typed alphabet gets text.
    final isNumeric = slot.alphabet.isNumeric;

    return SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: Theme(
        data: _selectionTheme(effectiveTheme.activeColor),
        child: ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) => TextField(
            controller: field,
            focusNode: focusNode,
            readOnly:
                inputSource == PlateInputSource.packageKeypad ||
                inputSource == PlateInputSource.host,
            showCursor:
                inputSource == PlateInputSource.packageKeypad ||
                    inputSource == PlateInputSource.host
                ? focusNode.hasFocus
                : null,
            textAlign: TextAlign.center,
            style: effectiveTheme.glyphStyle(slot.box.height, effectiveTheme.ink),
            cursorColor: effectiveTheme.activeColor,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: slot.box.height * 0.12,
              ),
              filled: false,
              counterText: '',
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: effectiveTheme.inactiveColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: underlineColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: effectiveTheme.activeColor),
              ),
            ),
            onChanged: (typed) {
              if (slot.alphabet.accepts(typed)) {
                onChanged(typed);
                if (typed != '') {
                  if (onCompleted != null) onCompleted!();
                }
              } else {
                field.text = '';
                onChanged('');
              }
            },
            maxLength: 1,
            keyboardType: inputSource == PlateInputSource.hardwareKeyboard
                ? TextInputType.none
                : isNumeric
                ? TextInputType.number
                : TextInputType.text,
          ),
        ),
      ),
    );
  }

  /// The former [StringPlateItem]: a focusable slot with an underline and a
  /// '؟' placeholder when empty.
  Widget _buildChosenSlot(PlateTheme effectiveTheme) {
    final isEmpty = value == null || value!.isEmpty;

    final letter = isEmpty
        ? Text(
            '؟',
            textAlign: TextAlign.center,
            style: effectiveTheme.glyphStyle(
              slot.box.height,
              effectiveTheme.inactiveColor,
            ),
          )
        : Text(
            slot.alphabet.render(value!),
            textAlign: TextAlign.center,
            style: effectiveTheme.glyphStyle(slot.box.height, effectiveTheme.ink),
          );

    Widget slotBox(Color underlineColor) => SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: underlineColor)),
        ),
        child: Center(child: letter),
      ),
    );

    final restingColor = isEmpty
        ? effectiveTheme.inactiveColor
        : effectiveTheme.activeColor;

    // Both hardwareKeyboard and packageKeypad/host make the slot focusable and
    // drive the underline off focus rather than opening a sheet. Only
    // hardwareKeyboard consumes key events; packageKeypad/host receive their
    // letter from the app's on-screen pad via the bloc, so they just claim
    // focus on tap.
    if (inputSource == PlateInputSource.hardwareKeyboard ||
        inputSource == PlateInputSource.packageKeypad ||
        inputSource == PlateInputSource.host) {
      final bool isKeyboard = inputSource == PlateInputSource.hardwareKeyboard;
      return Focus(
        focusNode: focusNode,
        onKeyEvent: isKeyboard
            ? (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  onChanged('');
                  return KeyEventResult.handled;
                }
                final ch = event.character;
                if (ch != null && ch.length == 1 && slot.alphabet.accepts(ch)) {
                  onChanged(ch);
                  return KeyEventResult.handled;
                }
                // Everything else (digits, arrows, ...) reaches the next field.
                return KeyEventResult.ignored;
              }
            : null,
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: () => focusNode.requestFocus(),
              child: slotBox(
                hasFocus ? effectiveTheme.activeColor : restingColor,
              ),
            );
          },
        ),
      );
    }

    return InkWell(onTap: onPressed, child: slotBox(restingColor));
  }
}
