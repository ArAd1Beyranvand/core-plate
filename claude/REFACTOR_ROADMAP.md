# REFACTOR_ROADMAP — plate monorepo

Twelve phases, each self-contained, each leaving `flutter analyze` clean and every app running.
Run one per Claude Code session with `/clear` between them. Read `AUDIT_DIAGNOSIS.md` for the evidence behind each.

**Philosophy: data structures first, behaviour second, surface last.**
P0–P1 buy the safety net. P2–P3 fix the *types*. P4–P8 propagate those types through behaviour. P9–P11 clean the surface.

---

## Phase index

| Phase | Title | Changes | Δ Lines | Model | Dependencies |
|---|---|---|---:|---|---|
| **P0** | Workspace & constraint baseline | 9 pubspecs, root `pubspec.yaml`, `.gitignore` | ±0 Dart<br>−180 yaml | Sonnet 5 low | — |
| **P1** | Core test harness | `core_plate/test/` (new, 5 files) | **+530** | Opus 5 high | P0 |
| **P2** | `PlateTheme.monochrome` primitive | `plate_theme.dart`, `palestine_themes.dart`, `yemen_themes.dart` | −95 | Sonnet 5 medium | P1 |
| **P3** | Render-time country override | `plate_canvas.dart`, `plate_view.dart`, `core_plate.dart` | +75 | Opus 5 high | P1 |
| **P3B** | Register geometry primitive | `plate_layout.dart` (new), `plate_spec.dart`, all 4 country spec files | **−315** | Opus 5 high | P1 |
| **P4** | Yemen: collapse the usage axis | `northern_plates.dart`, `unified_plates.dart`, `yemen_country.dart` | **−700** | Opus 5 high | P3 *(P3B first if possible)* |
| **P5** | Palestine: collapse the colour clones | `west_bank_plates.dart`, `palestine_country.dart` | −70 | Sonnet 5 medium | P3 |
| **P6** | Validation primitives in core | `plate_validator.dart` + 3 country validators | −60 | Sonnet 5 medium | P1 |
| **P7** | `PlateSpec.indicesOfGroup` + spec-driven generators | `plate_spec.dart`, both serial generators | +10 | Sonnet 5 low | P1 |
| **P8** | One text renderer, one no-op chooser | `plate_view.dart`, `show_plate.dart` | −45 | Sonnet 5 low | P1 |
| **P9** | Dead weight removal | deprecated API, docs, artefacts, stale comments | −140 Dart<br>−2.8 MB | Sonnet 5 low | P2, P4, P5, P6, P7, P8 |
| **P10** | `plate_gallery/` consolidation | new app; 7 `example/` dirs replaced | **−1,230** | Opus 5 high | P4, P5, P9 |
| **P11** | Verification & publish rehearsal | goldens, binding test, `pub publish --dry-run` | +260 | Sonnet 5 medium | all |
| **P12** | Animation frame budget | `plate_canvas.dart`, `plate_keypad.dart`, PS example | +130 | Opus 5 medium | P1 *(P10 helps)* |

**Net: ≈ −1,650 Dart lines** (12,449 → ~10,800), while test coverage rises from 542 to ~1,515 lines and the untested share of the engine falls from 100% to near zero.

---

## Model, reasoning level and thinking

One session per phase. "Thinking" means extended thinking on or off.

