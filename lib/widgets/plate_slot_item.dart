import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/plate_alphabet.dart';
import '../model/plate_spec.dart';
import '../model/slot_behavior.dart';
import '../theme/plate_theme.dart';

/// One plate position, driven entirely by its [PlateSlot] and a resolved
/// [SlotBehavior].
///
/// This replaces the old `IntegerPlateItem`/`StringPlateItem` pair: those two
/// differed only in which characters they accepted and how the character
/// arrived, which is a property of the slot's [PlateAlphabet], not a reason for
/// two widgets. The behaviour is a straight port of both.
///
/// The widget never reads the bloc. Its [value] arrives as a parameter — the
/// plate is the only thing that talks to the bloc. It also never re-derives
/// what kind of input it is: [behavior] is resolved once by the canvas and
/// every arm below is a `switch` on it.
class PlateSlotItem extends StatelessWidget {
  const PlateSlotItem({
    super.key,
    required this.slot,
    required this.behavior,
    required this.value,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
    this.theme,
    this.onPressed,
  });

  final PlateSlot slot;

  /// What this slot does about input, resolved once by [PlateCanvas].
  final SlotBehavior behavior;

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

  /// Opens the picker; [SlotBehavior.sheet] only.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? PlateTheme.of(context);
    final isTyped = slot.alphabet.input == AlphabetInput.typed;

    switch (behavior) {
      case SlotBehavior.glyph:
        return _GlyphSlot(slot: slot, value: value, theme: effectiveTheme);

      case SlotBehavior.imeField:
        return _TypedField(
          slot: slot,
          behavior: behavior,
          controller: controller!,
          focusNode: focusNode,
          onChanged: onChanged,
          onCompleted: onCompleted,
          theme: effectiveTheme,
        );

      // A typed slot under a hardware keyboard stays a TextField with the IME
      // suppressed; a chosen slot becomes a Focus that consumes raw key
      // events. Not the same thing — do not collapse them.
      case SlotBehavior.hardwareField:
        if (isTyped) {
          return _TypedField(
            slot: slot,
            behavior: behavior,
            controller: controller!,
            focusNode: focusNode,
            onChanged: onChanged,
            onCompleted: onCompleted,
            theme: effectiveTheme,
          );
        }
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          theme: effectiveTheme,
        );

      case SlotBehavior.externalField:
        if (isTyped) {
          return _TypedField(
            slot: slot,
            behavior: behavior,
            controller: controller!,
            focusNode: focusNode,
            onChanged: onChanged,
            onCompleted: onCompleted,
            theme: effectiveTheme,
          );
        }
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          theme: effectiveTheme,
        );

      case SlotBehavior.sheet:
        return _ChosenSlot(
          slot: slot,
          behavior: behavior,
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          onPressed: onPressed,
          theme: effectiveTheme,
        );
    }
  }
}

/// [SlotBehavior.glyph]: a bare rendered character on the white face, or
/// nothing when the slot is unset. No focus node, no gestures.
class _GlyphSlot extends StatelessWidget {
  const _GlyphSlot({
    required this.slot,
    required this.value,
    required this.theme,
  });

  final PlateSlot slot;
  final String? value;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
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
                style: theme.glyphStyle(slot.box.height, theme.ink),
              ),
            ),
    );
  }
}

/// The former [_buildTypedField] / `IntegerPlateItem`: a real [TextField]
/// restyled to a bare glyph with a thin underline.
///
/// [behavior] is [SlotBehavior.imeField], [SlotBehavior.hardwareField] or
/// [SlotBehavior.externalField] — it picks `readOnly`, `showCursor` and
/// `keyboardType` directly, with no reference to [PlateInputSource].
class _TypedField extends StatelessWidget {
  const _TypedField({
    required this.slot,
    required this.behavior,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCompleted,
    required this.theme,
  });

  final PlateSlot slot;
  final SlotBehavior behavior;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    // TODO(persian-input): the controller keeps ASCII so the bloc stays ASCII;
    // a two-way TextInputFormatter that displays Persian while storing ASCII is
    // fiddly to get right (cursor/selection), so the field shows ASCII for now.
    final isEmpty = controller.text.isEmpty;
    final underlineColor = isEmpty ? theme.inactiveColor : theme.activeColor;

    // externalField: the host feeds every character through the bloc, so the
    // field takes no keystrokes of its own and only shows a cursor when focused.
    final readOnly = behavior == SlotBehavior.externalField;

    return SizedBox(
      width: slot.box.width,
      height: slot.box.height,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          showCursor: readOnly ? focusNode.hasFocus : null,
          textAlign: TextAlign.center,
          style: theme.glyphStyle(slot.box.height, theme.ink),
          cursorColor: theme.activeColor,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: slot.box.height * 0.12,
            ),
            filled: false,
            counterText: '',
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.inactiveColor),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: underlineColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.activeColor),
            ),
          ),
          onChanged: (typed) {
            if (slot.alphabet.accepts(typed)) {
              onChanged(typed);
              if (typed != '') {
                if (onCompleted != null) onCompleted!();
              }
            } else {
              controller.text = '';
              onChanged('');
            }
          },
          maxLength: 1,
          // hardwareField keeps a TextField but suppresses the IME; the other
          // two show it, numeric where the alphabet is digits-only.
          keyboardType: behavior == SlotBehavior.hardwareField
              ? TextInputType.none
              : slot.alphabet.isNumeric
              ? TextInputType.number
              : TextInputType.text,
        ),
      ),
    );
  }
}

/// The former [_buildChosenSlot] / `StringPlateItem`: a focusable slot with an
/// underline and a '؟' placeholder when empty.
///
/// [behavior] is [SlotBehavior.sheet] (tap opens the picker),
/// [SlotBehavior.hardwareField] (Focus consuming key events) or
/// [SlotBehavior.externalField] (Focus, tap only claims focus).
class _ChosenSlot extends StatelessWidget {
  const _ChosenSlot({
    required this.slot,
    required this.behavior,
    required this.value,
    required this.focusNode,
    required this.onChanged,
    required this.onPressed,
    required this.theme,
  });

  final PlateSlot slot;
  final SlotBehavior behavior;
  final String? value;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPressed;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;

    final letter = isEmpty
        ? Text(
            '؟',
            textAlign: TextAlign.center,
            style: theme.glyphStyle(slot.box.height, theme.inactiveColor),
          )
        : Text(
            slot.alphabet.render(value!),
            textAlign: TextAlign.center,
            style: theme.glyphStyle(slot.box.height, theme.ink),
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

    final restingColor = isEmpty ? theme.inactiveColor : theme.activeColor;

    if (behavior == SlotBehavior.sheet) {
      return InkWell(onTap: onPressed, child: slotBox(restingColor));
    }

    // hardwareField and externalField both make the slot focusable and drive
    // the underline off focus rather than opening a sheet. Only hardwareField
    // consumes key events; externalField receives its letter from the host's
    // on-screen pad via the bloc, so it just claims focus on tap.
    final consumesKeys = behavior == SlotBehavior.hardwareField;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: consumesKeys
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
            child: slotBox(hasFocus ? theme.activeColor : restingColor),
          );
        },
      ),
    );
  }
}
