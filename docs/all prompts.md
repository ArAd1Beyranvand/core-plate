# plate_number — Refactor Pipeline v2

23 prompts, 23 sessions, `/clear` between every one.

New in v2:
- the plate system is generalised so **a new country is a `const`, not a widget**
- `PlateType` (a closed enum) is retired — it is the thing that makes the package
  un-extendable by its own users
- `IntegerPlateItem` / `StringPlateItem` collapse into one slot widget
- prompt 14 is the acid test: add a German plate touching **zero** widget files
- the callout choreography is rewritten to your three motifs
- a house-rules `CLAUDE.md` so every session inherits your structural constraints

---

## Step 0 — house rules (do this once, by hand, before prompt 0)

Put this at the top of `CLAUDE.md` at the repo root. Every Claude Code session reads it,
so none of the prompts below have to repeat it.

```md
## Structural rules — non-negotiable

1. **No functions that return widgets.** A helper like `Widget _buildFoo(...)` is
   forbidden. Every piece of UI is a real `StatelessWidget` or `StatefulWidget` class
   with named parameters. Private widget classes (`class _Foo extends StatelessWidget`)
   are the correct tool. This applies to `build` helpers, list-item builders, and
   "just a small one" cases alike. The only exception is a `builder:` callback that a
   Flutter API demands (`LayoutBuilder`, `BlocBuilder`, `AnimatedBuilder`).

2. **Variation is data, not code.** If two widgets differ only in numbers, colours,
   strings, or which characters are legal, they are one widget parameterised by a
   const record. Never fork a widget to express a variant.

3. **No open-ended enums for extensible concepts.** A closed `enum` is correct for a
   fixed set the library owns (e.g. input mode). It is wrong for anything a consumer
   of this package might want to add to (plate kinds, countries). Those are const
   values of a data class.

4. **Fixed-canvas layout inside plates.** Inside any plate widget: no `Expanded`,
   `Flexible`, `IntrinsicHeight`, `AspectRatio`, `MediaQuery`, or `LayoutBuilder`.
   Only `Positioned` with plain double literals in plate-coordinate space, inside one
   `FittedBox > SizedBox > Stack`.

5. **Scope.** Modify only the files the prompt names. Do not "improve", reformat, or
   harmonise anything else, even if it looks wrong. Report it instead.
```

**After every prompt:** `flutter analyze && git add -A && git commit -m "..."`.
Never carry a broken tree into the next session.

---

# PHASE A — clear the ground

## Prompt 0 · Recon
**Sonnet 5 · low**

```
You are doing read-only reconnaissance on a Flutter project. Do not modify, create, or
delete any source file. Your only output is one new markdown file.

Produce REFACTOR_MANIFEST.md at the repo root containing:

1. A tree of every .dart file under lib/, test/, example/lib/ and example/test/, with
   its line count. Exclude .dart_tool/, build/, and any generated file under web/ or
   named *generated_plugin_registrant.dart.

2. For each of these symbols, list every file that references it, or write UNUSED:
   Calculator, MyApp, MyHomePage, GraphBloc, GraphEvent, GraphState, RelationType,
   OrderedPair, DigitRow, IranFlag, RemoveButton, PlateText, IrCarText, IrBicycleText,
   IrCarShow, IrBicycleShow, SelectableInt, SelectableString, valueTypes,
   PlateTheme.lerp, panelBlue, panelText, flagGreen, flagWhite, flagRed, screwColor,
   screwSlots, panelWidthRatio, dividerWidthRatio, digitGapRatio, configResolver,
   onDeckKey, ambient, detailOpacity, toPersianDigits, persianCarPlateLetters,
   PlateType.

3. The exact path of every file matching poster_tokens.dart, annotation_callout.dart,
   poster_header.dart, poster_footer.dart, tech_chip.dart, grid_backdrop.dart,
   corner_brackets.dart — and state clearly whether each lives under the package's
   lib/ or under example/lib/.

4. The name: field from both pubspec.yaml files.

5. Every import line anywhere in example/ that starts with package:plate_number/showcase/.

6. Every place PlateType is switched on or compared, with file and line number.

Use find and grep. Do not open files you don't need. Do not suggest changes.
```

Read the manifest, then correct the paths in every prompt below before pasting them.

---

## Prompt 1 · Delete dead files
**Haiku 4.5**

```
Delete these files and nothing else:

- lib/main.dart
- test/widget_test.dart
- lib/bloc/graph_bloc.dart
- lib/bloc/graph_event.dart
- lib/bloc/graph_state.dart
- lib/widgets/digit_row.dart

Then run flutter analyze and fix any import that referenced a deleted file by removing
that import line. Do not refactor, rename, or reformat anything else.

Out of scope: every other file. Do not touch lib/plate_number.dart.
```

---

## Prompt 2 · Move the poster out of the package
**Sonnet 5 · medium**

```
The package lib/ currently contains showcase-only UI that must not ship to pub.dev.
Move it into the example app.

Move these files, flattening the folder structure:

- lib/showcase/theme/poster_tokens.dart          -> example/lib/poster/poster_tokens.dart
- lib/showcase/widgets/annotation_callout.dart   -> example/lib/poster/annotation_callout.dart
- lib/showcase/widgets/poster_header.dart        -> example/lib/poster/poster_header.dart
- lib/showcase/widgets/poster_footer.dart        -> example/lib/poster/poster_footer.dart
- lib/showcase/widgets/tech_chip.dart            -> example/lib/poster/tech_chip.dart
- lib/showcase/widgets/grid_backdrop.dart        -> example/lib/poster/grid_backdrop.dart
- lib/showcase/widgets/corner_brackets.dart      -> example/lib/poster/corner_brackets.dart

Then delete the now-empty lib/showcase/ tree.

Fix every import that breaks:
- inside the moved files, '../theme/poster_tokens.dart' becomes 'poster_tokens.dart'
- anywhere in example/lib/, 'package:plate_number/showcase/...' becomes a relative
  import to the new example/lib/poster/ location

Do not change a single line of logic, layout, colour, or text in any moved file. This
is a move plus an import fix, nothing more.

Out of scope: lib/car_plate/, lib/bicycle_plate/, lib/widgets/, lib/theme/,
example/lib/device_preview/. Do not create a barrel file.
```

---

## Prompt 3 · One real barrel
**Sonnet 5 · low**

