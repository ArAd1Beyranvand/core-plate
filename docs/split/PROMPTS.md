# Refactor prompts — P0.5 through P12

Not the `/task` system (that's the old, already-finished poster migration in
`docs/migration/` — unrelated, ignore it). These are plain prompts for the plate_number
split/refactor plan in `docs/split/`. Paste one at a time into Claude Code, opened in the
`plate-core` repo (renamed from `plate-number-upgrade`; the holder is its sibling at
`../plate_number_holder`). Run them in order — each names its own prerequisite.

## Testing policy

This project does not use automated tests. Ignore any instruction below (or in a
linked `SKILL.md`) to write, add, or update files under `test/`, or to run `flutter test`.
Every "Finish with flutter analyze clean (do not run flutter test)" line means: run `flutter
analyze` clean only. Do not create test files as part of any phase.

## Model and thinking level per phase

This used to say "see the table from the previous message," which is no use to a cold session —
so the table lives here now. **Quality** is what to use if you want the phase done right the
first time; **Budget** is the cheapest setting that still has a fair chance, and is a false
economy on any row marked ⚠.

| | phase | Quality | Budget | why this level |
|---|---|---|---|---|
| P0.5 | repo hygiene | — | — | **done** (`385c34a`) |
| P0.75 | package template | — | — | **done** (`803c795`) |
| P1 | slot identity | — | — | **done** in the perf pass; the leftover test check is Sonnet · — |
| P2 | plate geometry | Sonnet · `think hard` | Sonnet · `think` | mechanical, but must be pixel-identical and the panel-overlap comments are easy to drop |
| P3 | input model | Opus · `think` | Sonnet · `think hard` | a seven-row behaviour table ported across two repos, plus a design call on the theme global |
| P4 ⚠ | input machine | Opus · `think hard` | Opus · `think` | highest-risk phase in the plan: a live bug, a lifecycle rewrite, and a rebuild isolation it must not undo. Do not run this on Sonnet |
| P5 | value semantics | Sonnet · `think` | Sonnet · — | now mostly mechanical; the only trap is re-adding what already exists, and the skill says so |
| P6 | plate text | Sonnet · `think` | Sonnet · — | self-contained move of logic into the model, with tests |
| P7 ⚠ | validation as data | Opus · `think hard` | Sonnet · `think hard` | designs a new core abstraction *and* does holder surgery without hoisting the scoped rebuilds |
| P7.5 | district data | Sonnet · `think` | Sonnet · — | small edit; the hard part is asking rather than defaulting |
| P8 | country decoupling | Opus · `think` | Sonnet · `think hard` | four leaks, several call sites in two repos, and a grep that has to come back empty |
| P9 | keypad compaction | Sonnet · `think hard` | Sonnet · `think` | one file, but two highlight paths to carry through and tuned behaviour not to "improve" |
| P10 | core package | Opus · `think` | Sonnet · `think hard` | mechanical per file, but every import in the repo moves at once |
| P11 | country packages | Sonnet · `think hard` | Sonnet · `think` | mechanical; the asset trap is caught by the release-run step, not by reasoning |
| P12 ⚠ | keypad + cutover | Opus · `think hard` | Sonnet · `think hard` | two decisions to put to the user, the cutover itself, and the isolation proof the whole refactor was for |

Two rules that matter more than the table:

- **A phase that asks a question (P7.5, P10, P12) must ask it before writing code.** No model
  setting fixes a decision made by default.
- If a phase reports that something in its `SKILL.md` was already true, already done, or no
  longer in the tree — believe it and correct the file before the next phase inherits the same
  mistake. That is how P1 came to be listed as todo for a month after it landed.

**Already done: P0.5, P0.75 and P1.** Their `SKILL.md` files are kept as the record of what
changed; each opens with a status banner. Start at P2. The one loose end is in P1's banner —
two `PlateSpec` test cases that may never have been written.

**Every phase from P1 on also converts widget functions to widget classes** in the files it
already touches, under the judgement rule in `PLAN.md` §4b: convert only where the class is not
materially longer than the function, inline the rest, and report what was deliberately left
alone. It is written into each `SKILL.md`; the wrappers below do not repeat it.

---

## P0.5 — Repo hygiene — done (`385c34a`)
## P0.75 — Package template correction — done (`803c795`)
## P1 — Slot identity — done (inside the animation performance pass, no phase commit)

No prompt needed for these three. P1 has one possible loose end: the two `PlateSpec` test cases
(`nextIndex` at the last slot, `previousIndex` at slot 0) from its step 17. If you want them
checked:

```
Read docs/split/skills/p1-slot-identity/SKILL.md's status banner and step 17. The phase is
already landed; this project does not use automated tests, so there is nothing left to check
in test/spec_test.dart — treat this loose end as closed and do not add test cases for it.
Report that only.
```

## P2 — Plate geometry

