FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================


# plate_yemen example

Both of Yemen's current plate systems on one screen: a system switch, a usage
picker, a car/motorcycle switch, a register-length picker, the plate itself
typed with the `plate_keypad` on-screen pad, and a row of generated plates
underneath.

Run it with `flutter run` from this directory.

## The bit worth reading

**Every control on the screen clears the plate.** Each one changes which
`PlateSpec` the canvas is showing, and swapping `spec:` on a live `PlateCanvas`
dispatches `SpecIsChanged`, which empties the bloc. That is correct — a
five-cell value cannot be reinterpreted in a six-cell plate — but it makes this
layout the wrong one for a real app. Put your pickers *before* the plate, not
beside it.

**The `ExampleSystem` enum lives here, not in `plate_yemen`.** The package ships
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

The `dependency_overrides` block in `pubspec.yaml` resolves `plate_yemen` from
this checkout. Delete it when you copy this into an app of your own.