```
Replace the package's public API surface with a single barrel file.

1. Overwrite lib/plate_number.dart with only a `library plate_number;` declaration and
   export directives. Delete `class Calculator` entirely. Export:
   model/plate_number.dart, model/plate_country.dart, bloc/plate_card_bloc.dart,
   theme/plate_theme.dart, car_plate/car_plate_number.dart,
   bicycle_plate/bicycle_plate_number.dart, widgets/show_plate.dart,
   widgets/plate_items.dart, widgets/country_panel.dart, widgets/plate_flag.dart,
   widgets/remove_button.dart, tools.dart, constants.dart

2. Delete lib/car_plate/index.dart and lib/bicycle_plate/index.dart.

3. Anywhere in example/lib/ that imports either deleted index.dart, replace it with a
   single `import 'package:plate_number/plate_number.dart';` and remove the resulting
   duplicate imports.

Then flutter analyze in the package and in example/, and fix only errors caused by
this change.

Out of scope: the contents of any exported file. Do not reorganise lib/ into lib/src/.
```

---

# PHASE B — slim what stays

## Prompt 4 · Slim PlateTheme
**Sonnet 5 · medium**

```
Edit only lib/theme/plate_theme.dart.

Delete these fields entirely — from the constructor, copyWith, lerp, operator ==,
hashCode, PlateTheme.standard(), and their doc comments:

  panelBlue, panelText, flagGreen, flagWhite, flagRed, screwColor,
  panelWidthRatio, dividerWidthRatio, digitGapRatio

Also delete the whole `static PlateTheme lerp(...)` method and the `_lerpDouble`
helper, and the `// ignore_for_file: deprecated_member_use_from_same_package` comment
at the top of the file.

The surviving fields are exactly: plateBackground, plateBorder, ink, dividerColor,
borderWidthRatio, plateRadiusRatio, carAspect, motorcycleAspect, activeColor,
inactiveColor. Keep PlateTheme.standard(), copyWith, of, ==, hashCode and
PlateThemeScope, restricted to those ten. Keep these standard values:

  plateBackground: Color(0xFFFFFFFF), plateBorder: Color(0xFF111111),
  ink: Color(0xFF0A0A0A), dividerColor: Color(0xFF111111),
  borderWidthRatio: 0.04, plateRadiusRatio: 0.09,
  carAspect: 520 / 110, motorcycleAspect: 175 / 110,
  activeColor: Color(0xFF0A0A0A), inactiveColor: Color(0x66666666)

Then flutter analyze and fix ONLY the resulting compile errors elsewhere, by deleting
the reference. Every one is a read of a now-deleted field; no replacement value is
needed anywhere.

Out of scope: PlateCountry, plate_frame.dart layout, any widget's visual output. The
rendered plate must be pixel-identical afterwards.
```

---

## Prompt 5 · PlateFrame becomes a painter
**Sonnet 5 · medium**

```
Edit only lib/widgets/plate_frame.dart, lib/car_plate/car_plate_number.dart and
lib/bicycle_plate/bicycle_plate_number.dart.

Every caller uses PlateFrame as
  Positioned.fill(child: PlateFrame(aspectRatio: .., isCompleted: .., theme: ..,
                                    child: const SizedBox.expand()))
inside a fixed-size Stack. So the child, the AspectRatio and both LayoutBuilders are
computed and discarded. Remove them. New shape:

  class PlateFrame extends StatelessWidget {
    const PlateFrame({super.key, this.theme, this.isCompleted = false});
    final PlateTheme? theme;
    final bool isCompleted;

    @override
    Widget build(BuildContext context) => CustomPaint(
          painter: _PlateFramePainter(
            theme: theme ?? PlateTheme.of(context),
            isCompleted: isCompleted,
          ),
          child: const SizedBox.expand(),
        );
  }

In _PlateFramePainter: delete the screwSlots field, the _paintScrews method and its
call site, and drop screwSlots from shouldRepaint. Keep paint()'s border/face maths
and _borderColor() exactly as they are.

In the two plate widgets, drop the `aspectRatio:` and `child:` arguments at the
PlateFrame call site. Change nothing else in those two files.

Out of scope: plate_items.dart, country_panel.dart, the plate coordinate tables.
```

---

## Prompt 6 · Slim the model, bloc and tools
**Opus 5 · medium**

```
Edit only lib/model/plate_number.dart, lib/bloc/plate_card_bloc.dart,
lib/bloc/plate_card_state.dart and lib/tools.dart.

In lib/model/plate_number.dart:
- PlateNumber holds one typed field: `final List<String?> values;`. Delete valueTypes
  and its copyWith parameter.
- Delete `abstract final class SelectableString`, `abstract final class SelectableInt`,
  and the entire `extension Tool on PlateType` (vehicleType, parseToString).
- Keep PlateType, PlateMode, LetterInputMode and defaultLetterInputMode() for now.
  PlateType is retired in a later prompt; do not touch it here.

In lib/bloc/plate_card_state.dart, rewrite emptyPlateCardState as:

  static PlateCardState emptyPlateCardState(PlateType plateType) => PlateCardState(
        plateNumber: PlateNumber(values: List<String?>.filled(8, null)),
        plateType: plateType,
      );

Both plate types had eight null slots; the only former difference was valueTypes,
which is now deleted. Remove the `throw Error()` branch.

In lib/bloc/plate_card_bloc.dart, replace the ValueIsChanged handler's manual for-loop
with:

  final values = List<String?>.of(state.plateNumber.values)..[event.index] = event.value;
  emit(state.copyWith(plateNumber: state.plateNumber.copyWith(values: values)));

Keep the RemovePlateCard and TypeIsChanged handlers as they are.

In lib/tools.dart, replace the 30-line isDigit() switch with:

  bool isDigit() => length == 1 && codeUnitAt(0) >= 0x30 && codeUnitAt(0) <= 0x39;

Keep toPersianDigits and the Tools extension (isCompleted, isEmpty) as they are, but
drop the `final res =` temporary in isCompleted.

Then flutter analyze in both packages and fix only errors caused by the
List -> List<String?> tightening. Casts like `plate.values[p] as String?` become
redundant: delete the cast, keep the `?? ''`.

Out of scope: any widget's layout or visual output.
```

---

## Prompt 7 · Slim show_plate and delete IranFlag
**Haiku 4.5**

```
Edit only lib/widgets/show_plate.dart and lib/widgets/plate_flag.dart.

show_plate.dart: delete IrCarShow and IrBicycleShow (one-line aliases) and inline them
into ShowPlate's builder, so it returns `const CarPlateNumber(mode: PlateMode.display)`
and `const BicyclePlateNumber(mode: PlateMode.display)` directly. Turn the plate-type
check into a switch over PlateType so the trailing `return const Placeholder();`
disappears. Keep ShowPlate, PlateText, IrCarText and IrBicycleText and their current
behaviour.

