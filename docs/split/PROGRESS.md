# Split progress — second edition

Phases are runnable prompts in `docs/split/phases/`, one `SKILL.md` each; paste-ready wrappers
are in `PROMPTS.md`; plan and rationale in `PLAN.md`. All beside this file.

Repos: `plate-core` (the package, renamed to `core-plate` in P9) with `plate_number_holder` as
its sibling. P7 and P8 add `plate-keypad`, `iran-plate` and `germany-plate` beside them.

## First edition — landed, not re-run

| | phase | commit | note |
|---|---|---|---|
| P0 | `example/` → `plate_number_holder` | — | |
| P0.5 | repo hygiene (README, dead assets) | `385c34a` | assets → 3 declared files; refs → `docs/references/` |
| P0.75 | package template correction | `803c795` | `.metadata` → `project_type: package` |
| P1 | slot identity | (in the anim-perf pass) | `PlateSlot` lost `index`/`next` |
| P2 | plate geometry | `d67b511` (holder `35fa127`) | carried the entangled anim-perf pass |
| P3 | input model | `efa7481` (holder `841707d`) | `LetterInputMode` gone, `SlotBehavior` resolved once |
| P4 | input machine + the live state-reuse bug | | `lib/input/` exists; canvas no longer reuses focus nodes across specs |
| P5 | value semantics | | `bloc_concurrency` gone from `pubspec.yaml` |

Old P6 → P12 were **superseded** before they ran. `docs/split/skills/p6-…` through `p12-…`
describe a `packages/`-inside-one-repo layout and a blocking validator, neither of which is the
plan any more. Delete those directories; see `PLAN.md`'s closing mapping.

## Second edition

| | phase | skill | est. net lines | status | commit | actual |
|---|---|---|---|---|---|---|
| P1 | plate text into the model | `p1-plate-text` | −35 | done | `41ea6b0` | +41 |
| P2 | validation stops blocking | `p2-validation-advisory` | −45 lib, −45 holder | done | `71297ce` | see log |
| P3 | country decoupling | `p3-country-decoupling` | −35 | done | `ce4b538` | see log |
| P4 | keypad compaction | `p4-keypad-compaction` | −90 | done | `89961e9` | see log |
| P5 | core public surface | `p5-core-surface` | ±0 | done | `c9299a0` | see log |
| P6 | dead weight | `p6-core-dead-weight` | −40, −1 dep | done | `9c443e6` | see log |
| P7 | extract `plate-keypad` | `p7-extract-keypad` | ±0 | done | `86a0999` | see log |
| P8 | extract `iran-plate` + `germany-plate` | `p8-extract-countries` | ±0 | done | `d3a8009` | see log |
| P9 | cutover: rename, docs, isolation proof | `p9-cutover` | ±0 | done | — (see Log) | +0 net; see below |

(The `todo` rows above were stale — P2–P8 all landed on the dates in the Log; the table was
not kept current between phases. The git log in each repo is authoritative.)

**Baseline: not yet measured.** The first edition's 2 588 figure predates four landed phases
and the animation performance pass; it is stale and must not be quoted. P1's verify step
establishes the real one:

```bash
cd plate-core && find lib -name '*.dart' | xargs wc -l | tail -1
```

Record it here when P1 lands: `lib/` = **2941 lines** (measured 2026-08-31 at `0148dd5`,
before any P1 edit — the second edition's baseline). After P1: 2982 (+41; the estimate was
−35 — the model gained `effectiveTextGroups` / `groupAt` / `renderGroup` with their doc
comments, which outweighs the ~20 lines the shared `_EmptyPlate` and the removed inline
grouping saved in `show_plate.dart`).

Targets, per `PLAN.md` §4: `core_plate` ~1 400, `plate_keypad` ~280, `iran_plate` ~130,
`germany_plate` ~130. P9 measures all four for real.

