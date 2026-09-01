# core_plate

The country-neutral engine for data-driven vehicle licence plates in Flutter.

A plate is a `const` `PlateSpec`: canvas geometry, a country panel, a list of slots
over alphabets, and optional chrome (rules, labels, decals). The widget layer paints
whatever a spec describes, so **adding a plate — for a new country or an existing one —
means adding a const, never a widget.**

`core_plate` knows no country and ships no assets. It gives you the plate face, the
slots, the input machine and an advisory `PlateValidator`. Plates, alphabets and flags
are data, and each country's live in that country's own package.

## The four packages

| package | directory | what it is | depends on |
|---|---|---|---|
| `core_plate` | `core-plate/` | the engine — geometry, slots, alphabets, input machine, advisory validation | — |
| `iran_plate` | `iran-plate/` | Iran's country panel, Persian alphabets, car + bicycle specs, flag SVG | `core_plate` |
| `germany_plate` | `germany-plate/` | Germany's country panel, car spec + EU stickers, `GermanPlateValidator` | `core_plate` |
| `plate_keypad` | `plate-keypad/` | the optional on-screen keypad and the `chosen`-slot character picker | `core_plate` |

```
iran_plate ────┐
germany_plate ─┼──> core_plate
plate_keypad ──┘
```

`iran_plate` and `germany_plate` never see each other. `core_plate` sees neither. An
app shipping only Iranian plates compiles no German validator, no German PNGs, and no
soft keyboard.

## Install — one country, no keypad

The common case: you draw one country's plates and drive input from the system
keyboard. Depend on two packages.

```yaml
dependencies:
  core_plate: ^0.1.0
  iran_plate: ^0.1.0
```

```dart
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';
```

Add `plate_keypad` only if you want the bundled on-screen keyboard; add
`germany_plate` only if you also draw German plates. `iran_plate`,
`germany_plate` and `plate_keypad` each depend on `core_plate`, so you never
name a version for it that they don't already agree on.

## Usage

`PlateCanvas` renders a plate for a given `PlateSpec` and reads its state from a
`PlateCardBloc` you provide above it in the widget tree. **The bloc is a required
dependency** — `PlateCanvas` calls `context.read<PlateCardBloc>()` and has no
fallback; wrap it in a `BlocProvider<PlateCardBloc>` (or otherwise make one
available) or it throws on build. Create the bloc with the same spec you pass to
the canvas, and if you later swap `spec:` on the canvas, the canvas resets the
bloc to match.

`PlateCanvas` supplies its own `Material`, so it renders correctly outside a
`Scaffold`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocProvider(
              create: (_) => PlateCardBloc(IranPlates.car),
              child: PlateCanvas(
                spec: IranPlates.car,
                onChooseCharacter: (alphabet) async => null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

`onChooseCharacter` is `required` (P7): `core_plate` ships no built-in slot picker.
Pass `PlateCharacterPicker.show` from `plate_keypad`, or any
`Future<String?> Function(PlateAlphabet)` of your own.

## What `core_plate` deliberately does not do

- **It does not know any country.** Not one file in `lib/` names a country, and it
  ships no assets. `grep -rniE "iran|german|persian" lib/` returns nothing, and that
  is the standing proof — a country name here, even in a comment, is the bug.
- **It does not police input.** A `PlateValidator` answers "is this plate valid?" and
  never bars a keystroke. With `PlateCanvas(autoValidate: true)` the canvas paints the
  frame red when the plate is invalid; it still accepts the key.
- **It does not own your keyboard.** `PlateInputSource` lets the host supply
  characters from its own UI (system IME, hardware keyboard, `plate_keypad`, or
  bespoke) through a `PlateInputController`.

## API surface

Everything reachable from `package:core_plate/core_plate.dart` is supported API.
Anything under `lib/src/` that the barrel does not export is an implementation detail
and can change without a major version — in particular the input state machine, the
slot widget and the plate frame.

## The split

`core_plate` was carved out of a single `plate_number` package across phases P1–P9.
The rationale, the phase log and the line-count reckoning are in `docs/split/`
(`PLAN.md`, `PROGRESS.md`). `CHANGELOG.md` lists every breaking change for anyone
upgrading from `plate_number` 0.1.0.