plate_flag.dart: delete the deprecated IranFlag class entirely. Keep PlateFlag and
_resolveSize unchanged.

Then flutter analyze and fix any import of a deleted symbol.

Out of scope: country_panel.dart, the plate widgets.
```

---

# PHASE C — generalise (a new country becomes a const)

This is the block you asked for. The chain is:

```
alphabets  ->  specs  ->  one slot widget  ->  one plate widget
           ->  wrappers collapse  ->  PlateType dies  ->  new country is free
```

## Prompt 8 · Alphabets and numerals as data
**Sonnet 5 · medium**

```
Create one new file, lib/model/plate_alphabet.dart. Modify nothing else.

Today two things are hard-coded to Iran: `toPersianDigits` in tools.dart, and
`persianCarPlateLetters` in constants.dart. Both are properties of a plate, not of the
library. This file makes them data.

The file contains exactly:

  import 'package:flutter/foundation.dart';

  /// The set of characters a plate slot will accept, and how they are rendered.
  ///
  /// A slot is not "a digit slot" or "a letter slot" — it is a slot over an
  /// alphabet. Digits and letters differ only in [characters] and [input].
  @immutable
  class PlateAlphabet {
    const PlateAlphabet({
      required this.characters,
      required this.input,
      this.glyphs = const <String, String>{},
    });

    /// Every legal character, in canonical (storage) form. Order is the order a
    /// picker presents them in.
    final List<String> characters;

    /// How the user supplies a character from this alphabet.
    final AlphabetInput input;

    /// Storage form -> display form. Empty means display == storage.
    /// This is where national numerals live.
    final Map<String, String> glyphs;

    bool accepts(String value) => characters.contains(value);

    /// The display form of [value]; falls back to [value] itself.
    String render(String value) => glyphs[value] ?? value;

    static const PlateAlphabet latinDigits = PlateAlphabet(
      characters: ['0','1','2','3','4','5','6','7','8','9'],
      input: AlphabetInput.typed,
    );

    static const PlateAlphabet persianDigits = PlateAlphabet(
      characters: ['0','1','2','3','4','5','6','7','8','9'],
      input: AlphabetInput.typed,
      glyphs: {
        '0':'\u06F0','1':'\u06F1','2':'\u06F2','3':'\u06F3','4':'\u06F4',
        '5':'\u06F5','6':'\u06F6','7':'\u06F7','8':'\u06F8','9':'\u06F9',
      },
    );

    static const PlateAlphabet persianPlateLetters = PlateAlphabet(
      characters: ['ب','ح','د','س','ص','ط','ق','ل','م','ن','و','ه','ی','ت','ژ','گ'],
      input: AlphabetInput.chosen,
    );

    static const PlateAlphabet latinUppercase = PlateAlphabet(
      characters: ['A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
      input: AlphabetInput.typed,
    );
  }

  /// How a character reaches a slot.
  enum AlphabetInput {
    /// Typed straight into a TextField (digits, Latin letters).
    typed,
    /// Selected from a picker, or fed in by the host, because the character is
    /// not on a normal keyboard (Persian plate letters).
    chosen,
  }

Keep the storage form ASCII in every alphabet — the bloc stores canonical characters
and only rendering converts. persianDigits therefore has ASCII characters and a glyph
map, not Persian characters.

Do not modify tools.dart or constants.dart in this prompt; toPersianDigits and
persianCarPlateLetters stay where they are until a later prompt retires them.
```

---

## Prompt 9 · PlateSpec — a plate as a const
**Sonnet 5 · medium**

```
Create one new file, lib/model/plate_spec.dart. Modify nothing else.

A plate is a canvas, a country panel, a list of slots over alphabets, and some fixed
chrome. Two plates that differ only in those values must be the same widget. This file
is the data.

  import 'package:flutter/widgets.dart';
  import 'plate_alphabet.dart';
  import 'plate_country.dart';

  /// One editable position on a plate.
  @immutable
  class PlateSlot {
    const PlateSlot({
      required this.index,
      required this.alphabet,
      required this.left,
      required this.top,
      required this.width,
      required this.height,
      required this.next,
    });

    /// Position in PlateNumber.values.
    final int index;
    final PlateAlphabet alphabet;

    /// Plate-space geometry. [height] doubles as the slot height passed to the
    /// glyph style — do not add a separate field for it.
    final double left, top, width, height;

    /// The index focus advances to when this slot fills. Null unfocuses.
    final int? next;
  }

  /// A painted rule (e.g. the vertical divider on an Iranian car plate).
  @immutable
  class PlateRule {
    const PlateRule({required this.left, required this.top,
                     required this.width, required this.height});
    final double left, top, width, height;
  }

  /// Fixed text printed on the plate face (e.g. "ایران").
  @immutable
  class PlateLabel {
    const PlateLabel({
      required this.text, required this.left, required this.top,
      required this.width, required this.height, required this.glyphHeight,
    });
    final String text;
    final double left, top, width, height;
    /// Passed to the glyph style as the slot height.
    final double glyphHeight;
  }

  /// A complete plate design. Adding a plate — including for a new country — means
  /// adding a const of this type. It must never mean adding a widget.
  @immutable
  class PlateSpec {
    const PlateSpec({
      required this.id,
      required this.country,
      required this.canvasWidth,
      required this.canvasHeight,
      required this.panelLeft,
      required this.panelTop,
      required this.panelWidth,
      required this.panelHeight,
      required this.slots,
      this.rules = const <PlateRule>[],
      this.labels = const <PlateLabel>[],
      this.textDirection = TextDirection.ltr,
      this.borderWidthRatioOverride,
    });

    /// Stable identifier, e.g. 'ir.car'. Used for equality and persistence.
    final String id;
    final PlateCountry country;
    final double canvasWidth, canvasHeight;
    final double panelLeft, panelTop, panelWidth, panelHeight;
    final List<PlateSlot> slots;
    final List<PlateRule> rules;
    final List<PlateLabel> labels;
    final TextDirection textDirection;

    /// Applied via theme.copyWith when non-null.
    final double? borderWidthRatioOverride;

    /// How many values this plate stores. Derived, never hard-coded.
    int get slotCount => slots.length;

    /// The slot at [index], or null.
    PlateSlot? slotAt(int index) {
      for (final s in slots) { if (s.index == index) return s; }
      return null;
    }

    @override
    bool operator ==(Object other) => other is PlateSpec && other.id == id;
    @override
    int get hashCode => id.hashCode;
  }

Then define two consts in a `class PlateSpecs { const PlateSpecs._(); ... }` holder,
using EXACTLY these numbers, lifted verbatim from the current widgets.

PlateSpecs.irCar — id 'ir.car', country PlateCountry.iran, canvas 520 x 110,
panel left 5 top 5 w 52 h 100, textDirection rtl, no borderWidthRatioOverride.
Slots (alphabet persianDigits unless stated):

  index 0  left 65   top 17  w 47  h 76  next 1
  index 1  left 120  top 17  w 47  h 76  next 2
  index 2  left 175  top 17  w 55  h 76  next 3   alphabet persianPlateLetters
  index 3  left 238  top 17  w 47  h 76  next 4
  index 4  left 293  top 17  w 47  h 76  next 5
  index 5  left 348  top 17  w 47  h 76  next 6
  index 6  left 428  top 40  w 32  h 52  next 7
  index 7  left 466  top 40  w 32  h 52  next null

Rules: one — left 404, top 14, width 5, height 82.
Labels: one — text 'ایران', left 412, top 18, width 103, height 16, glyphHeight 16.

PlateSpecs.irBicycle — id 'ir.bicycle', country PlateCountry.iran, canvas 175 x 110,
panel left 8 top 8 w 56 h 46, textDirection rtl, borderWidthRatioOverride 0.07.
No rules, no labels. Every slot alphabet persianDigits, next = index + 1 except 7 -> null:

  index 0  left 74   top 13  w 22  h 36
  index 1  left 104  top 13  w 22  h 36
  index 2  left 134  top 13  w 22  h 36
  index 3  left 8    top 58  w 27  h 44
  index 4  left 41   top 58  w 27  h 44
  index 5  left 74   top 58  w 27  h 44
  index 6  left 107  top 58  w 27  h 44
  index 7  left 140  top 58  w 27  h 44

Do not import or modify any widget file. This prompt produces one data file. It must
compile.
```

---

## Prompt 10 · One slot widget
**Opus 5 · high**

```
Create one new file, lib/widgets/plate_slot_item.dart. Modify nothing else.

lib/widgets/plate_items.dart currently has two widgets, IntegerPlateItem and
StringPlateItem, that differ only in which characters they accept and how the
character arrives. That is a data difference. Replace both with one widget driven by
a PlateSlot.

  class PlateSlotItem extends StatelessWidget {
    const PlateSlotItem({
      super.key,
      required this.slot,
      required this.mode,
      required this.value,
      required this.controller,   // null for AlphabetInput.chosen slots
      required this.focusNode,
      required this.onChanged,    // commits a canonical character, or '' to clear
      required this.onCompleted,  // fires after a non-empty commit
      this.theme,
      this.letterInputMode = LetterInputMode.picker,
      this.onPressed,             // opens the picker, chosen slots in picker mode only
    });

    final PlateSlot slot;
    final PlateMode mode;
    final String? value;
    final TextEditingController? controller;
    final FocusNode focusNode;
    final ValueChanged<String> onChanged;
    final VoidCallback? onCompleted;
    final PlateTheme? theme;
    final LetterInputMode letterInputMode;
    final VoidCallback? onPressed;
  }

Behaviour, ported from the two existing widgets — do not redesign it:

- PlateMode.display: a bare glyph. `SizedBox(width: slot.width, height: slot.height)`
  containing a centred Text of `slot.alphabet.render(value ?? '')`, styled with
  PlateDigit.styleFor(slot.height, theme.ink). Empty value renders nothing.

- PlateMode.input, slot.alphabet.input == AlphabetInput.typed: the existing
  IntegerPlateItem TextField, restyled to a bare glyph with an underline. Keep
  isDense: true, contentPadding vertical slot.height * 0.12, counterText '',
  maxLength 1, textAlign center, the Theme() wrapper for selection colours, and the
  underline colour rule (inactiveColor when empty, activeColor when filled,
  activeColor when focused). Replace the `value.isDigit()` validity check with
  `slot.alphabet.accepts(value)` — that is the only logic change. Keyboard type is
  TextInputType.number when the alphabet's characters are all digits, else
  TextInputType.text.

- PlateMode.input, slot.alphabet.input == AlphabetInput.chosen: the existing
  StringPlateItem behaviour. A focusable slot with an underline and a '؟' placeholder
  in inactiveColor when empty. In LetterInputMode.keyboard it consumes key events and
  commits a character when `slot.alphabet.accepts(ch)`, and commits '' on Backspace.
  In LetterInputMode.hostKeypad it takes focus but consumes nothing. In
  LetterInputMode.picker it is an InkWell calling onPressed.

Important: the widget must NOT read the bloc. StringPlateItem currently wraps itself
in a BlocBuilder — remove that. The value arrives as a parameter. The plate is the
only thing that talks to the bloc.

Do not delete or edit plate_items.dart in this prompt; PlateDigit still lives there
and is used. This file must compile alongside it.
```

---

## Prompt 11 · One plate widget
**Opus 5 · xhigh**

```
Create one new file, lib/widgets/plate_canvas.dart. Modify nothing else.

PlateCanvas renders any PlateSpec. It replaces the duplicated bodies of
CarPlateNumber and BicyclePlateNumber, and it is the only widget that will ever need
to exist for any plate of any country.

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
    /// Escape hatch overriding the default picker sheet. Receives the alphabet to
    /// choose from.
    final Future<String?> Function(PlateAlphabet alphabet)? onChooseCharacter;
    final ValueChanged<int?>? onActiveSlotChanged;
    final VoidCallback? onRemove;
    final bool showRemoveButton;
  }

