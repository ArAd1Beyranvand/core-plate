---
name: p12-keypad-package-and-cutover
description: "Refactor phase P12 of the plate_number split — extract packages/plate_keypad and repoint plate_number_holder at the real packages, deciding the fate of the plate_number facade. Use when the user asks to run P12 or do the final cutover."
---

# P12 — Keypad package and cutover

Follow `CLAUDE.md` working style. Requires **P11** committed. Finish analyzer-clean, tests
green, committed in both repos; report diffstat and hashes only.

The last phase. After it, `plate_number_holder` depends on exactly the packages it uses, and
no consumer compiles a country or a soft keyboard they did not ask for.

## Do

### `packages/plate_keypad`

1. `flutter create --template=package packages/plate_keypad`; `resolution: workspace`; add to
   the root `workspace:` list. Dependencies: `flutter`, `core_plate`.
2. Move `lib/widgets/plate_keypad.dart` (compacted in P9) → `lib/src/plate_keypad.dart`,
   with `PlateKeypadTheme`, `kPlateBackspaceKey` and `kPlateKeypadSlide`.
3. Barrel `lib/plate_keypad.dart`.

   The pad depends on `core_plate` only for `PlateAlphabet` — nothing else. If the analyzer
   says otherwise, that coupling is worth reporting rather than accepting.

4. **Consider moving `PlateCharacterPicker` here too** (`docs/split/PLAN.md` §5.4). It is
   Cupertino-flavoured, 62 lines, and `PlateCanvas.onChooseCharacter` already lets a host
   supply its own. If it moves, `core_plate` loses its last `package:flutter/cupertino.dart`
   import and `PlateCanvas.onChooseCharacter` becomes required rather than optional-with-a-
   built-in-default — which is an API break worth its own line in `CHANGELOG.md`. Ask before
   doing it; do not decide unilaterally.

### Cutover

5. `plate_number_holder/pubspec.yaml`:

```yaml
dependencies:
  flutter: {sdk: flutter}
  core_plate:    {path: ../plate-number-upgrade/packages/core_plate}
  iran_plate:    {path: ../plate-number-upgrade/packages/iran_plate}
  germany_plate: {path: ../plate-number-upgrade/packages/germany_plate}
  plate_keypad:  {path: ../plate-number-upgrade/packages/plate_keypad}
  flutter_bloc: ^8.1.4
```

   Update the comment block explaining the layout — it currently describes the pre-split
   single-package arrangement and predicts this change. Replace the prediction with what
   actually happened.

6. Rewrite the ten `package:plate_number/...` imports across `lib/`. The mapping:
   - `PlateSpecs.irCar` / `irBicycle` → `IranPlates.car` / `IranPlates.bicycle` (`iran_plate`)
   - `PlateSpecs.deCar` → `GermanPlates.car` (`germany_plate`)
   - `GermanPlateValidator` → `germany_plate`
   - `PlateKeypad`, `PlateKeypadTheme`, `kPlateBackspaceKey` → `plate_keypad`
   - everything else → `core_plate`

   `lib/dev/flag_panel_gallery.dart` imports four deep paths
   (`package:plate_number/model/plate_country.dart` and friends) rather than the barrel.
   Switch it to barrel imports while you are there — deep imports into a package's `src/`
   will not resolve after this move.

7. `lib/minimal/main.dart` is the smallest use of the library and doubles as documentation.
   After the cutover it should read as two imports and one `PlateCanvas`. If it needs more
   than `core_plate` + `iran_plate`, the split has a seam in the wrong place — report it.

### The facade

8. Settle `docs/split/PLAN.md` §5.2 with the user, then either:

   **(a) Path-only, never published** — delete the root `plate_number` package. The repo root
   becomes the workspace root and nothing else. Note the removal in `CHANGELOG.md`.

   **(b) Published** — keep `plate_number` as the convenience meta-package. Then it needs its
   own `CHANGELOG.md`, `LICENSE` and version, each member package needs the same, and
   `iran_plate`/`germany_plate`/`plate_keypad` must depend on a **published version range** of
   `core_plate` rather than a workspace path, with the workspace used only for local
   development. Write a `docs/split/RELEASING.md` covering the publish order
   (`core_plate` → the rest → `plate_number`) — it is not obvious and getting it wrong ships
   a broken package.

   Do not pick for the user. Ask, then execute one.

### Documentation

9. `README.md` in the root: replace the single-package description with the package table and
   the dependency diagram from `docs/split/PLAN.md` §2, and show the two-line install for the
   common case (one country).
10. Each package gets a short `README.md` saying what it is and what it depends on.
11. `docs/split/PROGRESS.md`: mark P12 done, record the final line counts per package against
    the estimates in `PLAN.md` §3, and note where the estimates were wrong. That table is the
    only honest record of whether this refactor was worth it.

## Verify

```
cd plate-number-upgrade
flutter pub get && flutter analyze && flutter test
for p in packages/*; do (cd "$p" && flutter analyze && flutter test); done

cd ../plate_number_holder
flutter clean && flutter pub get && flutter analyze && flutter test
flutter run --release
```

Then prove the isolation the whole refactor was for — build a throwaway app that depends on
`core_plate` + `iran_plate` only, renders `IranPlates.car`, and does **not** compile:

```bash
grep -rn "germany_plate\|plate_keypad" <throwaway>/.dart_tool/package_config.json
```

Both must be absent. If either is pulled in transitively, a dependency arrow points the wrong
way and P11 or this phase put something in the wrong package.

Finally, delete `plate-number-upgrade/example/` — it has been a dead working copy since Phase 0
and now diverges from the holder in every import.

Expected: no net line change. One more package, the holder honest about what it uses, and the
`~1 600`-lines-for-one-country figure from `PLAN.md` §3 verifiable for the first time.
