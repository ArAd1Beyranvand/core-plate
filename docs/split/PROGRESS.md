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
| P1 | plate text into the model | `p1-plate-text` | −35 | done | | +41 |
| P2 | validation stops blocking | `p2-validation-advisory` | −45 lib, −45 holder | todo | | |
| P3 | country decoupling | `p3-country-decoupling` | −35 | todo | | |
| P4 | keypad compaction | `p4-keypad-compaction` | −90 | todo | | |
| P5 | core public surface | `p5-core-surface` | ±0 | todo | | |
| P6 | dead weight | `p6-core-dead-weight` | −40, −1 dep | todo | | |
| P7 | extract `plate-keypad` | `p7-extract-keypad` | ±0 | done | | see log |
| P8 | extract `iran-plate` + `germany-plate` | `p8-extract-countries` | ±0 | todo | | |
| P9 | cutover: rename, docs, isolation proof | `p9-cutover` | ±0 | todo | | |

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
| publish to pub.dev, or path-only? | P9 | §6.6 |

Write each answer into `PLAN.md` §6 when it is given. A plan that ends with open questions is a
plan someone reopens.

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