State behaviour, merged from the two existing states — port it, do not redesign:

- One FocusNode per slot, created in initState from spec.slots, each with
  addListener(_handleFocusChange), disposed in dispose. One TextEditingController per
  slot whose alphabet.input is AlphabetInput.typed.
- _handleFocusChange finds the focused slot index and fires onActiveSlotChanged only
  when the value actually changes.
- In build: resolve theme (widget.theme ?? PlateTheme.of(context)), apply
  spec.borderWidthRatioOverride via theme.copyWith(borderWidthRatio: ..) when non-null,
  resolve _letterInputMode = widget.letterInputMode ?? defaultLetterInputMode(), then
  context.select<PlateCardBloc, PlateNumber>((b) => b.state.plateNumber).
- Push bloc values into the controllers with the existing pattern: assign
  c.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length))
  only when c.text != v. Never assign .text.
- Return, with no intermediate widget-returning helper methods:

  FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: spec.canvasWidth,
      height: spec.canvasHeight,
      child: Directionality(
        textDirection: spec.textDirection,
        child: Stack(children: [ .. ]),
      ),
    ),
  )

  Stack children in this order:
   1. Positioned.fill(child: PlateFrame(isCompleted: plate.isCompleted(), theme: theme))
   2. Positioned(spec.panel*, child: CountryPanel(country: spec.country, theme: theme))
   3. one Positioned per spec.rules, child ColoredBox(color: theme.dividerColor)
   4. one Positioned per spec.labels, child a Text styled with
      PlateDigit.styleFor(label.glyphHeight, theme.ink), textAlign center
   5. one Positioned(left/top/width/height from the slot, child: Center(child:
      PlateSlotItem(..))) per spec.slots