```
Read docs/split/skills/p2-plate-geometry/SKILL.md in full and carry out exactly what it says.
P1 is already landed (verify with a quick look at plate_spec.dart: PlateSlot must have no index
or next field) — this is the first phase actually to run. This phase must be pixel-identical to before — read the verification
section carefully before starting, it explains what "identical" means here and why the panel
overlap comments matter. Finish with flutter analyze clean (do not run flutter test) in both repos
(plate-core and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P3 — Input model

```
Read docs/split/skills/p3-input-model/SKILL.md in full and carry out exactly what it says.
Requires P2 committed. Finish with flutter analyze clean (do not run flutter test) in both repos
(plate-core and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P4 — Input machine (fixes a confirmed live bug)

```
Read docs/split/skills/p4-input-machine/SKILL.md in full and carry out exactly what it says.
Requires P3 committed. This phase fixes a real, confirmed bug in ../plate_number_holder, not
just a refactor — follow its reproduce-before-you-fix steps exactly before writing any code,
and its confirm-after-the-fact steps before considering it done. Finish with flutter analyze
clean (do not run flutter test) in both repos, and a git commit in each repo you touched. Report
diffstat and commit hashes only.
```

## P5 — Value semantics

```
Read docs/split/skills/p5-value-semantics/SKILL.md in full and carry out exactly what it says.
Requires P4 committed. Pay attention to the two separate copyWith call sites it names. Finish
with flutter analyze clean (do not run flutter test) in both repos (plate-core and
../plate_number_holder), and a git commit in each repo you touched. Report diffstat and commit
hashes only.
```

## P6 — Plate text

```
Read docs/split/skills/p6-plate-text/SKILL.md in full and carry out exactly what it says.
Requires P2 committed (it does not need P3/P4/P5). Finish with flutter analyze clean (do not run
flutter test) in both repos, and a git commit in each repo you touched. Report diffstat
and commit hashes only.
```

## P7 — Validation as data

```
Read docs/split/skills/p7-validation-as-data/SKILL.md in full and carry out exactly what it
says. Requires P6 committed. It also resolves a data duplication with docs/forbidden.json —
follow that part exactly, it's a small decision embedded in an otherwise mechanical phase.
Finish with flutter analyze clean (do not run flutter test) in both repos (plate-core and
../plate_number_holder), and a git commit in each repo you touched. Report diffstat and commit
hashes only.
```

## P7.5 — District data (a decision, not just an edit)

```
Read docs/split/skills/p7.5-district-data/SKILL.md in full. Requires P7 committed. Before
writing any code, use AskUserQuestion to put the three options in the skill file to me and get
my answer — do not default to "wire it in." Once I've answered, carry out exactly what the
skill says for that option. Finish with flutter analyze clean (do not run flutter test) in both repos,
and a git commit in each repo you touched. Report diffstat and commit hashes only.
```

## P8 — Country decoupling

```
Read docs/split/skills/p8-country-decoupling/SKILL.md in full and carry out exactly what it
says. Requires P7 committed. This is the last phase before the package split — its acceptance
grep must return nothing before you consider it done. It also touches a standalone dev-gallery
entrypoint in ../plate_number_holder (lib/dev/flag_panel_gallery.dart) that nothing else
exercises automatically — actually run it as the skill's verification section describes, don't
skip that step. Finish with flutter analyze clean (do not run flutter test) in both repos, and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```

## P9 — Keypad compaction

```
Read docs/split/skills/p9-keypad-compaction/SKILL.md in full and carry out exactly what it
says. Requires P8 committed. Finish with flutter analyze clean (do not run flutter test) in both repos
(plate-core and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P10 — Core package

```
Read docs/split/skills/p10-core-package/SKILL.md in full. Requires P9 committed, and the P8
acceptance grep still returning nothing — recheck it before starting. Before creating any
package directories, ask me (via AskUserQuestion) to confirm the package-naming decision the
skill references in docs/split/PLAN.md §5.1. Then carry out exactly what the skill says,
including the shared workspace-level analysis_options.yaml it adds. Finish with flutter pub
get / flutter analyze clean (do not run flutter test) at the workspace root and inside packages/core_plate,
plus flutter analyze clean (do not run flutter test) in ../plate_number_holder, and a git commit in each
repo you touched. Report diffstat and commit hashes only.
```

## P11 — Country packages

```
Read docs/split/skills/p11-country-packages/SKILL.md in full and carry out exactly what it
says. Requires P10 committed. Pay close attention to "the asset trap" section — it describes a
failure mode that looks fine in a warm debug build and breaks for a fresh consumer, so its
flutter clean && flutter pub get && flutter run --release verification step is not optional.
Finish with flutter analyze clean (do not run flutter test) everywhere the skill lists, and a git commit
in each repo you touched. Report diffstat and commit hashes only.
```

## P12 — Keypad package and cutover

```
Read docs/split/skills/p12-keypad-package-and-cutover/SKILL.md in full. Requires P11 committed.
Before touching the plate_number facade, ask me (via AskUserQuestion) to settle whether it's
retired or kept as a published meta-package, per docs/split/PLAN.md §5.2 — do not decide this
yourself. Also confirm with me before moving PlateCharacterPicker into plate_keypad, per the
skill's note on that being an API break. Then carry out the rest of what the skill says,
finishing with the full verification section it describes, including the throwaway-app
isolation check. Finish with flutter analyze clean (do not run flutter test) everywhere, and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```
