FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================


# core_plate_bloc example

One plate, wired the bloc way: a `PlateController` holds the characters, a
`PlateCardBinding` provides a `PlateCardBloc` mirrored onto it, and a `BlocBuilder`
below reads the value straight out of that bloc. Type into the plate and the text
under it updates; press *bloc: set slot 0 to A* and the write goes the other way,
from a hand-dispatched `ValueIsChanged` into the plate.

`core_plate_bloc` ships no country, so the example declares its own four-slot spec —
two letters, two digits. What is on the plate is not the point.

Run it with `flutter run` from this directory.

The `dependency_overrides` block in `pubspec.yaml` resolves `core_plate_bloc` and
`core_plate` from this checkout. Delete it when you copy this into an app of your own.
