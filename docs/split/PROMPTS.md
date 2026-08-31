# Refactor prompts — P1 through P9 (second edition)

Paste-ready wrappers for the phases in `docs/split/phases/`. Plan and rationale: `PLAN.md`.
Status: `PROGRESS.md`. All three live beside this file.

Open Claude Code in the `plate-core` repo (`~/StudioProjects/plate/plate-core`; the holder is
its sibling at `../plate_number_holder`). Run them **in order** — each names its own
prerequisite, and the dependency notes in `PLAN.md` §3 explain which ones are genuinely
sequential rather than conventionally so.

> **This is a renumbering.** The old series (P0.5 → P12, in `docs/split/skills/`) ran through
> its P5; everything after that described a target that no longer exists. The remaining work is
> renumbered P1 … P9 here. `PLAN.md`'s closing section has the old→new mapping if you hit an
> old number in a commit message. **Do not run anything from `docs/split/skills/p6-…` through
> `p12-…`.**

## Two changes this edition is built around

1. **Validation never blocks input.** The barred-key path is deleted, not refactored. What
   survives is a verdict the developer opts into, painted red. P2.
2. **The packages are siblings of `core-plate`, not children.** No `packages/` directory, no
   pub workspace, no `plate_number` facade. P7–P9.

## Testing policy

This project does not use automated tests. Ignore any instruction — here or in a linked
`SKILL.md` — to write, add, or update files under `test/`, or to run `flutter test`. Every
"finish analyzer-clean" line means `flutter analyze` only.

## Model and thinking level per phase

**Quality** is what to use if you want the phase done right the first time. **Budget** is the
cheapest setting with a fair chance, and is a false economy on any row marked ⚠.

| | phase | Quality | Budget | why this level |
|---|---|---|---|---|
| P1 | plate text | Sonnet · `think` | Sonnet · — | self-contained move of logic into the model; the only judgement call is the `effectiveTextGroups` cache |
| P2 ⚠ | validation advisory | Opus · `think hard` | Opus · `think` | inverts a design across three files in two repos, and the failure mode is "preserved the thing it was told to delete." Do not run on Sonnet |
| P3 | country decoupling | Opus · `think` | Sonnet · `think hard` | five leaks, several call sites in two repos, and a grep that has to come back empty |
| P4 | keypad compaction | Sonnet · `think hard` | Sonnet · `think` | one file, but two highlight paths to carry through and tuned behaviour not to "improve" |
| P5 ⚠ | core surface | Opus · `think hard` | Opus · `think` | it is a design decision wearing a file-move costume; get it wrong and every later phase inherits it |
| P6 | dead weight | Sonnet · `think hard` | Sonnet · `think` | mostly mechanical, but "is this dead or just unused here?" needs care on a package's public API |
| P7 | extract keypad | Opus · `think` | Sonnet · `think hard` | first package; whatever pattern it sets, P8 copies |
| P8 ⚠ | extract countries | Opus · `think hard` | Sonnet · `think hard` | four repos in one commit, an asset trap that passes locally and fails for everyone else, and a product decision to ask |
| P9 ⚠ | cutover | Opus · `think hard` | Opus · `think` | a rename touching five repos, a decision to put to the user, and the isolation proof the whole refactor was for |

Two rules that matter more than the table:

- **A phase that asks a question (P7, P8, P9) must ask it before writing code.** No model
  setting fixes a decision made by default.
- If a phase reports that something in its `SKILL.md` was already true, already done, or no
  longer in the tree — **believe it and correct the file** before the next phase inherits the
  same mistake. In the first edition, P1 sat marked "todo" for a month after it landed because
  nobody did this.

---

## P1 — Plate text into the model

```
Read docs/split/phases/p1-plate-text/SKILL.md in full and carry out exactly what it says.
This is the first phase of the second edition — read docs/split/PLAN.md §2 first for what
changed and why. Nothing is required before it. Record lib/'s current line count in
docs/split/PROGRESS.md as the second edition's baseline, per the skill's verify section.
Finish with flutter analyze clean (do not run flutter test) in both repos (plate-core and
../plate_number_holder), and a git commit in each repo you touched. Report diffstat and commit
hashes only.
```

## P2 — Validation stops blocking input ⚠

```
Read docs/split/phases/p2-validation-advisory/SKILL.md in full, and docs/split/PLAN.md §1
before it. Requires P1 committed. This phase INVERTS the current design: validation must never
prevent a keystroke again. Delete the barred-key path first and let the analyzer lead you to
the call sites — barredNextDigits, barredNextLetters, PlateKeypad.unavailableKeys and the
holder's _unavailableKeysFor all go. Do not port them under a new name and do not keep an
"advisory" version. Keep _keyEnabled's alphabet check, which is not a validation rule. It also
resolves the docs/forbidden.json duplication — follow that part exactly. Finish with flutter
analyze clean (do not run flutter test) in both repos, and a git commit in each repo you
touched. Report diffstat and commit hashes only.
```