### P9 — the real per-package `lib/` line counts (measured 2026-09-01, `dart-lang` `wc -l`)

| package | `PLAN.md` §4 estimate | actual | delta | where the estimate was wrong |
|---|---:|---:|---:|---|
| `core_plate` | ~1 400 | **2 441** | **+74 %** | The estimate was the deepest miss in the plan. It assumed P1–P6 would come out net-negative (−285 lines of the six estimates combined); P1 alone came in +41 against −35, and the "moves, plus a barrel that shrinks" P5 estimate of ±0 ignored that `plate_canvas.dart` (485), `plate_slot_item.dart` (357) and `plate_spec.dart` (264) are large, documented widgets/models that never left core and were never going to. `core_plate` was always going to be ~2 400: subtract keypad (~530) and countries (~380) from the ~2 940 P1 baseline and the arithmetic was there to be done. The ~1 400 figure looks like it was carried over from the stale 2 588 first-edition baseline without re-deriving it. |
| `plate_keypad` | ~280 | **530** | **+89 %** | `plate_keypad.dart` is 449 lines on its own. The estimate predates P4's `_KeyGrid` collapse landing *inside* the package's history and predates `PlateCharacterPicker` (62 lines) moving in — §6.7 was answered "yes" after §4 was written. Even so, 280 was optimistic: the keypad has a themed grid, a slide animation, RTL handling and press-flash isolation, none of it free. |
| `iran_plate` | ~130 | **164** | +26 % | Closest of the four. `iran_plates.dart` (93) carries both the car and bicycle specs with their geometry comments; the rest (country, alphabets, barrel) is 71 lines. The estimate was for one spec's worth of data and got two. |
| `germany_plate` | ~130 | **217** | +67 % | `german_plate_validator.dart` is 122 lines — the forbidden-pairs tables and the format regex with its doc comment. The §4 estimate treated Germany as symmetric with Iran (both "~130"), but Germany ships a validator and Iran does not. The asymmetry was visible in the plan's own phase table (P8 "specs, assets, **validator**") and should have been priced in. |
| **total** | ~1 740 | **3 352** | **+93 %** | |

**The headline the isolation check actually verified.** `PLAN.md` §4: "an app that wants
Iranian car plates and drives input from the system keyboard compiles `core_plate` +
`iran_plate` and nothing else." Measured: `core_plate` (2 441) + `iran_plate` (164) = **2 605
lines** of first-party plate code, versus 3 352 for all four packages. The consumer compiles
**neither** `germany_plate` (217) **nor** `plate_keypad` (530) — confirmed by
`/tmp/plate_isolation_check/.dart_tool/package_config.json`, which resolves 44 packages and
names neither. The "~1 500 lines" phrasing in §4 was low by ~70 %; the *shape* of the claim —
one country is a strict subset, the German validator and the soft keyboard are never pulled in
transitively — held exactly.

**What the estimates got right.** The relative ordering (`core_plate` >> `plate_keypad` >
countries) and the direction of every dependency arrow. What they got wrong was the absolute
scale, uniformly, by assuming the six cleaning phases would net out negative — they netted
roughly flat, because every deletion was matched by a documented replacement API. A cleaning
pass that adds an interface for everything it removes does not shrink a package; it improves
it at constant size. That is the single most useful line for the next refactor.

Fill in `actual` as you go — the gap between estimate and reality is the useful part, and it is
the only evidence the next refactor will have.

## Order

Strictly linear P1 → P9, with the honest dependencies spelled out in `PLAN.md` §3. The ones
worth remembering:

- **P2 before P4.** Otherwise P4 carries `unavailableKeys` through into `_KeyGrid` and P2 rips
  it back out — the same work twice.
- **P3 before P4.** P3 removes the Persian defaults and the RTL sniff; P4's shared grid would
  otherwise re-introduce them.
- **P5 after P1–P4.** It decides the public surface, and P1–P4 are still changing it.
- **P8 after P3's grep is empty.** Non-negotiable — moving country code out of a core that
  still names a country produces two broken packages instead of one.