| Phase | Title | Model | Level | Thinking | Why this setting |
|---|---|---|---|---|---|
| **P0** | Workspace & constraint baseline | Sonnet 5 | low | **off** | Mechanical YAML edits from an explicit table. The one judgement call — what to do about the failing golden — is a stop-and-ask, not a reasoning problem. |
| **P1** | Core test harness | Opus 5 | high | **on** | Must derive correct expectations for `adoptSpec`'s `byGroupKey` migration from prose alone, with no reference implementation to check against. The hardest reasoning in the roadmap. |
| **P2** | `PlateTheme.monochrome` | Sonnet 5 | medium | **off** | One small primitive, then 15 one-for-one substitutions verified by a golden. Mechanical once the constructor is written. |
| **P3** | Render-time country override | Opus 5 | high | **on** | The `copyWith`-vs-override decision turns on how `spec.id` interacts with `didUpdateWidget`, `adoptSpec` and equality. Getting it wrong silently corrupts value migration. |
| **P3B** | Register geometry | Opus 5 | high | **on** | Arithmetic correctness across 281 literals, three deliberate pixel corrections, and a `const`→`final` migration whose blast radius has to be reasoned about, not guessed. |
| **P4** | Yemen: collapse the usage axis | Opus 5 | high | **on** | Deletes 44 constants and two lookup structures across 1,980 lines while proving no geometry moved. The largest irreversible change in the roadmap. |
| **P5** | Palestine: collapse colour clones | Sonnet 5 | medium | **off** | Same shape as P4 at 1/10 the size, and a golden test catches any mistake immediately. |
| **P6** | Validation primitives | Sonnet 5 | medium | **on** | Substitutions are mechanical, but **check order is observable** — which reason an invalid plate reports depends on it, and Palestine's tests assert exact strings. Thinking on for the ordering. |
| **P7** | `indicesOfGroup` + generators | Sonnet 5 | low | **on** | Small diff, one subtle constraint: the `rng.nextInt` draw order must not change or every seeded fixture shifts. Thinking on for that alone. |
| **P8** | Core surface consolidation | Sonnet 5 | low | **off** | A straight extraction of one duplicated 30-line widget, plus two additive parameters. |
| **P9** | Dead weight removal | Sonnet 5 | low | **off** | Deletion from an explicit list. *The file/artefact half alone is safe on **Haiku 4.5** if you want to split the session — but the doc-comment rewrites are writing, not deleting, so keep those on Sonnet.* |
| **P10** | `plate_gallery/` consolidation | Opus 5 | high | **on** | Writes a new application, designs the catalogue contract, and must merge two divergent widget sets without letting country concepts leak into shared code. |
| **P11** | Verification & publish rehearsal | Sonnet 5 | medium | **off** | Goldens, version bumps and a dry-run against a checklist. Procedural. |
| **P12** | Animation frame budget | Opus 5 | medium | **on** | Diagnosis, not transcription: ten candidates must be weighed against a profile, and the phase has to know when to stop. Medium rather than high because each individual fix is small. |

**Six phases on Sonnet, five on Opus, one splittable to Haiku.** If you are rationing Opus, P3B and P4
are the two that most repay it — both are irreversible and both touch geometry that no test currently
guards.

---

## Critical path

```
P0 ──► P1 ──┬──► P2 ──────────────────────────┐
            ├──► P3B ─┐                       │
            ├──► P3 ──┼──► P4 ──┐             │
            │         └──► P5 ──┤             │
            ├──► P6 ──────────────┤            ├──► P9 ──► P10 ──► P11
            ├──► P7 ──────────────┤            │           │
            └──► P8 ──────────────┘            │           └──► P12
```

P12 (animation) depends only on P1 and can be pulled forward at any time — if the lag is reproducible
today, measure it today. It is placed after P10 only because profiling one gallery app beats profiling
four demos.

P2, P3B, P6, P7 and P8 are mutually independent and can run in any order (or in parallel worktrees) once
P1 lands. P4 and P5 are independent of each other; both need P3.

**P3B before P4 if you can.** P4 collapses 55 Yemen specs to 11; doing that over register-form geometry is
cleaner than converting 281 literals afterwards. Neither blocks the other — the end state is identical.

---

## On the size difference between packages

`germany_plate` is 245 lines and `yemen_plate` is 3,168. That 13× spread is the most visible thing about
this repo, and it is mostly **not** debt. Per distinct plate geometry, counting code only:

| Package | code | real geometries | code / geometry |
|---|---:|---:|---:|
| `germany_plate` | 150 | 1 | 150 |
| `iran_plate` | 180 | 2 | 90 |
| `palestine_plate` | 904 | 13 | 70 |
| `yemen_plate` | 1,817 | 11 *(55 declared)* | 165 |

All four are within about 2× of each other per plate, and Palestine is the most economical in the repo.
Yemen is big because Yemen has eleven plate designs across two concurrent national systems, and because a
third of the file is doc comments recording calibration provenance — which is a feature, not weight.

The excess is two specific, separable things, and both have a phase:

- **44 of Yemen's 55 specs are usage clones** → P4, ≈ −700.
- **Every regular layout is a `for` loop unrolled by hand** → P3B, ≈ −315, and it closes three arithmetic
  drifts that no existing check can see.

After both, Yemen sits near 105 code lines per geometry — below Germany's 150 — and the remaining spread
is the honest cost of modelling eleven plates instead of one.

---

## Standing rules for every phase