- Each PlateSlotItem gets: the slot, mode, value plate.values[slot.index], its
  controller and focus node, onChanged committing ValueIsChanged(index: slot.index,
  value: v) to the bloc, and onCompleted advancing focus. Focus advance rule: if
  slot.next is null, unfocus. Otherwise look up spec.slotAt(slot.next!). If that
  slot's alphabet.input is chosen AND _letterInputMode is picker, open the picker for
  it. Otherwise request its focus node.
- onPressed is set only when mode is input, the slot's alphabet.input is chosen, and
  _letterInputMode is picker.
- The picker: a private stateless widget, not a method. It shows
  showModalBottomSheet returning a String from the alphabet's characters, using the
  existing LetterPicker + OK button layout, or delegates to widget.onChooseCharacter
  when non-null. On a result, commit it to the bloc and advance focus to slot.next.
- showRemoveButton wraps the whole thing in a Column with the existing
  IconButton(Icons.close).

Every piece of UI above is a widget class. No `Widget _buildX()` methods anywhere in
this file — see CLAUDE.md rule 1.

Out of scope: deleting or editing car_plate_number.dart and bicycle_plate_number.dart.
This prompt only adds the file. It must compile.
```

---

## Prompt 12 · Collapse the two plate widgets
**Opus 5 · high**

```
Edit only lib/car_plate/car_plate_number.dart and
lib/bicycle_plate/bicycle_plate_number.dart.

Replace each file's entire body with a thin StatelessWidget delegating to PlateCanvas.
Keep the public constructor parameters exactly as they are today so no caller breaks:

  CarPlateNumber({super.key, this.mode = PlateMode.input, this.theme,
                  this.onChooseLetter, this.onRemove, this.showRemoveButton = false,
                  this.letterInputMode, this.onActiveSlotChanged})
    -> PlateCanvas(spec: PlateSpecs.irCar, .. all params forwarded ..)

  BicyclePlateNumber({super.key, this.mode = PlateMode.input, this.theme,
                      this.onRemove, this.showRemoveButton = false})
    -> PlateCanvas(spec: PlateSpecs.irBicycle, .. params forwarded ..)

onChooseLetter is `Future<String?> Function()?` and PlateCanvas takes
`Future<String?> Function(PlateAlphabet)?` — adapt it with a lambda that ignores the
alphabet, so the old signature keeps working.

Delete from both files: every static const double coordinate, _digitPositions, the
controller and focus-node maps, initState, dispose, _handleFocusChange, _focus,
_chooseLetter, _digit, _positioned, and the whole build body. Delete now-unused
imports. Keep the doc comments describing the public widget; delete the ones
describing deleted internals.

Then flutter analyze in both packages and hot-restart the example.

Verification before you finish: the car plate and the motorcycle plate render
pixel-identically to before, in both input and display mode, with the letter picker
and the focus-advance chain still working.

Out of scope: plate_canvas.dart, plate_spec.dart, plate_slot_item.dart. If something
doesn't fit, fix it in the caller — do not change PlateCanvas.
```

---

## Prompt 13 · Retire PlateType
**Opus 5 · high**

```
PlateType is a closed enum. A consumer of this package cannot add a value to it, so it
is the single thing preventing anyone from defining their own plate. Replace it with
the spec itself.

Edit lib/bloc/plate_card_bloc.dart, lib/bloc/plate_card_state.dart,
lib/bloc/plate_card_event.dart, lib/model/plate_number.dart, lib/widgets/show_plate.dart
and every call site the analyzer flags.

1. PlateCardBloc takes a PlateSpec instead of a PlateType:
     PlateCardBloc(this.spec) : super(PlateCardState.empty(spec));
   PlateCardState holds `final PlateSpec spec;` in place of `final PlateType plateType;`.

2. PlateCardState.empty becomes:
     static PlateCardState empty(PlateSpec spec) => PlateCardState(
           plateNumber: PlateNumber(values: List<String?>.filled(spec.slotCount, null)),
           spec: spec,
         );
   The hard-coded 8 disappears — slot count is derived from the spec.

3. TypeIsChanged becomes SpecIsChanged(PlateSpec spec), emitting
   PlateCardState.empty(event.spec).

4. ShowPlate dispatches on state.spec rather than switching on PlateType:
   return PlateCanvas(spec: state.spec, mode: PlateMode.display). The car/bicycle
   branch disappears entirely — this is the point of the change.

5. Delete `enum PlateType` from lib/model/plate_number.dart.

6. In example/lib/, plateTypeFor(DeviceType) becomes specFor(DeviceType) returning
   PlateSpecs.irBicycle for mobile and PlateSpecs.irCar otherwise. PlateDisplay takes
   `required this.spec` instead of `required this.plateType`, and passes it to
   PlateCanvas directly — its internal switch over plateType disappears too.

Then flutter analyze in both packages and hot-restart the example. Behaviour must be
identical.

Out of scope: plate_spec.dart, plate_canvas.dart, plate_slot_item.dart, the device
preview, the poster.
```

---

## Prompt 14 · Prove it — a German plate, no widget touched
**Opus 5 · medium**

```
This prompt is a test of the abstraction, not a feature. If it requires editing any
widget file, the abstraction is wrong: stop and report which widget forced the change
instead of editing it.

Edit only lib/model/plate_country.dart and lib/model/plate_spec.dart.

1. In plate_country.dart, add alongside PlateCountry.iran:

     static const PlateCountry germany = PlateCountry(
       code: 'de',
       captionLines: ['D'],
       panelColor: Color(0xFF003399),
       panelTextColor: Color(0xFFFFFFFF),
     );

