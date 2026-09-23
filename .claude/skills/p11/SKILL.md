---
name: p11
description: "P11 — close the roadmap: golden coverage for every country, the bloc binding test nobody wrote, a shared lint base, version bumps and a publish rehearsal for all seven packages. Invoke with /p11 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** medium · **extended thinking:** off
> **Requires:** every prior phase
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P11 — Verification & publish rehearsal

## Context (assume nothing else)

Ten phases have run. The engine has tests (P1), the type-level debt is gone (P2, P3), the spec explosion
is collapsed (P4, P5), the validators and generators share primitives (P6, P7), the read-only surface is
one widget (P8), the residue is deleted (P9), and one gallery app replaced four (P10).

Three things are still missing, and they are the ones that make the result durable.

**1. Golden coverage is one image.** `palestine_plate/test/goldens/wb_modern_car_green.png` is the only
rendered-pixel assertion in the workspace. It has carried every phase from P2 onward — every "no pixel
moved" check in this roadmap leans on that single file. Iran, Germany and Yemen have no golden at all,
and Yemen just lost 44 specs.

**2. `core_plate_bloc`'s binding has never been tested.** `PlateCardBinding` installs a two-way mirror
between a `PlateController` and a `PlateCardBloc` — a controller write must reach the bloc, a dispatched
`ValueIsChanged` must reach the controller, and neither may loop. P8 added the first tests to that
package, but only for `ShowPlate` and `PlateText`. The mirror itself, the trickiest state plumbing in the
repo, is still unpinned. So is `SpecIsChanged`, which P9 deliberately kept despite having no dispatcher.

**3. Six copies of `analysis_options.yaml`.** `core_plate_bloc`, `iran_plate`, `germany_plate`,
`palestine_plate`, `yemen_plate` and `plate_keypad` each carry a 1,774-byte file; `core_plate` carries a
different 1,545-byte one; the examples carry 1,470-byte copies. P0 deliberately froze these, because
changing lint configuration mid-roadmap would have contaminated every analyze baseline. Now is the time.

And nothing has been rehearsed for publication since P0 discovered that four packages declared a
`core_plate` constraint excluding the `core_plate` they were built against.

## Scope

**In:**
- `core_plate_bloc/test/` — the binding tests.
- `iran_plate/test/`, `germany_plate/test/`, `yemen_plate/test/` — one golden each.
- `plate_gallery/test/catalogue_test.dart` — extend P10's count assertion.
- Root `analysis_options.yaml` — new; every package's file reduced to an `include:`.
- Every package's `version:` and `CHANGELOG.md`.
- `pubspec.yaml` inter-package constraints, updated to the new versions.

**Out — frozen:**
- **All `lib/` source.** If a new golden or binding test fails, that is a finding to report, not a
  licence to change behaviour in the phase whose job is to prove behaviour did not change. Write the
  test, mark it `skip: 'BUG: <one line>'`, and report.
- **`palestine_plate/test/goldens/wb_modern_car_green.png`.** Do not regenerate it. It is the one image
  that has been stable across ten phases; regenerating it here would discard that evidence.
- `plate_number_holder/`.
- Actually publishing. `--dry-run` only. A real `pub publish` is the repo owner's decision.

## Steps

### 1. One golden per country

Model them on `palestine_plate/test/golden_test.dart`, which already works. One image per country, chosen
to exercise what is distinctive:

| Package | Golden | Exercises |
|---|---|---|
| `iran_plate` | `IranPlates.car` with a full value | RTL layout, Persian glyph mapping (`glyphs`), the `ایران` label, the province rule, the flag SVG |
| `germany_plate` | `GermanPlates.car`, valid value | LTR, two `PlateDecal` raster images, the EU panel |
| `yemen_plate` | `YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5)` × `private`, and the same spec × `government` | **the P4 change**: two images from one spec, differing only in `country:` and `theme:` |

The Yemen pair is the important one. Two goldens off a single spec is the whole P4 thesis rendered as
pixels: if `country:` and `theme:` are wired correctly, the two images differ in field colour and panel
word and in nothing else.

