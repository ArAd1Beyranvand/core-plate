## 0.11.1

**`PlateSlot.color`.** A slot may name the ink its character is printed in;
null keeps `PlateTheme.ink`, so every existing slot is unchanged. The case is
`PlateLabel.color`'s, for a character the user types: Abu Dhabi prints its
emirate code white on a red column of the background, and the theme carries one
ink. `plateRegister` and `plateRegisterAcross` take a `color` for all their
cells.

## 0.11.0

**Breaking: the plate background is sectioned.** `PlateSpec.background` is a
tree of `PlateSection`s — columns and rows whose leaves are a `PlateFill`
(the theme's field, the country's panel colour, the divider colour for a
strip that runs to the edge, or a colour of the design's own) — with `PlatePart.divider` rules between regions. The frame paints the
regions, then the dividers, then the border over all of it, in one painter.

A coloured strip used to be a box on the white face, inset to the border's
inner edge. Two anti-aliased edges met there and the face showed through as a
light seam; and because the box was positioned against the border, any theme
with a different border width moved it. A region now runs out under the
border, and its edges are plate coordinates that ignore the border entirely.

- `PlateSpec.leftBand`, `rightBand` and `innerBand` are removed. A strip that
  divides the plate is a section; a block floating on the face is an entry in
  the new `PlateSpec.bands` list.
- `CountryPanel.paintBlock`: when the background paints a `PlateFill.panel`
  region the panel lays out only its flag and wording.
- `PlateRule` is for marks that do not divide the plate; an edge-to-edge line
  is a divider.

## 0.9.1

**`PlateLabel.color`.** A label may now name the ink it is printed in; null
keeps `PlateTheme.ink`, so every existing label is unchanged. A caption that
sits on a coloured block rather than on the plate's field — reversed out white
over a diplomatic plate's green band, say — is printed in an ink the field's
ink cannot express, and that is data about the label. The alternative was a
second theme per plate, which would have recoloured the digits too.

## 0.9.0

**Breaking: removed deprecated symbols.**

- `PlateInputController` (typedef) — use `PlateController`.
- `PlateController.activeSlotIn(spec)` — use `PlateController.activeSlot`, which
  resolves against the controller's own spec.


**`PlateTextRow` and `noCharacterChooser`.** The plain-text rendering of a
plate — each effective text group rendered through its slots' alphabets, laid
out in the plate's reading direction — is now one exported widget instead of
30 identical lines in both `PlateTextView` and `core_plate_bloc`'s `PlateText`.
`PlateTextView` builds a `PlateTextRow` off its controller; the bloc package
builds the same off its state. `noCharacterChooser` — the required-but-never-
called chooser for `PlateMode.display` — is likewise promoted from a private
copy in each file to one exported function.

## 0.8.0

**`PlateSpec.indicesOfGroup(key)`.** The write-side counterpart to
`valueOfGroup`: it returns the slot indices a named text group covers, or an
empty list when no group carries that key (matching `valueOfGroup`'s empty
string). Walks `effectiveTextGroups`. Country packages that generate synthetic
plate values were each doing this by hand — `yemen_plate` over the raw
`textGroups` field, `palestine_plate` not at all — and now share this.

## 0.7.0

**Validation primitives.** `plate_validator.dart` gains three shared pieces the
country packages were each re-deriving:

- `isDigits(String)` / `isDigitsOfLength(String, int)` — the `^[0-9]+$` test,
  allocation-free, replacing four `RegExp`s across three packages. Eastern Arabic
  numerals are not ASCII digits and read as `false`, the case `int.tryParse` gets
  wrong.
- `GatedPlateValidator` — the "stay quiet until one named register fills" shape
  every validator in the workspace had. Subclasses name a `gateGroup` and
  implement `judge`; they never see the empty-plate case. `PlateValidator` is
  unchanged for hosts with an ungated rule.

No behaviour change: every reason string, `validateFields` signature and check
order is untouched.

## 0.6.0

**The country block is a render-time choice.** `PlateCanvas` and `PlateView`
take an optional `country:` that overrides `PlateSpec.country` for that render,
exactly as `theme:` overrides the inherited `PlateTheme`.

- A design whose panel colours or caption vary along an axis the spec does not
  encode — a vehicle's usage class, say — now passes the block at render time
  instead of minting a second spec identical but for `country:`.
- `PlateSpec` is unchanged: `country` stays required and stays the default, and
  there is no `copyWith`. Spec identity is `id` alone, and `PlateCanvas`'s
  machine rebuild, `PlateController.adoptSpec` migration and card comparison all
  key off it — so a swap of the panel's colours must not look like a spec swap.
  Passing `country:` disturbs neither focus, nor the input machine, nor values.
- Additive: every existing call site is unaffected.

**A plate is registers, not rectangles.** New `plate_layout.dart` exports four
pure functions that build the existing geometry types, so a run of evenly
pitched cells is written once rather than one cell at a time.

- `plateRegister` — `count` equal cells from `left`, stepping by `pitch`
  (default: flush, i.e. `width`).
- `plateRegisterAcross` — `count` cells filling `[left, right)` exactly, for a
  register defined by the span it must fill rather than by cell width. It cannot
  round wrong, which is the point.
- `plateEcho` — one `PlateMirror` per source, laid out as a register: the echo
  band a plate that prints its number twice needs.
- `plateStipple` — `count` identical `PlateRule`s at a constant step.
- All four return unmodifiable, freshly built lists. Nothing is added to
  `PlateSpec`: these build `PlateSlot`, `PlateMirror` and `PlateRule` and the
  widget layer cannot tell the difference.

**`debugValidateSpec` now rejects an unevenly pitched register.** Every keyed
`PlateTextGroup` whose slots share a `top` and `height` must be evenly spaced.
A hand-written run of cells is a for-loop unrolled by hand, and one rounded
coordinate is invisible until someone measures the plate — this assertion found
three such drifts across the country packages, none of which any test could
have caught. Groups spanning two rows are exempt; the check is assert-only and
costs nothing in release.

Note for spec authors: a `const` constructor cannot run a loop, so a spec whose
slot list is generated is `static final` rather than `static const`. That is not
a downgrade — `PlateSpec` equality is over `id` alone and `static final` is
initialised lazily once per isolate — but a const-context use of such a spec
(`const spec = …`) must become `final spec = …`.

## 0.5.0

**One controller, not two.** Since 0.3.0 `PlateController` — the handle that
owns a plate's characters — *extended* a focus-only `PlateInputController`, a
compatibility shape that let every `PlateCanvas(controller: …)` call site keep
compiling through the bloc migration. That migration is done and no consumer
passes a bare focus-only controller any more, so the two are merged.

- **`PlateInputController` is now a deprecated `typedef` for `PlateController`.**
  Existing type annotations still compile, with a deprecation warning. It will
  be **removed in 0.6.0** — rename to `PlateController`.
- Everything the old class carried — `attach`/`detach`, `installValidation`,
  `reportValidation`, `notifyActiveSlotChanged`, and the host-facing focus API
  (`activeIndex`, `isAttached`, `validation`, `submit`, `backspace`,
  `focusFirstEmpty`, `focusSlot`) — is on `PlateController` unchanged.
- **`activeSlotIn(spec)` is deprecated; use `activeSlot`.** The controller knows
  its own spec, so passing one back was redundant. `activeSlotIn` will be
  **removed in 0.6.0**.
- `PlateCanvas.controller` is now `PlateController?` (was `PlateInputController?`
  — the same type after the typedef). A canvas either gets a controller or
  makes its own private one; the `TextField`/`TextEditingController` ownership
  is unchanged — owned when the canvas created it, never disposed when it is
  the host's.
- `PlateInputTarget` — the interface `PlateInputMachine` implements — is
  unchanged.

No behaviour change: this is a rename and a merge.

## 0.4.0

**Breaking. The bloc has left this package, and a plate now owns its own
characters.** `core_plate` no longer depends on `flutter_bloc` or `bloc` — a
`grep` for either in `pubspec.yaml` returns nothing — and no longer decides how
you manage state.

### The plate owns its value: `PlateController`

`PlateCanvas` holds the plate's characters in a `PlateController` — a
`ChangeNotifier`, no dependency beyond Flutter — and needs **nothing above it**.
`PlateCanvas(spec: …, onChooseCharacter: …)` on its own is a complete, working,
editable plate. Pass `controller:` when you want to read or write the value:

```dart
final controller = PlateController(spec: spec);
// controller.values, .valueAt(i), .plateNumber, .isEmpty, .isCompleted
// controller.setAt(i, 'A'), .setValues([…]), .setGroup('serial', '1234'), .clear()
// controller.slot(i)  → ValueListenable<String?> for one position
// controller.completed → ValueListenable<bool>
```

`PlateController` extends `PlateInputController`, so a host that passed a
focus-only controller keeps compiling unchanged. `PlateSelector` rebuilds on a
*derived* piece of a controller only when that piece changes.

Under the hood a keystroke now rebuilds one slot instead of the whole plate:
each slot, each `PlateMirror` and the frame subscribe to just the listenable
they render.

### The bloc moved to `core_plate_bloc`

**Removed from this package** — they are now in the new sibling package
`core_plate_bloc`, unchanged in behaviour:

`PlateCardBloc`, `PlateCardEvent`, `ValueIsChanged`, `RemovePlateCard`,
`SpecIsChanged`, `PlateCardState`, `PlateCardBinding`, `ShowPlate`, `PlateText`.

**Migration for a bloc host, in one line:** add `core_plate_bloc` to your
pubspec, import `package:core_plate_bloc/core_plate_bloc.dart` alongside
`package:core_plate/core_plate.dart`, and put a `PlateCardBinding(controller: …)`
where your `BlocProvider<PlateCardBloc>` was:

```dart
final controller = PlateController(spec: spec);

PlateCardBinding(                       // was: BlocProvider(create: (_) => PlateCardBloc(spec))
  controller: controller,
  child: PlateCanvas(spec: spec, controller: controller, onChooseCharacter: …),
);
```

Everything below it — every `BlocBuilder<PlateCardBloc, PlateCardState>`, every
`context.read<PlateCardBloc>()`, every hand-dispatched `ValueIsChanged`, every
`ShowPlate` — is **unchanged**. The binding keeps the bloc and the controller
holding the same characters in both directions, so a write on either side
reaches the other. Pass `bloc:` to mirror onto a bloc you already hold.

Two differences inside the moved code: `PlateCardBloc.spec` (the field) is gone
— it was dead after construction, only `PlateCardState.spec` was ever read, and
`PlateCardBloc(spec)` still takes the same argument — and `RemovePlateCard` is
deprecated, since nothing dispatched it and `PlateController.clear()` is the
replacement.

**A `PlateCardBloc` above the canvas is no longer adopted.** In 0.2.0 the canvas
*required* one and read its value straight off it; that lookup is gone. A canvas
with a bloc above it and no `PlateCardBinding` simply ignores it, and the plate
will appear not to update the bloc. Wrap it in a `PlateCardBinding`.

### The read-only pair

| Was (bloc-reading) | Now (controller-reading) |
| --- | --- |
| `ShowPlate(emptyPlate: …)` | `PlateView(controller: …, theme: …, emptyPlate: …)` |
| `PlateText(emptyPlate: …, textStyle: …)` | `PlateTextView(controller: …, emptyPlate: …, textStyle: …)` |

Both are in `core_plate` and need no provider above them. `PlateView` also takes
a `PlateTheme`, which `ShowPlate` never did — that is why hosts drawing plates
in several liveries had their own reimplementations of it. One behaviour
difference: `PlateView`'s `emptyPlate` defaults to drawing the blank plate (a
controller always knows its spec), where `ShowPlate` rendered nothing; pass
`emptyPlate: const SizedBox.shrink()` for the old behaviour. `ShowPlate` and
`PlateText` still exist, in `core_plate_bloc`, for hosts that keep a bloc.