## The three questions

Each is a product decision, asked by exactly one phase, and none of them defaults:

| question | asked by | `PLAN.md` |
|---|---|---|
| does `PlateCharacterPicker` move into `plate_keypad`? — **yes** (2026-08-31) | P7 | §6.7 |
| does `docs/districts.json` back the German district check? — **no, deleted** (2026-08-31) | P8 | §6.8 |
| publish to pub.dev, or path-only? — **path-only** (2026-09-01) | P9 | §6.6 |

All three are answered, and all three are written into `PLAN.md` §6. The plan ends with no
open questions.

## Not tracked as a phase: widgets instead of widget functions

Folded into every phase (`PLAN.md` §5) rather than run as a sweep: each phase converts the
`Widget _buildX` methods in the files it already touches, **only where the widget class does
not come out materially longer than the function**, and reports the ones it left inline on
purpose. Live ones today: `plate_keypad.dart` (P4), holder `device_stage.dart` (P2,
conditionally). The holder's poster layer has more and is out of scope for this plan.

## Do not undo the rebuild isolation

The animation performance pass left the canvas selecting narrowly — `_FrameBinding` watches
`isCompleted`, `_SlotBinding` watches its own `String?`, `_Key` watches a
`ValueListenable<String?>` — so a keystroke rebuilds one slot and a press-flash rebuilds one
key. Several phases edit those files. **A rebuild that is currently scoped to one slot, one
frame or one key stays scoped there.** If a phase finds itself hoisting a `BlocBuilder` up the
tree, it has gone wrong.

## Log

Append one line per phase as it lands: date, commit, anything the prompt got wrong. A phase
prompt that turned out to be inaccurate is worth correcting in its `SKILL.md` before the next
phase inherits the same mistake.

- 2026-08-31 — P1 landed. Grouping fallback moved into `PlateSpec` as
  `effectiveTextGroups` / `groupAt` / `renderGroup`; `valueOfGroup` and `PlateText.build`
  now read `effectiveTextGroups`; shared empty state extracted as `_EmptyPlate`. `slotAt`
  was already a bounds check + index. No barrel change (no new files). Holder unchanged —
  its `device_stage.dart` reads `spec.textGroups` with a `.key` filter, which only matches
  explicitly-declared groups, so `effectiveTextGroups` vs `textGroups` makes no difference
  there; that call site is P2's. No widget functions in `show_plate.dart` to convert.
  Net +41 lib lines vs the −35 estimate — `SKILL.md`'s own budget was optimistic about how
  much three documented model methods cost.
