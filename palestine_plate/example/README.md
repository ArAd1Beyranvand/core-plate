FREE PALESTINE 🇵🇸🇮🇷 پاینده ایران

GO VEGAN 🌱

==================================


# palestine_plate example

Two apps in one directory, because they answer two different questions.

| Entry point | What it is |
| --- | --- |
| `lib/main.dart` | **How a host uses the package.** One plate, a scheme picker, a usage picker, the `plate_keypad` on-screen pad, a submit button gated on the validator, and a row of generated plates. |
| `lib/gallery.dart` | **What the package contains.** All thirteen specs — nine West Bank, four Gaza — on one scrollable page, every one of them empty and editable. No pickers, no generated values, no auto-fill: tap a slot and type. |

```sh
flutter run                      # the single-plate app
flutter run -t lib/gallery.dart  # the catalogue
```

## The catalogue

**One `PlateCardBloc` per plate.** The bloc holds the values. Share one across
the page and every plate on it becomes the same plate.

**No `PlateInputController` and no `inputSource`.** The single-plate app routes
input through `plate_keypad`, which is one keypad and one controller for one
focused plate — the right design when there is one plate. A catalogue has no
single focus, so its plates take the platform keyboard instead (`PlateCanvas`
falls back to `defaultInputSource()`) and tapping any slot on any card types
into that card.

**The governorate slot still opens a picker**, whatever the input source is. It
is a `chosen` alphabet, so core asks for a character rather than accepting
typing, and `PlateCharacterPicker.show` answers with the thirteen legal letters
— no I, no O. That call is the only reason the catalogue depends on
`plate_keypad` at all.

**Colour is derived, never chosen — and the two schemes derive it differently.**
A West Bank card passes the usage its spec was cut for through
`PSThemes.forUsage`, because the modern scheme encodes no usage on the plate and
the host is the only thing that knows it. A Gaza card reads the usage off the
plate's own last two digits, so *a Gaza card recolours itself as you type* and a
West Bank card does not. That is the most interesting thing on the page and it
is worth typing `07` and then `40` into one to watch.

**Each legacy ink variant is a separate card** because it is a separate spec.
The `ف / P` block carries its own colour on the `PlateCountry`, which no theme
can recolour, so green-on-white, the inverted white-on-green public transport
plate (usage `30`) and the red government plate (`99` / `31`) are three consts
with identical geometry.

**Do not copy the layout.** Thirteen live `PlateCanvas`es on one scrolling page
is a demo, not an app.

## The single-plate app

**Switching scheme resets the plate.** Changing `spec:` on a live `PlateCanvas`
dispatches `SpecIsChanged`, which empties the bloc — it has to, since the old
values are of a different length. `main.dart` re-seeds the new spec from the old
values positionally afterwards, which works only because every scheme here is a
head + a four-digit serial + a tail. A real app should present its pickers
*before* entry begins rather than beside it.

**The submit button is gated on `validateFields`, not on `validate`.** Each
validator's instance `validate` stays deliberately quiet until the user reaches
the last group, so an empty plate reads as valid and gating a button on it would
let a blank plate through. The static `validateFields` judges the groups as
given. `PlateNumber.isCompleted` is not asked at all.

**The usage picker is disabled for Gaza.** The plate already says what it is.

The `dependency_overrides` block in `pubspec.yaml` resolves `palestine_plate`
from this checkout. Delete it when you copy this into an app of your own.