### Breaking: swapping `spec:` now keeps the value

`PlateCanvas.onSpecChange` is new in this release and defaults to
`PlateValuePreservation.byGroupKey`. Swapping `spec:` on a live canvas carries
the characters across to the new spec, matching registers by
`PlateTextGroup.key` and truncating only what no longer fits, instead of
emptying the plate, which is what 0.2.0 did (it dispatched `SpecIsChanged`).
`byIndex` copies position by position; `PlateValuePreservation.none` restores
the old wipe:

```dart
PlateCanvas(spec: spec, onSpecChange: PlateValuePreservation.none, …)
```

This is also the fix for a spec swap landing on a canvas that Flutter kept in
place: the canvas rebuilds its input machine for the new spec rather than
holding the previous plate's focus nodes.

## 0.2.0

- **`PlateMirror`** — a read-only echo of a slot's value, painted elsewhere on
  the plate. A plate that prints its number twice (national numerals big, Latin
  digits small beneath) is one value with two presentations, not two slots; a
  mirror carries no focus node, no controller and no position in `slots`, so it
  never reaches `textGroups`, `isCompleted`, focus traversal or validation. Its
  optional `alphabet` is the whole transform, since `PlateAlphabet.glyphs`
  already maps storage form to display form.
- `debugValidateSpec` now bounds-checks mirror boxes and their `source` indices,
  and keys its alphabet-consistency check on `characters` **and** `glyphs`.
  Keying on `characters` alone rejected an alphabet that accepts ASCII digits
  and renders national numerals, which shares `latin.digits`' character list and
  genuinely differs in meaning.

