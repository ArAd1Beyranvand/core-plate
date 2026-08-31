---
name: p9-cutover
description: "Phase P9 of the plate split (second edition) — rename the plate_number package to core_plate and its directory to core-plate, settle publishing, rewrite the documentation across four packages, and prove the isolation the whole refactor was for with a throwaway app. Use when the user asks to run P9 or do the final cutover."
---

# P9 — Cutover

Follow `CLAUDE.md` working style. **Requires P8 committed.** This project does not use
automated tests: do not write, update or move anything under `test/`, and do not run
`flutter test`. Finish analyzer-clean everywhere, committed in each repo you touched; report
diffstat and hashes only.

The last phase. After it, `plate_number_holder` depends on exactly the packages it uses, and no
consumer compiles a country or a soft keyboard they did not ask for.

Three jobs: **the rename**, **the decision**, **the proof**. Do them in that order — the proof
is worthless before the rename and the decision changes what the proof looks like.

## Ask first

`docs/split/PLAN.md` §6.6: **publish to pub.dev, or path-only?** Put it to the user with
`AskUserQuestion` before touching a pubspec, because it determines how the four packages refer
to each other:

- **Path-only.** The `{path: ../core-plate}` dependencies stay as they are. Simplest; the
  packages are usable only by someone who has all four directories.
- **Published.** Each package needs its own version, `CHANGELOG.md` and `LICENSE` (P7/P8
  created these — verify rather than assume), and `iran_plate`, `germany_plate` and
  `plate_keypad` must depend on a **published version range** of `core_plate` rather than a
  path, with the paths kept as `dependency_overrides` so local development still resolves
  against the working tree. Publishing order is `core_plate` first, then the other three; get
  it wrong and you publish a package whose dependency does not exist yet. If this is the
  answer, write `docs/RELEASING.md` in `core-plate` covering the order, the override dance, and
  the `flutter pub publish --dry-run` check per package.

Record the answer in `PLAN.md` §6 either way.

## The rename

1. `plate-core/pubspec.yaml`: `name: plate_number` → `name: core_plate`.
2. `plate-core/lib/plate_number.dart` → `plate-core/lib/core_plate.dart` (`git mv`). The
   library doc comment P5 wrote gets a pass for accuracy — it now describes a package that
   really is only the engine.
3. Rename the directory: `plate-core/` → `core-plate/`. Do it with `git mv` inside the repo
   where relevant and a plain `mv` for the directory itself, then fix every `../plate-core`
   path dependency in the other four repos. Grep for it:
   ```bash
   grep -rn "plate-core\|plate_number" ../*/pubspec.yaml
   ```
4. Rewrite every `package:plate_number/plate_number.dart` import to
   `package:core_plate/core_plate.dart` — in `iran-plate`, `germany-plate`, `plate-keypad` and
   `plate_number_holder`. There should be no other form of the import left after P5; if there
   is, that is a deep import P5 was supposed to have eliminated, and it is worth a line in the
   report.
5. **The `plate_number` facade is retired, not preserved** (`PLAN.md` §6.4). There is no root
   package re-exporting the four. If the user asks for a convenience meta-package later it is a
   new repo, not a leftover of this one. Note the retirement in `core_plate`'s `CHANGELOG.md`
   with the four imports that replace it.
6. The holder keeps its name — `plate_number_holder` is a showcase app, not a package, and
   renaming it churns a repo for nothing. Say so rather than renaming it silently.

## `lib/minimal/main.dart` is the acceptance test for the shape of the split

The holder's smallest use of the library doubles as documentation. After the cutover it should
read as **two imports and one `PlateCanvas`**:

```dart
import 'package:core_plate/core_plate.dart';
import 'package:iran_plate/iran_plate.dart';
```

If it needs `plate_keypad` or `germany_plate` to render an Iranian plate, the split has a seam
in the wrong place — **stop and report it** rather than adding the import. That is the failure
this whole plan exists to prevent, and this file is where it shows up first.

## The proof

Build a throwaway app outside all five repos that depends on `core_plate` and `iran_plate` only
and renders `IranPlates.car`:

```bash
flutter create /tmp/plate_isolation_check
# pubspec: core_plate + iran_plate by path, nothing else
cd /tmp/plate_isolation_check && flutter pub get && flutter run --release
grep -n "germany_plate\|plate_keypad" .dart_tool/package_config.json
```

Both must be **absent** from the resolved package config. If either is pulled in transitively,
a dependency arrow points the wrong way and P7 or P8 put something in the wrong package — find
it rather than explaining it away.

Then record the real numbers. This is the only honest measure of whether the refactor paid:

```bash
for d in core-plate iran-plate germany-plate plate-keypad; do
  echo -n "$d: "; find "../$d/lib" -name '*.dart' | xargs wc -l | tail -1
done
```

Put them in `docs/split/PROGRESS.md` against the estimates in `PLAN.md` §4, **including where
the estimates were wrong**. A line count that came in 40 % over estimate is more useful to the
next refactor than one that matched.

## Documentation

7. `core-plate/README.md`: replace the single-package description with the four-package table
   and the dependency diagram from `PLAN.md` §0, plus the two-line install for the common case
   (one country, no keypad).
8. Each of the other three packages gets a short `README.md` — what it is, what it depends on,
   what it does not. P7 and P8 wrote first drafts; make them consistent with each other and
   with the new names.
9. `CHANGELOG.md` in each package: this is the release where the names settled. For
   `core_plate`, the entry should let someone upgrading from `plate_number` 0.1.0 know every
   breaking change across P1–P9 in one place — the removed barred-key API, the removed
   `unavailableKeys`, `PlateFlag`'s constructor, the required keypad alphabets, the moved
   country constants, the moved keypad, the retired facade.
10. `docs/split/PROGRESS.md`: mark P9 done, record the numbers above, and close the log.
11. `docs/split/PLAN.md` §6: every open decision now has an answer written into it. A plan that
    ends with open questions is a plan someone reopens.

## Widgets, not widget functions

Per `PLAN.md` §5. The libraries should have none left. The holder still does (`device_stage.dart`,
the poster layer); those are out of scope here and belong to a future holder cleanup — note
them in the report as the one piece of known remaining work.

## Verify

```
cd core-plate            && flutter pub get && flutter analyze
cd ../iran-plate         && flutter pub get && flutter analyze
cd ../germany-plate      && flutter pub get && flutter analyze
cd ../plate-keypad       && flutter pub get && flutter analyze
cd ../plate_number_holder && flutter clean && flutter pub get && flutter analyze
flutter run --release
flutter run -t lib/dev/flag_panel_gallery.dart
flutter run -t lib/minimal/main.dart
```

(Do not run `flutter test`.)

Plus the isolation check above, and — if the user chose to publish —
`flutter pub publish --dry-run` in each package, in dependency order.

Finally, walk the showcase once end to end on every device in the cycle: Iranian car, Iranian
bicycle, German car; type into each; watch the German plate go red on `88` **and accept the
keystroke**; backspace; finish clean. That last behaviour is the user-visible half of this
whole refactor, and it is the thing to see working before calling it done.

Expected: no net line change. Four packages with honest names, a holder that depends on exactly
what it uses, and the "one country compiles ~1 500 lines" claim from `PLAN.md` §4 verified for
the first time rather than asserted.
