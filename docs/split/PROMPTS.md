# Refactor prompts — P0.5 through P12

Not the `/task` system (that's the old, already-finished poster migration in
`docs/migration/` — unrelated, ignore it). These are plain prompts for the plate_number
split/refactor plan in `docs/split/`. Paste one at a time into Claude Code, opened in the
`plate-number-upgrade` repo. Run them in order — each names its own prerequisite.

Model guidance for each is in the table from the previous message; nothing below repeats it.

---

## P0.5 — Repo hygiene

```
Read docs/split/skills/p0.5-repo-hygiene/SKILL.md in full and carry out exactly what it says.
It has no prerequisite phase. Finish with flutter analyze clean and a git commit; report the
diffstat and commit hash only.
```

## P0.75 — Package template correction

```
Read docs/split/skills/p0.75-package-template/SKILL.md in full and carry out exactly what it
says. It has no prerequisite phase and can run independently of P0.5. Finish with
flutter pub get / flutter analyze / flutter test all clean and a git commit; report the
diffstat and commit hash only.
```

## P1 — Slot identity

```
Read docs/split/skills/p1-slot-identity/SKILL.md in full and carry out exactly what it says.
Requires P0.5 and P0.75 to not be blockers (they aren't — just confirm they're either done or
skipped). This phase also touches plate_number_holder, a sibling repo at
../plate_number_holder — read its device_stage.dart in full before editing, the skill explains
why. Finish with flutter analyze and flutter test clean in both repos, and a git commit in
each repo you touched. Report diffstat and commit hashes only.
```

## P2 — Plate geometry

```
Read docs/split/skills/p2-plate-geometry/SKILL.md in full and carry out exactly what it says.
Requires P1 committed. This phase must be pixel-identical to before — read the verification
section carefully before starting, it explains what "identical" means here and why the panel
overlap comments matter. Finish with flutter analyze and flutter test clean in both repos
(plate-number-upgrade and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P3 — Input model

```
Read docs/split/skills/p3-input-model/SKILL.md in full and carry out exactly what it says.
Requires P2 committed. Finish with flutter analyze and flutter test clean in both repos
(plate-number-upgrade and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P4 — Input machine (fixes a confirmed live bug)

```
Read docs/split/skills/p4-input-machine/SKILL.md in full and carry out exactly what it says.
Requires P3 committed. This phase fixes a real, confirmed bug in ../plate_number_holder, not
just a refactor — follow its reproduce-before-you-fix steps exactly before writing any code,
and its confirm-after-the-fact steps before considering it done. Finish with flutter analyze
and flutter test clean in both repos, and a git commit in each repo you touched. Report
diffstat and commit hashes only.
```

## P5 — Value semantics

```
Read docs/split/skills/p5-value-semantics/SKILL.md in full and carry out exactly what it says.
Requires P4 committed. Pay attention to the two separate copyWith call sites it names — missing
either one leaves the test suite failing to compile. Finish with flutter analyze and
flutter test clean in both repos (plate-number-upgrade and ../plate_number_holder), and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```

## P6 — Plate text

```
Read docs/split/skills/p6-plate-text/SKILL.md in full and carry out exactly what it says.
Requires P2 committed (it does not need P3/P4/P5). Finish with flutter analyze and
flutter test clean in both repos, and a git commit in each repo you touched. Report diffstat
and commit hashes only.
```

## P7 — Validation as data

```
Read docs/split/skills/p7-validation-as-data/SKILL.md in full and carry out exactly what it
says. Requires P6 committed. It also resolves a data duplication with docs/forbidden.json —
follow that part exactly, it's a small decision embedded in an otherwise mechanical phase.
Finish with flutter analyze and flutter test clean in both repos (plate-number-upgrade and
../plate_number_holder), and a git commit in each repo you touched. Report diffstat and commit
hashes only.
```

## P7.5 — District data (a decision, not just an edit)

```
Read docs/split/skills/p7.5-district-data/SKILL.md in full. Requires P7 committed. Before
writing any code, use AskUserQuestion to put the three options in the skill file to me and get
my answer — do not default to "wire it in." Once I've answered, carry out exactly what the
skill says for that option. Finish with flutter analyze and flutter test clean in both repos,
and a git commit in each repo you touched. Report diffstat and commit hashes only.
```

## P8 — Country decoupling

```
Read docs/split/skills/p8-country-decoupling/SKILL.md in full and carry out exactly what it
says. Requires P7 committed. This is the last phase before the package split — its acceptance
grep must return nothing before you consider it done. It also touches a standalone dev-gallery
entrypoint in ../plate_number_holder (lib/dev/flag_panel_gallery.dart) that nothing else
exercises automatically — actually run it as the skill's verification section describes, don't
skip that step. Finish with flutter analyze and flutter test clean in both repos, and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```

## P9 — Keypad compaction

```
Read docs/split/skills/p9-keypad-compaction/SKILL.md in full and carry out exactly what it
says. Requires P8 committed. Finish with flutter analyze and flutter test clean in both repos
(plate-number-upgrade and ../plate_number_holder), and a git commit in each repo you touched.
Report diffstat and commit hashes only.
```

## P10 — Core package

```
Read docs/split/skills/p10-core-package/SKILL.md in full. Requires P9 committed, and the P8
acceptance grep still returning nothing — recheck it before starting. Before creating any
package directories, ask me (via AskUserQuestion) to confirm the package-naming decision the
skill references in docs/split/PLAN.md §5.1. Then carry out exactly what the skill says,
including the shared workspace-level analysis_options.yaml it adds. Finish with flutter pub
get / flutter analyze / flutter test clean at the workspace root and inside packages/core_plate,
plus flutter analyze / flutter test clean in ../plate_number_holder, and a git commit in each
repo you touched. Report diffstat and commit hashes only.
```

## P11 — Country packages

```
Read docs/split/skills/p11-country-packages/SKILL.md in full and carry out exactly what it
says. Requires P10 committed. Pay close attention to "the asset trap" section — it describes a
failure mode that looks fine in a warm debug build and breaks for a fresh consumer, so its
flutter clean && flutter pub get && flutter run --release verification step is not optional.
Finish with flutter analyze and flutter test clean everywhere the skill lists, and a git commit
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
isolation check. Finish with flutter analyze and flutter test clean everywhere, and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```