Purely additive: every existing spec compiles unchanged.

## 0.1.0

First pub.dev release. The four packages (`core_plate`, `iran_plate`,
`germany_plate`, `plate_keypad`) are now published with versioned
dependencies — the country and keypad packages depend on `core_plate: ^0.1.0`
rather than a sibling `path:`.

- `PlateCanvas` now wraps its face in a `Material`, so it renders outside a
  `Scaffold` without throwing.
- `PlateCanvas` dispatches `SpecIsChanged` to the `PlateCardBloc` when its
  `spec` changes, keeping the bloc's value list the right length for the new
  spec.

### P9 — the rename, and the split settles

The package is now **`core_plate`** (was `plate_number`); its directory is
**`core-plate/`** (was `plate-core/`); its barrel is
**`package:core_plate/core_plate.dart`** (was `package:plate_number/plate_number.dart`).
The `lib/src/model/plate_number.dart` file — the `PlateNumber` entered-value type — keeps
its name; it is a domain type, not the package.

**Upgrading from `plate_number` 0.1.0 — every breaking change across P1–P9, in one place:**

- **The import.** `package:plate_number/plate_number.dart` →
  `package:core_plate/core_plate.dart`. Path dependency
  `plate_number: {path: ../plate-core}` → `core_plate: {path: ../core-plate}`. These
  packages are path-only; they are not published to pub.dev (`docs/split/PLAN.md` §6.6).
