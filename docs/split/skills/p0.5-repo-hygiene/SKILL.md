---
name: p0.5-repo-hygiene
description: "Refactor phase P0.5 of the plate_number split — rewrite README.md, which documents a deleted pre-PlateSpec API, and remove or relocate ~9.6MB of untracked-by-pubspec assets shipping inside the package. Use when the user asks to run P0.5 or clean up repo hygiene."
---

# P0.5 — Repo hygiene

Follow `CLAUDE.md` working style. Depends on nothing, blocks nothing — run this any time.
It touches no file any other phase edits except `pubspec.yaml`'s `assets:` list, which every
phase treats as append-only anyway. Finish with `flutter analyze` clean, committed; report
diffstat and commit hash only.

## Why this exists as its own phase

Everything else in this plan is invisible to someone who has not already decided to use the
package. `README.md` is not. It is the first thing pub.dev shows, the first thing a `git clone`
opens, and it currently documents software that does not exist.

## Finding 1 — `README.md` is for a deleted API

Every code sample in the current README:

```dart
import 'package:plate_number/bicycle_plate/index.dart';   // no such directory
import 'package:plate_number/car_plate/index.dart';       // no such directory
...
bloc = PlateCardBloc(PlateType.irCar);   // PlateType does not exist; PlateCardBloc takes a PlateSpec
bloc.add(TypeIsChanged(type));            // TypeIsChanged does not exist
switch (state.plateType) { ... }          // PlateCardState has no plateType field
```

Confirmed by `REFACTOR_MANIFEST.md`'s file tree, which lists `lib/bicycle_plate/`,
`lib/car_plate/`, `lib/model/plate_country.dart` (old 65-line version) as **pre-refactor**
state — the current `lib/` (2 588 lines, `PlateSpec`-based) postdates that README and nobody
updated it. The "Features" list (`spacingScale`, custom letter/removal widgets, rejecting
`.`/`-`/` ` in numeric fields) describes the same dead API.

**Fix.** Rewrite `README.md` against the *current* surface:

1. A working install + minimal usage example — port the shape of
   `plate_number_holder/lib/minimal/main.dart` (the smallest real use of the package), not the
   showcase. Show `PlateCanvas(spec: PlateSpecs.irCar)` inside a `BlocProvider<PlateCardBloc>`,
   end to end, copy-pasteable.
2. A short "what this package renders" section naming the two shipped plate types
   (`PlateSpecs.irCar`/`irBicycle`, `PlateSpecs.deCar`) rather than the old `PlateType` enum.
3. Drop the "Features" list entirely rather than patch it — none of its claims describe the
   current widget. If there is a replacement feature list worth writing, that is new content,
   not a fix, and should wait until the split settles what the public surface actually is
   (`docs/split/PLAN.md` — this README will need a second pass after P12 regardless, once
   installation is "add `iran_plate`" instead of "add `plate_number`"). For now, state plainly
   what the package does in two sentences and move on.
4. Keep the `## Contributing` section as-is.
5. Fix or drop the `<table>` of example media — see Finding 2 below; do not point it at an
   asset this phase deletes.

## Finding 2 — untracked-by-pubspec assets shipping in the package

`assets/` contains, verified against `pubspec.yaml`'s `flutter.assets:` list (which declares
only `de_inspection_sticker.png`, `de_state_seal.png`, `flags/Flag_of_Iran.svg`) and against
`.gitignore` (which excludes `flutter_*.png` but nothing else in `assets/`):

| file | size | referenced by |
|---|---|---|
| `CopyQ.ckUzym.png` | 584 KB | nothing — grepped `lib/`, `README.md`, `CHANGELOG.md`: zero hits |
| `CopyQ.emHrGZ.png` | 361 KB | nothing |
| `CopyQ.fSSaTj.png` | 513 KB | nothing |
| `motor.png` | 27 KB | nothing |
| `example1.png` | 17 KB | `README.md` (the stale one, Finding 1) |
| `example2.gif` | 1.1 MB | `README.md` (same) |
| `car-plate-iran.jpg` | 14 KB | nothing in `lib/`; likely a design reference |
| `germany-license-plate-english-infographic.jpg` | 285 KB | nothing in `lib/`; likely a design reference |

Plus at repo root, also untracked-by-ignore: `screenshot.png`, `screenshot2.png`,
`screenshot3.png` — 1.6 MB combined, none referenced by `README.md` or `lib/`.

The `CopyQ.*` names are a clipboard-manager's auto-generated filenames — these look like
accidental commits, not deliberate assets. None of the eight files is pulled into an app build
(Flutter's asset bundler only loads what `pubspec.yaml` declares), but git does not know that:
they are tracked, and `flutter pub publish` ships a package's full tree minus `.gitignore`d
paths, so all 9.6 MB would go out on a real publish today.

**Fix.**

1. Delete the three `CopyQ.*` files and `motor.png` outright — nothing references them and
   their names indicate they were never meant to be committed.
2. For `example1.png`/`example2.gif`: either keep them and rewrite the README table to still
   reference them (if they genuinely show the current widget — check by eye before deciding),
   or delete them along with the table if they show the old API's UI. Do not keep an asset a
   rewritten README no longer needs.
3. `car-plate-iran.jpg` and `germany-license-plate-english-infographic.jpg` look like the
   design references `docs/split/PLAN.md`'s P8 verification step already points at — move them
   to `docs/references/` rather than `assets/`, so they stay in the repo for that purpose
   without being mistaken for package assets or counting toward a published package's size.
4. Move `screenshot.png`/`screenshot2.png`/`screenshot3.png` to `docs/references/` too, or
   delete them if they are stale — check their content against the current three plate specs
   first; if they show the pre-refactor UI, delete rather than relocate.
5. Add `docs/` exclusions are **not** needed — `docs/` should stay tracked; the point is
   getting non-package images out of `assets/`, which is a published-package directory,
   not making them disappear from the repo.

## Do not

- Do not touch `de_inspection_sticker.png`, `de_state_seal.png`, or `flags/Flag_of_Iran.svg` —
  these are declared, referenced, load-bearing assets. P8/P11 relocate them into their country
  packages later; this phase does not move real assets, only removes or relocates dead ones.
- Do not rewrite `CHANGELOG.md` in this phase. If the README rewrite is worth a changelog
  entry, add one line under a new `## Unreleased` heading — do not restructure the file.
- Do not fix the `docs/districts.json` / `docs/forbidden.json` duplication here — that is
  **P7.5** and **P7**, because it is a validator behavior question, not a hygiene one.

## Verify

```
cd plate-number-upgrade && flutter analyze
```

No `flutter test` impact expected — this phase touches no Dart source. Manually open the
rewritten `README.md` and paste its usage example into a scratch `main.dart` in the holder
project to confirm it actually compiles and runs — that is the whole point of the phase, so
don't skip it.

```bash
du -sh assets/
git status   # confirm the deleted/moved files are staged as such, not left dangling
```

Expected: `assets/` drops from ~10 MB to under 100 KB (the three declared, referenced files),
and the README's first code sample runs.