1. **Frozen unless the phase says otherwise.** `plate_number_holder/` is out of scope entirely and is never read, referenced, or built. `pubspec.lock` and everything under `.dart_tool/`, `build/` and `*.iml` is never hand-edited — a phase may cause `flutter pub get` to regenerate a lockfile, and that is fine, but no phase edits one.
2. **`plate_canvas.dart`'s subscription architecture is frozen** through P8. The per-slot `ValueListenableBuilder` bindings, the resolved-once `behaviors` list, `_PlateFaceClipper`'s `_overlap = 0.75` seam fix, and the post-frame active-index announcement are all correct and load-bearing for rendering and animation timing. A phase may *add* a parameter to `PlateCanvas`; none may restructure its build.
3. **Every phase ends green.** From the repo root:
   ```bash
   for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
     (cd "$p" && flutter analyze --no-fatal-infos) || echo "FAIL: $p"
   done
   (cd core_plate && flutter test)
   (cd palestine_plate && flutter test)
   ```
4. **No behaviour change without a test that pins it.** After P1, any phase that changes engine semantics adds or updates a test in the same commit.
5. **Do not consult prior plans.** `core_plate/docs/`, `REFACTOR_MANIFEST.md`, `PLATE_CONTROLLER_PLAN.md` and the root `PROMPT_*.md` files describe work that may or may not have happened. P9 deletes them. Until then, treat them as noise.
6. **One phase, one session.** `/clear` between phases. Each skill file is written to be pasted cold.

---

## Baseline to capture before P0

The Palestine golden test appears to be failing: `palestine_plate/test/failures/` holds four diff images for `wb_modern_car_green`, all newer than `test/goldens/wb_modern_car_green.png`. **Record the true starting state before touching anything** — a phase cannot claim "tests still pass" against an unknown baseline:

```bash
cd palestine_plate && flutter test 2>&1 | tee /tmp/baseline-palestine.txt
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos) 2>&1 | tee "/tmp/baseline-analyze-$p.txt"
done
```

If the golden is genuinely failing, decide *in P0* whether to re-baseline it (`flutter test --update-goldens`) or fix it, and record which. Every later phase compares against that decision.

---

## Gallery app plan (P10, summarised)

**Target:** one standalone `plate_gallery/` at the repo root, depending on all five country packages plus `plate_keypad`. Every `<package>/example/` is reduced to a single ~30-line `main.dart` that renders one plate and nothing else — the pub.dev example, not a showcase.

**Why it is one small phase and not the whole project:** the four showcase apps duplicate each other because there is no shared *catalogue* contract. Palestine exposes `.all` lists; Yemen exposes `carGeometries`/`motoGeometries` maps plus `car()`/`moto()`; Iran and Germany expose nothing. P10 introduces a tiny `PlateCatalogEntry { spec, theme, country, validator, label }` record in the gallery app itself — **not in core** — and one adapter file per country. That is the entire consolidation.

**Acceptance criteria:**
- `plate_gallery/` builds and runs on Linux desktop and Chrome; `flutter analyze` clean.
- Every spec reachable in the old four apps is reachable in the gallery, verified by counting entries against `PSWestBankPlates.all + PSGazaPlates.all` (13), the Yemen geometry set post-P4 (11 × usages), `IranPlates` (2) and `GermanPlates` (1).
- No `example/` directory contains a second `void main()`.
- `_PlateStage`, `_Section`, `_PickerRow` and `_SampleCard` exist exactly once in the repo.
- No country package gains a dependency; the gallery depends on countries, never the reverse.
- Total example + gallery Dart is under 1,200 lines (from 2,386).

---

## Phase skill files

One per phase, in this directory, each ready to paste into a fresh Claude Code session:

```
claude/P0_workspace_baseline.md      claude/P6_validation_primitives.md
claude/P1_core_test_harness.md       claude/P7_group_indices.md
claude/P2_theme_monochrome.md        claude/P8_core_surface.md
claude/P3_country_override.md        claude/P9_dead_weight.md
claude/P3B_register_geometry.md      claude/P10_plate_gallery.md
claude/P4_yemen_usage_axis.md        claude/P11_verification.md
claude/P5_palestine_colour_clones.md claude/P12_animation_frame_budget.md
```

`P3` and `P3B` share a number because they are siblings, not a sequence: both add a core primitive, both
depend only on P1, and neither depends on the other. The **Dependencies** column is the ordering, not the
phase number.