- **The `plate_number` facade is retired, not replaced.** There is no meta-package that
  re-exports the four. A consumer imports exactly what it uses. The four imports that
  replace the old single import:
  ```dart
  import 'package:core_plate/core_plate.dart';     // always
  import 'package:iran_plate/iran_plate.dart';      // if you draw Iranian plates
  import 'package:germany_plate/germany_plate.dart';// if you draw German plates
  import 'package:plate_keypad/plate_keypad.dart';  // if you want the on-screen keypad
  ```
- **Validation no longer blocks input** (P2). `PlateKeypad.unavailableKeys`,
  `GermanPlateValidator.barredNextDigits` / `barredNextLetters`, the `ForbiddenByGroup`
  mixin and `docs/forbidden.json` are **removed**. A plate may now hold an invalid
  value. What survives: `PlateValidator` / `PlateValidation` / `PlateEntry`, a verdict
  and nothing more. `PlateCanvas` gains `validator` and `autoValidate` (default
  `false`); with `autoValidate: true` the frame paints red in `PlateTheme.alertColor`
  and the keystroke still lands. `PlateInputController.validation` exposes the verdict
  on demand.
- **The core names no country** (P3). `PlateCountry.iran` / `.germany` and
  `PlateSpecs` (`irCar`, `irBicycle`, `deCar`) are **removed**. See the country
  packages below.
- **`PlateFlag` takes `required PlateCountry country`** (P3), not `String countryCode`,
  and renders `country.flag` (a `PlateAsset?`). The `country_flags` dependency and the
  `_resolveSize` aspect-ratio guess are gone. New `PlateAsset` / `SvgPlateAsset` /
  `RasterPlateAsset`; `PlateCountry` gains `PlateAsset? flag`.
- **`CountryPanel.country` and `PlateKeypad.digitAlphabet` / `letterAlphabet` are
  `required`** (P3) — they used to default to Iran / Persian.
- **`PlateAlphabet` gains `TextDirection direction` and `String placeholder`** (P3).
  RTL and the empty-slot glyph are read off the alphabet, not sniffed against
  `persianPlateLetters` or hard-coded `'؟'`.
- **`PlateAlphabet.persianDigits` / `persianPlateLetters` moved** (P3) to
  `PersianAlphabets` in `iran_plate`.
