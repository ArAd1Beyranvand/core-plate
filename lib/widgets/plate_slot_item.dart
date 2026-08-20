import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_number.dart';
import '../model/plate_spec.dart';
import '../theme/plate_theme.dart';
import 'plate_items.dart';

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

  /// Opens the picker; chosen slots in [LetterInputMode.picker] only.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);

    if (mode == PlateMode.display) {
      final v = value ?? '';
      return SizedBox(
        width: slot.width,
        height: slot.height,
        child: v.isEmpty
            ? null
            : Center(
                child: Text(
                  slot.alphabet.render(v),
                  textAlign: TextAlign.center,
                  style: PlateDigit.styleFor(slot.height, effectiveTheme.ink),
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
      width: slot.width,
      height: slot.height,
      child: Theme(
        data: ThemeData.light().copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: effectiveTheme.activeColor.withValues(alpha: 0.3),
            cursorColor: effectiveTheme.activeColor,
            selectionHandleColor: effectiveTheme.activeColor,
          ),
        ),
        child: ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) => TextField(
            controller: field,
            focusNode: focusNode,
            readOnly: letterInputMode == LetterInputMode.hostKeypad,
            showCursor: letterInputMode == LetterInputMode.hostKeypad
                ? focusNode.hasFocus
                : null,
            textAlign: TextAlign.center,
            style: PlateDigit.styleFor(slot.height, effectiveTheme.ink),
            cursorColor: effectiveTheme.activeColor,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: slot.height * 0.12,
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
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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
            style: PlateDigit.styleFor(
              slot.height,
              effectiveTheme.inactiveColor,
            ),
          )
        : Text(
            slot.alphabet.render(value!),
            textAlign: TextAlign.center,
            style: PlateDigit.styleFor(slot.height, effectiveTheme.ink),
          );

    Widget slotBox(Color underlineColor) => SizedBox(
      width: slot.width,
      height: slot.height,
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

    // Both keyboard and hostKeypad make the slot focusable and drive the
    // underline off focus rather than opening a sheet. Only keyboard mode
    // consumes key events; hostKeypad receives its letter from the app's
    // on-screen pad via the bloc, so it just claims focus on tap.
    if (letterInputMode == LetterInputMode.keyboard ||
        letterInputMode == LetterInputMode.hostKeypad) {
      final bool isKeyboard = letterInputMode == LetterInputMode.keyboard;
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