- 2026-08-31 — P7 landed. `../plate-keypad` (package `plate_keypad`) created as a sibling,
  `git init` + scaffold commit, then `plate_keypad.dart` and `plate_character_picker.dart`
  moved in as a plain add/delete (cross-repo, history not preserved; "extracted from
  plate-core at 9c443e6" in the commit). Barrel exports both files whole — every non-private
  top-level name was already public, so no `show:` clauses. `analysis_options.yaml` copied
  from core (4th hand-synced copy; noted in-file). Only core import is
  `package:plate_number/plate_number.dart` for `PlateAlphabet` — analyzer confirms nothing
  else leaked. **PlateCharacterPicker question answered yes**, so `PlateCanvas.onChooseCharacter`
  became `required` (SKILL's "moves files without editing bodies" held for the moved files,
  but this one caller in core and three holder call sites had to change). Core lost its last
  `package:flutter/cupertino.dart`. Holder gained `plate_keypad` path dep; keypad/picker
  imports rewritten in `device_stage.dart`, `plate_typist.dart`, `minimal/main.dart`; pubspec
  layout comment updated to the sibling plan.
- 2026-08-31 — second edition written. Old P6–P12 superseded: validation inverted (no longer
  blocks input), packages become siblings of `core-plate` rather than a `packages/` directory
  inside it, and two new phases (P5 core surface, P6 dead weight) added because the split needs
  a core that has been cleaned rather than one that has merely been rearranged.
- 2026-09-01 — P9 landed. **The rename:** `plate_number` → `core_plate` in
  `pubspec.yaml`; `lib/plate_number.dart` → `lib/core_plate.dart` (`git mv`); directory
  `plate-core/` → `core-plate/` (plain `mv`, git history intact). `lib/src/model/plate_number.dart`
  keeps its name — it holds the `PlateNumber` entered-value type, a domain type, not the
  package. Every `package:plate_number/plate_number.dart` import rewritten to
  `package:core_plate/core_plate.dart` across `iran-plate`, `germany-plate`, `plate-keypad`
  and `plate_number_holder` — all were the barrel form, no deep imports had leaked past P5.
  The four sibling pubspecs and the holder pubspec repointed `plate_number: {path: ../plate-core}`
  → `core_plate: {path: ../core-plate}`. **The decision:** path-only (§6.6) — no version
  ranges, no `dependency_overrides`, no `RELEASING.md`; the three dependants keep
  `publish_to: none`. **The proof:** `/tmp/plate_isolation_check`, a `flutter create` app
  depending on `core_plate` + `iran_plate` (+ `flutter_bloc`) by path only, rendering
  `IranPlates.car`. `flutter build linux --release` succeeded; its
  `.dart_tool/package_config.json` resolves 44 packages and names **neither `germany_plate`
  nor `plate_keypad`**. The "one country compiles a strict subset" claim from §4 is verified
  for the first time. **The numbers:** all four packages came in well over the §4 estimates
  (`core_plate` +74 %, `plate_keypad` +89 %, `iran_plate` +26 %, `germany_plate` +67 %); the
  full reckoning and the reason (six cleaning phases that netted flat, not negative, because
  every deletion shipped a replacement API) is in the P9 line-count table above.
  **`plate_number_holder` keeps its name** — it is an app, not a package. The `plate_number`
  facade stays retired (§6.4); no meta-package was created.
  **SKILL inaccuracy worth noting:** P9's SKILL says `lib/minimal/main.dart` should be "two
  imports and one `PlateCanvas`" and to stop-and-report if it needs `plate_keypad` to render
  an Iranian plate. It does need it: `IranPlates.car` has an `AlphabetInput.chosen` letter
  slot, and §6.7 (answered in P7) deliberately made `PlateCanvas.onChooseCharacter` `required`
  with the picker living in `plate_keypad`. That is not a wrong seam — it is the direct,
  approved consequence of §6.7 — but the SKILL's "two imports" ideal predates that decision
  and is stale. `minimal/main.dart` correctly keeps three imports and passes
  `PlateCharacterPicker.show`. A future edit to `p9-cutover/SKILL.md` should reconcile the
  two.
- P9 also swept the leftover `flutter create` scaffold: `iran-plate/test/` and
  `germany-plate/test/` held `Calculator`/`expect` stubs that broke `flutter analyze`
  (undefined identifiers). Removed — this project runs no automated tests (`CLAUDE.md`).
  The holder's own scaffold `test/widget_test.dart` was already gone.
- **Known remaining work, unchanged from the plan:** the holder still has widget-returning
  functions in `device_stage.dart` and the poster layer (`PLAN.md` §5). That is a future
  holder cleanup, explicitly out of scope for the split. The libraries have none.

## The split is done

P1 → P9 complete. Four packages with honest names (`core_plate`, `iran_plate`, `germany_plate`,
`plate_keypad`), each depending on exactly what it uses; a holder that depends on all four by
path and would not compile a German validator or a soft keyboard to show an Iranian plate; and
the "one consumer compiles a subset" claim proven by a throwaway app rather than asserted. No
open decisions remain in `PLAN.md` §6. This log is closed.