- **Grouping moved into the model** (P1). `PlateSpec` gains `effectiveTextGroups` /
  `groupAt` / `renderGroup`; `ShowPlate` no longer computes its own grouping.
- **Keypad grids collapsed** (P4). One `_KeyGrid` for both pads; `_buildDigitKey` /
  `_buildLettersLayer` gone. Internal, but it is why the keypad shrank ~90 lines.
- **Public surface is now a decision** (P5). `lib/src/` holds the implementation;
  `core_plate.dart` exports a chosen list, not every file. Anything under `src/` the
  barrel does not name is not API.
- **Dead weight removed** (P6). `PlateKeypadTheme.copyWith` (unused), the `args`
  dependency, and doc comments that described "a real Iranian licence plate" for
  country-neutral code.
- **The on-screen keypad left core** (P7). `PlateKeypad`, `PlateKeypadTheme`,
  `kPlateBackspaceKey`, `kPlateKeypadSlide` and `PlateCharacterPicker` are in
  `plate_keypad`. **`PlateCanvas.onChooseCharacter` is now `required`** — core ships no
  fallback picker. Core no longer imports `package:flutter/cupertino.dart`.
- **The countries left core** (P8). `IranCountry` / `PersianAlphabets` / `IranPlates`
  are in `iran_plate`; `GermanyCountry` / `GermanPlates` / `GermanPlateValidator` are
  in `germany_plate`. Core ships no assets — no `flutter.assets:` block. `flutter_svg`
  stays: `PlateFlag` renders whatever `SvgPlateAsset` a country hands it.
  `docs/districts.json` was deleted (§6.8); the German district check stays
  shape-only (`^[A-ZÄÖÜ]{1,3}$`).

### P8 — countries extracted to their own packages

- **Breaking: the countries have left core.** `IranCountry`, `PersianAlphabets`
  and `IranPlates` are **removed** from `plate_number` and now live in the
  sibling package `iran_plate` (`path: ../iran-plate`); `GermanyCountry`,
  `GermanPlates` and `GermanPlateValidator` live in `germany_plate`
  (`path: ../germany-plate`). Switch
  `import 'package:plate_number/plate_number.dart';` to
  `import 'package:iran_plate/iran_plate.dart';` or
  `import 'package:germany_plate/germany_plate.dart';` for those names; both
  packages depend on `plate_number`, so the imports coexist. Depend only on the
  countries you actually draw.
- **Breaking: core ships no assets.** The `flutter.assets:` block is gone. The
  two flag SVGs and the two German stickers moved into the packages that name
  them, and the `package:` argument of every `SvgPlateAsset` / `AssetImage`
  literal moved with them in the same commit — an asset reference resolves
  against the bundle of the package that *declares* the file, so a literal and
  its declaration can never be in different packages, even briefly.
- `flutter_svg` remains a dependency: `PlateFlag` renders whatever
  `SvgPlateAsset` a country hands it.
- `docs/districts.json` deleted — see `docs/split/PLAN.md` §6.8. It was read by
  no code and declared in no pubspec, and `germany_plate` chose not to take on
  keeping a district list current.
- This is the claim the whole split was built to make:
  `grep -rniE "iran|german|persian" plate-core/lib/` returns nothing.

### P7 — keypad extracted to its own package

- **Breaking: the on-screen keypad has left core.** `PlateKeypad`,
  `PlateKeypadTheme`, `kPlateBackspaceKey`, `kPlateKeypadSlide` and
  `PlateCharacterPicker` are **removed** from `plate_number` and now live in the
  sibling package `plate_keypad` (`path: ../plate-keypad`). Switch
  `import 'package:plate_number/plate_number.dart';` to
  `import 'package:plate_keypad/plate_keypad.dart';` for those names; the keypad
  package depends on `plate_number` for `PlateAlphabet`, so both imports coexist.
- **Breaking: `PlateCanvas.onChooseCharacter` is now `required`.** It used to
  default to an internal `PlateCharacterPicker`; that picker moved out with the
  keypad, so core no longer has a fallback. Pass
  `PlateCharacterPicker.show` from `plate_keypad`, or any
  `Future<String?> Function(PlateAlphabet)` of your own.
- Core no longer imports `package:flutter/cupertino.dart` anywhere.

### P3 — country decoupling