Add a `PlateMirror` case too — `carGov2Serial5` prints its number twice, in Latin and iranian numerals,
and nothing renders mirrors under test today.

**And add a golden for each spec P3B corrected**, so the three drift fixes have a pinned appearance
rather than a changelog entry:

| Golden | Why |
|---|---|
| `ye_northern_car_g2s4.png` | the register that used to end at 531 instead of 530 |
| `ye_northern_moto_g2s5.png` | pitch was 42, 42, 41, 42 |
| `ps_wb_modern_moto.png` | pitch was 31.5, 32, 32 |

Generate these **after** P3B, never before — a golden of a drifted layout pins the bug.

### 1b. The register invariant, as a test rather than an assert

P3B added an evenness check to `debugValidateSpec`, which only runs inside an `assert`. Promote it to an
explicit test in every country package, so a release build cannot hide a regression:

```dart
test('every keyed register is evenly pitched', () {
  for (final spec in <PlateSpec>[/* every spec the package exposes */]) {
    expect(() => debugValidateSpec(spec), returnsNormally, reason: spec.id);
  }
});
```

Palestine already enumerates its specs through `PSWestBankPlates.all` and `PSGazaPlates.all`; Yemen's
`carGeometries`/`motoGeometries` maps serve the same purpose post-P4. Iran and Germany need a two-line
literal list. This is the cheapest test in the roadmap and it is the one that keeps P3B true.

Golden tests are platform-sensitive. Follow whatever `palestine_plate/test/golden_test.dart` already does
about fonts and `matchesGoldenFile` tolerance; do not invent a second convention. Generate the images on
the same machine that runs CI, and if the Palestine golden's own setup has a font caveat, inherit it.

### 2. `core_plate_bloc/test/plate_card_binding_test.dart`

The mirror, in both directions, with loop protection:

- Controller → bloc: `controller.setAt(0, 'A')` leaves `bloc.state.plateNumber.values[0] == 'A'`.
- Bloc → controller: dispatching `ValueIsChanged(index: 0, value: 'A')` leaves `controller.valueAt(0) == 'A'`.
- **No loop:** a single controller write produces exactly one bloc emission. Count states with
  `emitsInOrder` or a subscription counter. A mirror that echoes its own write is the failure mode this
  test exists for.
- Idempotence: writing the same value twice emits once (`plate_card_bloc.dart:11-14` guards this — pin it).
- `SpecIsChanged` clears the plate and re-empties the state for the new spec, and the controller follows.
  P9 kept this event precisely because it is coherent API; this is where it earns that.
- Disposal: `PlateCardBinding` closes the bloc it created and does **not** dispose a controller the host
  passed in.
- `PlateCardState` equality is over `plateNumber` **and** `spec` — two states with equal values but
  different specs are unequal.

### 3. Shared lint base

Root `analysis_options.yaml`, taking the country packages' 1,774-byte file as the base (it is the
majority and the stricter of the two). Then each package's file becomes:

```yaml
include: ../analysis_options.yaml
```

with any package-specific rule kept below the include and **commented with why**. `core_plate`'s file
differs — diff it against the base first, and preserve any deliberate difference explicitly rather than
silently adopting the base.

Example pubspecs get `include: ../../analysis_options.yaml`.

**Then re-run analyze everywhere and compare against P0's baseline files in `/tmp/plate-baseline/`.**
New diagnostics are expected — the base is stricter than `core_plate`'s. Fix them or add a scoped
`// ignore:` with a reason. Do not silence a rule globally to avoid one fix.

### 4. Versions and changelogs

Ten phases changed public API. Set versions honestly:

| Package | From | To | Why |
|---|---|---|---|
| `core_plate` | 0.5.0 | **0.6.0** | `PlateCanvas.country`/`PlateView.country` (P3), `plateRegister`/`plateEcho`/`plateStipple` + the register assertion (P3B), `PlateTheme.monochrome` (P2), `PlateSpec.indicesOfGroup` (P7), `PlateTextRow` + `noCharacterChooser` (P8), `GatedPlateValidator` + `isDigits` (P6), removed `PlateInputController` and `activeSlotIn` (P9) |
| `core_plate_bloc` | 0.1.0 | **0.2.0** | `ShowPlate.theme`/`.country` (P8), removed `RemovePlateCard` (P9) |
| `yemen_plate` | 0.2.0 | **0.3.0** | 44 constants removed (P4) |
| `palestine_plate` | 0.1.0 | **0.2.0** | 2 specs and `legacyCarForUsage` removed (P5) |
| `germany_plate` | 0.1.0 | **0.2.0** | validator internals + docs, and P3B may have made `GermanPlates.car` `final` rather than `const` — a source break for a consumer using it in a const context |
| `iran_plate` | 0.1.0 | **0.2.0** | P3B: spec constants become `final`; same source break |
| `plate_keypad` | 0.1.0 | 0.1.1 | the corrupted doc comment (P9) |

Then update every inter-package constraint to match — `core_plate: ^0.6.0` in all six dependents.
**This is the exact failure P0 found**, and shipping it again would be the worst possible ending to a
roadmap that opened by diagnosing it.

Every `CHANGELOG.md` gets an entry naming removed symbols and their replacements, so a consumer can grep
their own code.

### 5. Publish rehearsal

```bash
cd ~/StudioProjects/plate
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  echo "════ $p"; (cd "$p" && flutter pub publish --dry-run 2>&1 | tail -30)
done
```

Check each report for: package size, any `.log`/`.iml`/`build/`/`docs/` survivor, a missing `example/`,
`homepage` reachability, and — most of all — **that no `dependency_overrides` remains anywhere**.
`pub publish` ignores overrides in a consumer's resolution, which is exactly what makes a wrong
constraint invisible until someone else's build breaks.

Finally, prove the constraints resolve *without* the workspace, which is how a real consumer sees them:

```bash
cd /tmp && flutter create --template=app constraint_probe && cd constraint_probe
# add each country package by version (not path) to pubspec.yaml, then:
flutter pub get
```

If a package cannot resolve from its declared constraints alone, the constraint is still wrong. This step
is the actual regression test for P0's finding, and it is the one nothing else in the roadmap covers.

## Verification

```bash
cd ~/StudioProjects/plate

for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate plate_gallery; do
  echo "════ $p"
  (cd "$p" && flutter analyze --no-fatal-infos && flutter test 2>/dev/null)
done

# Golden coverage: at least one per country.
find . -name '*.png' -path '*goldens*' -not -path './plate_number_holder/*' | sort
#   -> palestine (1, original) + iran (1) + germany (1) + yemen (2)

# The Palestine golden is untouched.
git status --porcelain palestine_plate/test/goldens/     # empty

# One lint base.
find . -name analysis_options.yaml -not -path './plate_number_holder/*' -exec wc -l {} +
#   -> root is the only large file; every package file is 1-6 lines

# Constraints match reality.
grep -rn "core_plate:" --include=pubspec.yaml . | grep -v plate_number_holder | grep -v '^\./core_plate/'
#   -> every hit is ^0.6.0

(cd plate_gallery && flutter build web --release && flutter run -d linux --debug)
```

**Success:**
- Every package analyzes clean under one shared lint base and every test suite passes.
- Five new goldens exist, including the Yemen pair that proves the P4 country/theme split renders.
- `core_plate_bloc`'s binding is tested in both directions with no echo loop.
- Versions are bumped, changelogs name every removal, and every inter-package constraint admits the
  version actually in the repo.
- `pub publish --dry-run` is clean for all seven, and a scratch project resolves the country packages
  from their published constraints alone.
- The Palestine golden that carried the whole roadmap is byte-identical to its P0 state.

## Dependencies

All prior phases.

## Line estimate

Goldens + their tests +180 · binding tests +90 · gallery catalogue test +20 · lint consolidation −70 net ·
changelogs +40. **Net ≈ +260**, all of it test and configuration.