## P3 — Country decoupling

```
Read docs/split/phases/p3-country-decoupling/SKILL.md in full and carry out exactly what it
says. Requires P2 committed. Its acceptance grep must return nothing before you consider the
phase done — paste the command and its actual output into your report, not a claim that it
passed. It also touches a standalone dev-gallery entrypoint in ../plate_number_holder
(lib/dev/flag_panel_gallery.dart) that nothing else exercises and flutter analyze will not run
for you — actually launch it as the verify section describes. Finish with flutter analyze clean
(do not run flutter test) in both repos, and a git commit in each repo you touched. Report
diffstat and commit hashes only.
```

## P4 — Keypad compaction

```
Read docs/split/phases/p4-keypad-compaction/SKILL.md in full and carry out exactly what it
says. Requires P2 and P3 committed. One file: lib/widgets/plate_keypad.dart. The trap is
collapsing the two highlight paths into one for tidiness — the ValueListenable path exists so a
press-flash rebuilds one key instead of the grid, and it must survive into _KeyGrid unchanged.
Finish with flutter analyze clean (do not run flutter test) in both repos, and a git commit in
each repo you touched. Report diffstat and commit hashes only.
```

## P5 — The core's public surface ⚠

```
Read docs/split/phases/p5-core-surface/SKILL.md in full. Requires P1-P4 committed. Do step 1
(classifying every top-level name as public / internal / undecided) BEFORE moving any file, and
put the classification table in your report — it is the deliverable, the file moves are just
what follows from it. Use AskUserQuestion for anything you land in the "undecided" bucket
rather than picking for me. Use git mv so history follows the files. No renames, no deletions,
no behaviour changes. Finish with flutter analyze clean (do not run flutter test) in both
repos, and a git commit in each repo you touched. Report diffstat and commit hashes only.
```

## P6 — Dead weight

```
Read docs/split/phases/p6-core-dead-weight/SKILL.md in full and carry out exactly what it says.
Requires P5 committed. Confirm each item on its known-dead list is genuinely unreferenced
across BOTH repos before removing it, and say so. Be careful with the public API: a name this
repo does not use may still be right for a package to export — use judgement and report the
calls you made. Where you are unsure whether something in docs/ is superseded or history, ask
rather than deleting. Finish with flutter analyze clean (do not run flutter test) in both
repos, and a git commit in each repo you touched. Report diffstat and commit hashes only.
```

## P7 — Extract plate-keypad

```
Read docs/split/phases/p7-extract-keypad/SKILL.md in full. Requires P5 (and P4) committed.
Before moving any code, use AskUserQuestion to put the PlateCharacterPicker question in the
skill file to me — do not decide it yourself. This is the first package the split creates and
P8 copies whatever pattern you establish, so get the pubspec, barrel, src/ layout, LICENSE,
CHANGELOG and README right once. Finish with flutter pub get and flutter analyze clean (do not
run flutter test) in ../plate-keypad, plate-core and ../plate_number_holder, plus a git commit
in each repo you touched. Report diffstat and commit hashes only.
```

## P8 — Extract iran-plate and germany-plate ⚠

```
Read docs/split/phases/p8-extract-countries/SKILL.md in full. Requires P7 committed and P3's
acceptance grep still returning nothing — re-run it and paste the output before you start.
Before writing code, use AskUserQuestion to put the three docs/districts.json options to me;
do not default to "wire it in." Pay close attention to "the asset trap" — it describes a
failure that looks fine in a warm debug build and breaks for a fresh consumer, so the
flutter clean && flutter pub get && flutter run --release verification is not optional. Finish
with flutter analyze clean (do not run flutter test) in every repo the skill lists, and a git
commit in each repo you touched. Report diffstat and commit hashes only.
```

## P9 — Cutover ⚠

```
Read docs/split/phases/p9-cutover/SKILL.md in full. Requires P8 committed. Before touching any
pubspec, use AskUserQuestion to settle whether these packages get published to pub.dev or stay
path-only, per docs/split/PLAN.md §6.6 — it changes how the four packages depend on each other.
Then do the rename, the documentation, and the throwaway-app isolation check exactly as the
skill describes; that check is the proof the whole refactor was for, so do not substitute a
reasoned argument for actually building it. Record the real per-package line counts against the
estimates in PLAN.md §4, including where the estimates were wrong. Finish with flutter analyze
clean (do not run flutter test) everywhere, and a git commit in each repo you touched. Report
diffstat and commit hashes only.
```