- **Breaking: the core no longer names a country.** `PlateCountry.iran` /
  `PlateCountry.germany` and the `PlateSpecs` catalogue (`irCar`, `irBicycle`,
  `deCar`) are **removed, not deprecated** — a shim would have re-introduced the
  country names the phase exists to remove. The constants moved to
  `countries/iran.dart` (`IranCountry.iran`, `PersianAlphabets.digits` /
  `.plateLetters`, `IranPlates.car` / `.bicycle`) and `countries/germany.dart`
  (`GermanyCountry.germany`, `GermanPlates.car`), both re-exported from
  `plate_number.dart`. `PlateAlphabet.persianDigits` / `persianPlateLetters`
  likewise moved to `PersianAlphabets`.
- `GermanPlateValidator` moved to `countries/german_plate_validator.dart`
  (still exported from the barrel) — it is a country artifact, and the phase's
  acceptance is that no file outside `countries/` names a country.
- New `PlateAsset` (`SvgPlateAsset` / `RasterPlateAsset`): a country ships its
  own flag asset, named with the package that owns it. `PlateCountry` gains
  `PlateAsset? flag`.
- **Breaking: `PlateFlag` takes `required PlateCountry country`** instead of
  `String countryCode`, and renders `country.flag` (nothing when null). Its
  `_resolveSize` aspect-ratio guess is gone.
- Dropped the `country_flags` dependency and its fallback rendering path;
  Germany now ships `assets/flags/Flag_of_Germany.svg`. Every country renders
  from a vector.
- **Breaking: `CountryPanel.country` and `PlateKeypad.digitAlphabet` /
  `letterAlphabet` are now `required`** — they defaulted to Iran / Persian.
- `plate_number.dart` now also exports `model/plate_box.dart` (`PlateBox` is
  part of the `PlateSpec` surface and consumers need it to build a `PlatePanel`).
- `PlateAlphabet` gains `TextDirection direction` (default `ltr`) and
  `String placeholder` (default `'?'`). `PlateKeypad` reads direction off the
  alphabet instead of comparing against a constant; `PlateSlotItem` reads the
  empty-slot placeholder off the alphabet instead of hard-coding `'؟'`.

- **Breaking: validation no longer prevents input.** `PlateKeypad.unavailableKeys`
  and `GermanPlateValidator.barredNextDigits` / `barredNextLetters` are
  **removed**, not deprecated. They existed to grey out and swallow the keys
  that would complete a forbidden value; a plate library has no business
  refusing a keystroke, and a plate may now hold an invalid value. `_keyEnabled`
  still disables a key outside the active alphabet — that is a fact about the
  alphabet, not a validation rule.
- New `PlateValidator` / `PlateValidation` / `PlateEntry` in
  `validators/plate_validator.dart`: a validator answers one question — is this
  plate valid? — and returns a verdict. There is deliberately no "which keys are
  barred" method.
- `PlateCanvas` gains `validator` and `autoValidate` (default `false`). With
  `autoValidate: true` the canvas paints the invalid state itself, in the new
  `PlateTheme.alertColor`. With it `false` the validator is never called by the
  canvas; read `PlateInputController.validation` and pick your own timing.
- `PlateInputController.validation` exposes the verdict on demand and notifies
  listeners when the verdict changes, not on every keystroke.
- `GermanPlateValidator` is now `const`-constructible and implements
  `PlateValidator`. `GermanPlateValidationResult` is a `typedef` for
  `PlateValidation`, kept for one release. `validateValues(spec, values)` is
  replaced by the `validate(PlateEntry)` override; the spec-free static is
  renamed `validateFields`.
- Removed `docs/forbidden.json`. It duplicated `_forbiddenLetterPairs` /
  `_forbiddenNumbers` by hand and nothing read it; the Dart consts always were
  the source of truth.
- Rewrote `README.md` against the current `PlateSpec`/`PlateCanvas` API.

## 0.0.1 — history as `plate_number`

- **Breaking:** Removed `CarPlateNumber` and `BicyclePlateNumber`. Use
  `PlateCanvas(spec: PlateSpecs.irCar)` and
  `PlateCanvas(spec: PlateSpecs.irBicycle)` instead.
- `PlateCanvas` is now exported from the package root (`plate_number.dart`)
  instead of requiring a deep import.
- **Breaking:** Removed `PlateCanvas.showRemoveButton` and `onRemove`. Hosts
  should render their own remove control alongside `PlateCanvas`.
