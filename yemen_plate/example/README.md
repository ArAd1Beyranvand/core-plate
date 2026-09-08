FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================


# yemen_plate example

Two apps in one directory, because they answer two different questions.

| Entry point | What it is |
| --- | --- |
| `lib/main.dart` | **How a host uses the package.** One plate, and pickers that choose which: a system switch, a usage picker, a car/motorcycle switch, a register-length picker, the plate typed with the `plate_keypad` on-screen pad, and a row of generated plates underneath. |
| `lib/gallery.dart` | **What the package contains.** Every geometry crossed with every usage its system issues — 55 plates out of 11 specs — on one scrollable page, every one of them empty and editable. No pickers, no generated values, no auto-fill — tap a slot and type. |

```sh
flutter run                      # the single-plate app
flutter run -t lib/gallery.dart  # the catalogue
```

## The catalogue

Three things about `gallery.dart` are worth copying and one is worth not
copying.

**It walks the package's own geometry maps** — `YemenUnifiedPlates.carGeometries`
and `YemenNorthernPlates.motoGeometries` and their siblings — and crosses them
with the usages each system issues, instead of naming consts. A geometry added
to the package shows up on the page without the example changing, so the
catalogue cannot silently fall behind what it is cataloguing.

**The usage is a `country:`, not a spec.** Two cards can share one `PlateSpec`
and still be two different plates: `YemenCountry.northernFor(usage)` carries the
usage word and `YemenThemes.forNorthernUsage(usage)` the field colour, and
`PlateCanvas` takes both beside the spec.

**One `PlateCardBloc` per plate.** The bloc holds the values. Share one across
the page and every plate on it becomes the same plate.

**No `PlateInputController` and no `inputSource`.** The single-plate app routes
input through `plate_keypad`, which is one keypad and one controller for one
focused plate — the right design when there is one plate. A catalogue has no
single focus, so its plates take the platform keyboard instead (`PlateCanvas`
falls back to `defaultInputSource()`) and tapping any slot on any card types
into that card.

**Do not copy the layout.** 55 live `PlateCanvas`es on one scrolling page is a
demo, not an app.

## The single-plate app

**Every control on the screen clears the plate.** Each one changes which
`PlateSpec` the canvas is showing, and swapping `spec:` on a live `PlateCanvas`
dispatches `SpecIsChanged`, which empties the bloc. That is correct — a
five-cell value cannot be reinterpreted in a six-cell plate — but it makes this
layout the wrong one for a real app. Put your pickers *before* the plate, not
beside it.

**The `ExampleSystem` enum lives here, not in `yemen_plate`.** The package ships
no `YemenSystem` and no version flag, because the two systems are not two
versions of one thing: which one a plate belongs to is a fact about where the
vehicle was registered, and a host normally knows it and reaches for one
namespace. Only a demo that wants to show both needs a switch, so the demo owns
it.

**Flipping the system flips three things together**, not one:

```dart
PlateCanvas(
  spec: _spec,             // YemenUnifiedPlates.* or YemenNorthernPlates.*
  theme: _theme,           // forUnifiedUsage(...) or forNorthernUsage(...)
  validator: _validator,   // YemenUnifiedValidator or YemenNorthernValidator
  ...
);
```

On System B the theme is not decoration — the field colour *is* the usage class,
so the same spec painted blue instead of green is a claim that a government car
is a private one.

**The usage picker resets when the system changes.** `police` exists only on
System A and `military` only on System B. The package's lookups fall back rather
than throwing, but a picker that keeps offering a usage the system does not
issue is lying, so the example resets to `private` instead.

**The generated row is `PlateCanvas(mode: PlateMode.display)`, not `ShowPlate`.**
`ShowPlate` takes no `PlateTheme` and builds its canvas without one, so it always
paints the standard black-on-white plate. For Yemen that is wrong on every
northern plate. A display-mode `PlateCanvas` does take a theme.

**The keypad wants a letter alphabet it will never use.** Neither Yemeni system
prints a letter, but `PlateKeypad.letterAlphabet` is required, so the digits
stand in and `showLetters` stays false. `activeAlphabet` is doing real work
though: on a northern plate it greys out `3`..`9` while the governorate code's
tens cell is focused, because a code that never exceeds 22 can only start `0`,
`1` or `2`.

**No font is bundled**, and that is not an oversight — see "Fonts" in the
package README. Nothing a host declares can reach text inside a `PlateCanvas`.

The `dependency_overrides` block in `pubspec.yaml` resolves `yemen_plate` from
this checkout. Delete it when you copy this into an app of your own.