2. In plate_spec.dart, add PlateSpecs.deCar. It deliberately differs from the Iranian
   plates on every axis the abstraction claims to handle: Latin numerals, a Latin
   alphabet, LTR text, nine slots instead of eight, no divider, no label.

   id 'de.car', country PlateCountry.germany, canvas 520 x 110,
   panel left 5 top 5 w 52 h 100, textDirection ltr, no borderWidthRatioOverride.
   No rules, no labels.

   Slots — indices 0..2 alphabet latinUppercase, 3..4 alphabet latinUppercase,
   5..8 alphabet latinDigits. All top 17, height 76. next = index + 1 except 8 -> null.

     index 0  left 70   w 47
     index 1  left 120  w 47
     index 2  left 170  w 47
     index 3  left 238  w 47
     index 4  left 288  w 47
     index 5  left 348  w 38
     index 6  left 390  w 38
     index 7  left 432  w 38
     index 8  left 474  w 38

3. Add a short doc comment on PlateSpecs stating that adding a plate means adding a
   const here and nothing else.

Verification: add a temporary route or a top-level dev entry in
lib/dev/ that renders PlateCanvas(spec: PlateSpecs.deCar) inside a
BlocProvider(create: (_) => PlateCardBloc(PlateSpecs.deCar)), run it, type into it,
confirm nine slots accept letters then digits with Latin numerals and an LTR layout,
then delete the temporary entry before committing.

Report at the end: the exact list of files you had to edit. It should be two.
```

---

# PHASE D — the showcase

## Prompt 15 · Fix the callout overflow
**Sonnet 5 · medium**

```
Edit only example/lib/poster/annotation_callout.dart.

CalloutWithConnector overflows by about 90px on every callout: it builds
Row(children: [callout, connector]) where the connector is SizedBox(width: 150) and the
callout's body is ConstrainedBox(maxWidth: 300), inside a 360px-wide column.
300 + 150 > 360.

Fix:
- In ConnectorLine, replace the outer SizedBox(width: length) with
  ConstrainedBox(constraints: BoxConstraints(minWidth: 40, maxWidth: length)), keeping
  the inner Row with the Expanded hairline and the 7px dot.
- In CalloutWithConnector, wrap the connector in Flexible(fit: FlexFit.loose, ..) and
  the callout in Flexible(fit: FlexFit.tight, ..), with
  crossAxisAlignment: CrossAxisAlignment.start and mainAxisSize: MainAxisSize.max.
- In AnnotationCallout, delete the ConstrainedBox(maxWidth: 300) around the body Text.
  The parent controls the width now.

After the change, at a 1920x1080 window there must be zero yellow overflow stripes, and
each connector's dot must sit at the inner edge of its column, pointing at the device.

Out of scope: showcase_screen.dart, the callout copy, poster_tokens.dart, the device.
```

---

## Prompt 16 · Per-device callout content
**Haiku 4.5**

```
Create one new file, example/lib/poster/callout_content.dart. Modify nothing else.

The four callouts are currently const AnnotationCallout values inlined in
showcase_screen.dart. They become three sets of four, one per device.

  @immutable
  class CalloutSet {
    const CalloutSet({required this.left, required this.right});
    /// Exactly two callouts, top then bottom.
    final List<AnnotationCallout> left;
    final List<AnnotationCallout> right;
  }

  const Map<DeviceType, CalloutSet> calloutSets = { .. };

Import AnnotationCallout / CalloutSide from annotation_callout.dart and DeviceType from
../device_preview/device_config.dart.

DeviceType.desktop reuses the four existing callouts verbatim:
  left  01 VIEWPORT / One layout, three devices / Mobile, tablet and laptop states animate between each other.
        04 STYLING  / Fully themeable / Spacing, colour and light or dark theme are all yours.
  right 02 PACKAGE  / plate_number / Open-source Flutter package for Iranian vehicle plates.
        03 MODES    / Input & display / Capture plates field by field, or render them read-only.

DeviceType.tablet:
  left  05 TOUCH    / Tap to type / An on-screen pad drives the plate, field by field.
        08 SCALE    / One canvas, any size / A fixed plate space scales to any viewport.
  right 06 LETTER   / Picker on touch / Touch platforms choose the letter from a wheel.
        07 COUNTRY  / Plates are data / A new country is a const, not a new widget.

DeviceType.mobile:
  left  09 VARIANTS / Motorcycle plates / Two-row plates ship in the same package.
        12 STATE    / Bloc-driven / Every field is one event; the plate is pure render.
  right 10 COMPACT  / Small screens / Eight digits stay legible at phone width.
        11 NUMERALS / Native glyphs / Canonical characters in state, national numerals on the face.

All left callouts use CalloutSide.left, all right use CalloutSide.right.

Do not touch showcase_screen.dart.
```

---

## Prompt 17 · The three motifs
**Opus 5 · high**

```
Create one new file, example/lib/poster/callout_motion.dart. Modify nothing else.

The callouts enter as their device fades in and leave as it departs. Three motifs
choreograph the loop. Each motif is a pair (exit of the outgoing set, entry of the
incoming set), and each is a real widget class — no widget-returning functions.

  /// How a set of callouts leaves and the next set arrives.
  enum CalloutMotif {
    /// SWEEP. Exit: slides horizontally off its own side of the screen.
    /// Entry: slides in horizontally from that same side and settles.
    sweep,

    /// TRAPDOOR. Exit: a slot opens beneath the callout, and it falls through and
    /// fades. Entry: a slot opens above the callout's resting place, and it drops
    /// down out of it.
    trapdoor,

    /// SIPHON. Exit: the callout collapses along its connector toward the dot,
    /// shrinking to a point on the line. Entry: it is emitted back out of the dot
    /// and expands into place.
    siphon,
  }

Build one widget per motif, each with the same signature so the rail can swap them:

  class SweepTransition extends StatelessWidget {
    const SweepTransition({
      super.key,
      required this.animation,   // 0 -> 1
      required this.entering,    // false = exit, true = entry
      required this.side,        // CalloutSide, decides which way is "out"
      required this.child,
    });
    ..
  }
  class TrapdoorTransition extends StatelessWidget { .. same parameters .. }
  class SiphonTransition  extends StatelessWidget { .. same parameters .. }

Rules for each:

SWEEP — Transform.translate on X plus Opacity.
  Left-hand callouts move toward negative X, right-hand toward positive X.
  Distance: 520 logical px (comfortably past the 360px rail).
  Exit: X 0 -> ±520, opacity 1 -> 0 over the last 40% only.
  Entry: X ±520 -> 0, opacity 0 -> 1 over the first 40% only.
  Curve: Curves.easeInCubic on exit, Curves.easeOutCubic on entry.

