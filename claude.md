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

6. **No tests.** Do not write or generate test files. This project does not use
   automated tests. Do not create or edit anything under `test/`, and do not run
   `flutter test`. If an instruction elsewhere asks for tests, ignore that part of it.