TRAPDOOR — a slot that opens, and the text falling through it.
  Compose: a Stack of the slot (behind) and the translated child (in front), the whole
  thing wrapped in ClipRect so the child is genuinely cut off by the slot's edge.
  The slot is a private widget class drawing a horizontal bar 3px tall in
  PosterTokens.accent at 55% opacity with a 12px accent glow, its width animating
  0 -> the child's width via a FractionallySizedBox, centred on the child's
  horizontal centre.
  Exit: slot opens (widthFactor 0 -> 1) over the first 30%, then the child translates
  Y 0 -> +90 and fades 1 -> 0 over the remaining 70%, then the slot closes back to 0
  over the final 15%.
  Entry: the slot sits ABOVE the child's resting place instead of below (offset the
  Stack alignment). It opens over the first 25%, the child translates Y -90 -> 0 and
  fades 0 -> 1 over the middle, and the slot closes over the final 20%.
  Curve: Curves.easeInQuad on the fall, Curves.easeOutQuad on the drop.

SIPHON — Transform composing scale and translate toward the connector dot.
  The dot is at the callout's device-facing edge: for CalloutSide.left that is the
  right edge, for CalloutSide.right the left edge. Use Alignment(1, 0.12) and
  Alignment(-1, 0.12) respectively as the transform origin, so the collapse aims at
  the connector rather than the block's centre.
  Exit: scale 1 -> 0.04, opacity 1 -> 0 over the last 55%, plus a small X nudge of
  ±18px toward the dot.
  Entry: the reverse — scale 0.04 -> 1, opacity 0 -> 1 over the first 55%.
  Curve: Curves.easeInBack on exit, Curves.easeOutBack on entry, and clamp the scale
  at a floor of 0.0 so the overshoot never inverts the widget.

Also export a dispatcher widget so the rail never switches on the enum itself:

  class CalloutTransition extends StatelessWidget {
    const CalloutTransition({super.key, required this.motif, required this.animation,
                             required this.entering, required this.side,
                             required this.child});
    ..
  }

Its build is a single switch expression over motif returning the right transition
widget. That switch is the only place the enum is read.

This file must compile on its own and import nothing from showcase_screen.dart.
```

---

## Prompt 18 · The rail
**Opus 5 · xhigh**

```
Create one new file, example/lib/poster/callout_rail.dart. Modify nothing else.

CalloutRail owns one side's two callouts and animates them out and in as the device
changes, using the motifs from callout_motion.dart.

  class CalloutRail extends StatefulWidget {
    const CalloutRail({
      super.key,
      required this.device,
      required this.side,
      required this.exitMotif,    // how the OUTGOING set leaves
      required this.entryMotif,   // how the INCOMING set arrives
      this.duration = const Duration(milliseconds: 1500),
    });
    final DeviceType device;
    final CalloutSide side;
    final CalloutMotif exitMotif;
    final CalloutMotif entryMotif;
    final Duration duration;
  }

Rules:

- One AnimationController of `duration`. In didUpdateWidget, when widget.device
  changes, store the outgoing device in _outgoing and call
  _controller.forward(from: 0).
- Exit occupies Interval(0.0, 0.45); entry occupies Interval(0.55, 1.0). Between them
  nothing is visible. Never run both at once.
- Render exactly one set at a time. While _controller.value < 0.5, render _outgoing
  wrapped in CalloutTransition(motif: exitMotif, entering: false, animation: <exit
  interval animation>). At and after 0.5, render widget.device wrapped in
  CalloutTransition(motif: entryMotif, entering: true, animation: <entry interval
  animation>). At rest (controller idle at 1, or at 0 with no outgoing set), render
  widget.device with no transition wrapper at all.
- The set for a device is calloutSets[device]!, then
  side == CalloutSide.left ? set.left : set.right.
- The rail's own layout reproduces the existing _LeftCallouts / _RightCallouts
  structure exactly, including their padding:
    left:  Column(crossAxisAlignment: end)   -> Padding(top: 40) + first callout,
           Spacer(), Padding(bottom: 48) + second callout
    right: Column(crossAxisAlignment: start) -> SizedBox(height: 150), first callout,
           Spacer(), Padding(bottom: 96) + second callout
  Both callouts go through CalloutWithConnector.
- Wrap the whole rail in ClipRect so a departing callout is cut off at the rail's own
  bounds and never paints over the header or the footer.
- The two callouts on a side animate together as one block, not staggered.

No widget-returning functions: the per-side column is a private widget class taking
the CalloutSet and the side.

Do not import showcase_screen.dart. Do not wire this in yet. It must compile alone.
```

---

## Prompt 19 · Wire the rail in, cap the stage
**Opus 5 · xhigh**

```
Edit only example/lib/screens/showcase_screen.dart.

A. Motif schedule. The cycle order is DeviceCycle's `order` list. Add next to it:

  /// The motif pairing for each hop of the loop. Index i describes the hop that
  /// LANDS on order[i]: how the previous set left, and how this set arrives.
  const List<({CalloutMotif exit, CalloutMotif entry})> calloutSchedule = [
    (exit: CalloutMotif.siphon,   entry: CalloutMotif.siphon),   // -> device 1
    (exit: CalloutMotif.sweep,    entry: CalloutMotif.sweep),    // -> device 2
    (exit: CalloutMotif.trapdoor, entry: CalloutMotif.trapdoor), // -> device 3
  ];

  This encodes: device 1 leaves by sweeping out sideways and device 2 sweeps in from
  the side; device 2 falls through a trapdoor and device 3 drops in from one above;
  device 3 siphons into its connector and device 1 is emitted back out of it.

B. Use the rail. Delete _callout01.._callout04 and the _LeftCallouts / _RightCallouts
   widgets. In _WideBody, each 360px column becomes
   CalloutRail(device: .., side: .., exitMotif: .., entryMotif: ..).
   In _StackedBody, build the 2x2 Wrap from calloutSets[device]! with
   showConnector: false.

C. Lift the device up. _WideBody and _StackedBody need the current device and the
   current schedule entry, so the DeviceCycle must sit above them rather than inside
   _DeviceStage. Move it so _PosterBody (or a new private stateful widget in this
   file) owns the cycle and passes (DeviceType device, schedule entry) down to all
   three columns. Keep _DeviceStage's typist, bloc and swap logic byte-identical —
   only its position in the tree moves.

   The rail switches on the FRAME device — the moment the hop fires — not the content
   device, so the callouts leave while the device is still morphing.

D. Cap the stage. Wrap the DeviceFrame in
   Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860,
   maxHeight: 640), child: ..)). The laptop currently renders at its full 1280x830
   body plus a 430px deck, which is why it dwarfs the poster.

No widget-returning functions anywhere in this file — if a build method grows a
helper, that helper becomes a private widget class.

Out of scope: device_frame.dart, device_presets.dart, plate_display.dart,
callout_rail.dart, callout_motion.dart, annotation_callout.dart. Do not retune any
colour here.
```

---

## Prompt 20 · Centre and size the plate on the glass
**Sonnet 5 · low**

```
Edit only example/lib/widgets/plate_display.dart and, for the call site only,
example/lib/screens/showcase_screen.dart.

In PlateMode.input, PlateDisplay returns the plate bare, so the plate's own
FittedBox(fit: BoxFit.contain) expands it to the entire device screen — on the laptop
a 1258x796 glass, which is why the plate is enormous and top-anchored.

Add `final double plateWidthFactor;` defaulting to 0.62, and wrap the plate in both
the display and input branches:

  Center(
    child: FractionallySizedBox(
      widthFactor: plateWidthFactor,
      child: content,
    ),
  )

When a `keyboard` is present it stays flush at the bottom, full width — only the plate
is scaled.

At the showcase call site, pass plateWidthFactor per device: 0.55 desktop, 0.62 tablet,
0.86 mobile.

Out of scope: the plate widgets themselves, device_frame.dart, the callouts.
```

---

## Prompt 21 · Wire the laptop keycaps to the plate
**Opus 5 · medium**

```
The desktop preset passes letterInputMode: LetterInputMode.hostKeypad, meaning "the
host app feeds the character in". LaptopDeck already has onKey, _Key._report() and the
_nonReportingKeys filter; DeviceFrame already has onDeckKey and forwards it. Nothing
passes onDeckKey, so every interactive keycap is currently unreachable.

Edit only the file that owns _DeviceStage's state (showcase_screen.dart, or the widget
prompt 19 extracted it into).

Pass onDeckKey to DeviceFrame, backed by:

  /// A tapped laptop keycap, routed through the active plate slot's alphabet.
  void _onDeckKey(String label) {
    if (_typist.isRunning) return;              // never fight the auto-typist
    final index = _activeSlot;
    if (index == null) return;
    if (label == 'BACKSPACE') {
      _bloc.add(ValueIsChanged(index: index, value: ''));
      return;
    }
    final slot = _bloc.state.spec.slotAt(index);
    if (slot == null || !slot.alphabet.accepts(label)) return;
    _bloc.add(ValueIsChanged(index: index, value: label));
  }

Note this routes through the slot's own alphabet rather than a hard-coded digit or
Persian-letter check, so it keeps working for any plate of any country.

Track _activeSlot by passing onActiveSlotChanged: (i) => _activeSlot = i down through
PlateDisplay to PlateCanvas — add the pass-through parameter to PlateDisplay if it
isn't there.

Verify by hand: with the typist idle, clicking ص on the laptop keyboard puts the letter
on the plate, and clicking a number-row digit fills the focused slot.

Out of scope: laptop_deck.dart, laptop_deck.parts.dart, device_frame.dart,
plate_typist.dart. Do not change the deck's layout or key labels.
```

---

## Prompt 22 · Colour and proportion pass
**Haiku 4.5**

```
Purely visual. Edit only example/lib/poster/poster_tokens.dart,
example/lib/device_preview/device_presets.dart and
example/lib/device_preview/device_painters.dart.

The render currently reads as a black rectangle on a black background. Three targeted
changes, nothing else:

1. device_presets.dart — the laptop is too big and its lid is invisible. Change
   desktop's bodySize from Size(1280, 830) to Size(1180, 740), deck.depth from 430 to
   360, and bezel from EdgeInsets.fromLTRB(11, 22, 11, 12) to
   EdgeInsets.fromLTRB(22, 34, 22, 26) so the aluminium lid actually shows around the
   glass. Leave mobile and tablet alone.

2. device_painters.dart — lift the metal ramp so the body separates from the
   background. In _Metal: highlight -> Color(0xFF3E434C), light -> Color(0xFF2B2F36),
   mid -> Color(0xFF1D2026), shade -> Color(0xFF262A31). Leave deep, edge and glass
   unchanged.

3. poster_tokens.dart — give the backdrop air. bgTop -> Color(0xFF0A1017),
   hairline -> Color(0x1AFFFFFF). Leave bg, accent and every text style unchanged.

No layout edits, no new widgets, no restructuring. Hot-reload and compare against the
reference render before committing.
```

---

# Summary

| # | Prompt | Model | Level |
|---|---|---|---|
| 0 | Recon | Sonnet 5 | low |
| 1 | Delete dead files | Haiku 4.5 | — |
| 2 | Move poster out of package | Sonnet 5 | medium |
| 3 | One real barrel | Sonnet 5 | low |
| 4 | Slim PlateTheme | Sonnet 5 | medium |
| 5 | PlateFrame becomes a painter | Sonnet 5 | medium |
| 6 | Slim model, bloc, tools | Opus 5 | medium |
| 7 | Slim show_plate, delete IranFlag | Haiku 4.5 | — |
| 8 | Alphabets and numerals as data | Sonnet 5 | medium |
| 9 | PlateSpec — a plate as a const | Sonnet 5 | medium |
| 10 | One slot widget | Opus 5 | high |
| 11 | One plate widget | Opus 5 | xhigh |
| 12 | Collapse the two plate widgets | Opus 5 | high |
| 13 | Retire PlateType | Opus 5 | high |
| 14 | Prove it — a German plate | Opus 5 | medium |
| 15 | Fix the callout overflow | Sonnet 5 | medium |
| 16 | Per-device callout content | Haiku 4.5 | — |
| 17 | The three motifs | Opus 5 | high |
| 18 | The rail | Opus 5 | xhigh |
| 19 | Wire the rail in, cap the stage | Opus 5 | xhigh |
| 20 | Centre and size the plate | Sonnet 5 | low |
| 21 | Wire the laptop keycaps | Opus 5 | medium |
| 22 | Colour and proportion pass | Haiku 4.5 | — |

Run 0 → 22 in order, `/clear` between every one.

The load-bearing chains, which must not be reordered or merged:
`8 → 9 → 10 → 11 → 12 → 13 → 14` (the plate generalisation) and
`15 → 16 → 17 → 18 → 19` (the callouts).

Prompt 14 is the falsification test. If it needs a third file, the abstraction leaked
somewhere in 9–13 and that is worth knowing before you build anything else on it.
