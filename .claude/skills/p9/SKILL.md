---
name: p9
description: "P9 — remove the three deprecated symbols nothing calls, delete ~2.8 MB of stale planning documents and artefacts from inside publishable packages, and fix every dangling doc reference. Invoke with /p9 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** low · **extended thinking:** off
> **Requires:** /p2 /p4 /p5 /p6 /p7 /p8
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P9 — Dead weight removal

## Context (assume nothing else)

By this point the structural work is done and the workspace is green. What remains is accumulated
residue: API kept alive for a migration that finished, documents describing plans that may or may not
have been executed, and comments pointing at files and line numbers that have moved.

Everything below was verified by grep across all seven packages.

### Deprecated API with zero call sites

| Symbol | Declared | Deprecation says | Real call sites |
|---|---|---|---|
| `PlateInputController` (typedef for `PlateController`) | `core_plate/lib/src/input/plate_input_controller.dart:22` | "will be removed in 0.6.0" | **0** |
| `PlateController.activeSlotIn(PlateSpec)` | `core_plate/lib/src/input/plate_controller.dart:264-268` | "will be removed in 0.6.0" | **0** |
| `RemovePlateCard` (bloc event) | `core_plate_bloc/lib/src/plate_card_event.dart:22` | "will be removed in 1.0.0" | **0 dispatchers**; one handler at `plate_card_bloc.dart:20` |

The only textual hits for `PlateInputController` outside its own declaration are a doc-comment mention in
`core_plate.dart:99-102` and one in `yemen_serial_generator.dart:13`. `core_plate` is at 0.5.0; the next
release is the one those deprecations named.

### Documents and artefacts inside publishable package directories

| Path | Size | What it is |
|---|---:|---|
| `core_plate/docs/poster_assets.zip` | 2.6 MB | binary blob |
| `core_plate/docs/split/` (PLAN, PROGRESS, PROMPTS + 9 `phases/*/SKILL.md`) | ~110 KB | a prior refactor plan |
| `core_plate/docs/migration/` (P1–P9, PROGRESS, README, logs) | ~47 KB | an earlier prior refactor plan |
| `core_plate/docs/all prompts.md`, `docs/PROMPTS.md` | ~83 KB | prompt transcripts |
| `core_plate/docs/.~lock.all prompts.md#` | 85 B | a LibreOffice lock file |
| `core_plate/docs/ARCHITECTURE_BEFORE_REFACTOR.md.md` | 13 KB | note the doubled extension |
| `core_plate/docs/references/*.jpg` | ~307 KB | reference photographs |
| `core_plate/DESIGN_SPEC.md` and `core_plate/docs/DESIGN_SPEC.md` | 24,674 B each | **byte-identical duplicates** |
| `core_plate/REFACTOR_MANIFEST.md` | 11 KB | a third prior plan |
| `core_plate/claude.md` **and** `core_plate/CLAUDE.md` | 1,739 B / 513 B | two files differing only in case |
| `core_plate/plate_number.iml` | 842 B | IDE module named after a package that does not exist |
| `palestine_plate/images.jpeg` | 34 KB | stray file at package root |
| `palestine_plate/test/failures/*.png` | 17 KB | golden-diff artefacts |
| repo root: `debug.log`, `omniroute.log`, `omniroute-debug.log` | 5.5 KB | runtime logs |
| repo root: `PLATE_CONTROLLER_PLAN.md`, `PROMPT_palestine_plate.md`, `PROMPT_yemen_plate.md` | 118 KB | three more prior plans |

### Dangling references in live API documentation

| File:line | Says | Reality |
|---|---|---|
| `core_plate/lib/src/validators/plate_validator.dart:58` | "see `docs/split/PLAN.md` §1" | a prior plan, deleted by this phase |
| `germany_plate/lib/src/german_plate_validator.dart:50` | "see `docs/split/PLAN.md` §1" | that path does not exist in `germany_plate` at all |
| `germany_plate/lib/src/german_plate_validator.dart:16` | "`docs/districts.json` … deleted in P8 of the split" | narrates a prior phase to a consumer |
| `core_plate/lib/src/model/plate_spec.dart:68` | `AssetImage(..., package: 'plate_number')` | no such package |
| `core_plate/lib/src/model/plate_country.dart:11` | constants "live in their own files (`countries/…`)" | no such directory (P3 may have fixed this) |
| `yemen_plate/example/pubspec.yaml:23` | "core_plate plate_canvas.dart:227 and :355" | the lines are **279** and **429** |
| `core_plate/lib/core_plate.dart:83-86, 110-113, 121-126` | "moved … in P7", "left … in P8", "in 0.4.0" | changelog prose in a barrel file |
| `plate_keypad/lib/src/plate_keypad.dart:98` | `/// gimme cloc command to would reject them anyway —` | **a corrupted doc comment**: an editing artefact committed into public API documentation |

### Empty directories

`palestine_plate/lib/src/generator/`, `models/`, `render/`, `validation/` — all four contain nothing.

## Scope

**In:** deletion and doc correction only, across all seven packages and the repo root.

**Out — frozen:**
- **All live code.** This phase deletes only symbols proven to have zero call sites and text that
  describes nothing. If a deletion requires editing a call site, it is not this phase's deletion — stop
  and report it.
- `SpecIsChanged` (`plate_card_event.dart:24`). It has no dispatcher in the workspace either, but it is
  **not deprecated** and it is coherent public API for an external bloc host. Leave it; add a test for it
  in P11 instead.
- `YemenCountry.unified` and `YemenCountry.northernMilitaryModern`. Both are unreferenced and both are
  self-documented as deliberately so: *"it exists because 'the panel, without a usage' is a meaningful
  value"*. That is a data decision. Leave both.
- `YemenColors.unifiedFrame` if P2 orphaned it — same reasoning, it is a named calibration target.
- `PSSerialGenerator.toFilename` — used by its own test, which is a legitimate user.
- **`claude/` and `.claude/`.** `claude/AUDIT_DIAGNOSIS.md`, `claude/REFACTOR_ROADMAP.md` and the
  `.claude/skills/p*/` phase skills are this roadmap's own working documents. They are current, not
  stale, and they are not in the deletion list above. Leave them.
- **`.gitignore` files.** P0 owns those.
- **Git history.** Deleting a file from the working tree is in scope; rewriting history is not.
  If `palestine_plate/example/.dart_tool/chrome-device/` (a full Chrome profile with `Cookies` and
  `Login Data`) turns out to be *tracked*, **stop and report it** — purging credentials from history is
  the repo owner's decision, not a refactor step.

## Steps

### 1. Remove the three deprecated symbols

Confirm zero call sites first, then delete:

```bash
cd ~/StudioProjects/plate
grep -rn "PlateInputController\|activeSlotIn\|RemovePlateCard" --include=*.dart . \
  | grep -v plate_number_holder
```

Expect only: the three declarations, the `on<RemovePlateCard>` handler, the `core_plate.dart:99-102`
export doc, and the `yemen_serial_generator.dart:13` doc mention. If anything else appears, stop.

- Delete the `PlateInputController` typedef; `plate_input_controller.dart` keeps `PlateInputTarget`.
  Rewrite the `core_plate.dart:99-102` export doc to describe `PlateInputTarget` only.
- Delete `activeSlotIn`. `activeSlot` replaces it.
- Delete `RemovePlateCard`, its `on<>` handler, and the two `// ignore: deprecated_member_use_from_same_package`
  comments it forced.
- Fix `yemen_serial_generator.dart:13`, which says the output "drops straight into a
  `PlateInputController` or `ShowPlate`" — say `PlateController`.

`CHANGELOG.md` in both packages: a breaking entry naming each removed symbol and its replacement.

### 2. Delete the documents and artefacts

```bash
cd ~/StudioProjects/plate
git rm -r core_plate/docs/
git rm core_plate/REFACTOR_MANIFEST.md core_plate/plate_number.iml
git rm palestine_plate/images.jpeg
git rm -r palestine_plate/test/failures/
git rm debug.log omniroute.log omniroute-debug.log
git rm PLATE_CONTROLLER_PLAN.md PROMPT_palestine_plate.md PROMPT_yemen_plate.md
rmdir palestine_plate/lib/src/{generator,models,render,validation}
```

On `core_plate/DESIGN_SPEC.md`: the root copy and `docs/DESIGN_SPEC.md` are byte-identical
(`cmp` them to confirm). Deleting `docs/` removes one; **keep the root copy** — it is the only
architectural document in the repo that describes the design rather than a plan to change it. Skim it
first: if it describes an architecture this roadmap has since superseded, prepend a dated note saying so
rather than deleting it.

On `claude.md` vs `CLAUDE.md`: on a case-insensitive filesystem one shadows the other. Read both, merge
into a single `CLAUDE.md` and `git rm claude.md`. Verify with `git ls-files | grep -i '^core_plate/claude'`
that exactly one path remains.

### 3. Fix every dangling reference

Work the table above top to bottom. The principle: **an API doc comment is written for a consumer who has
only the published package.** It may not reference a plan file, a phase number, or a line number in
another package.

- `plate_validator.dart:58`: replace "see `docs/split/PLAN.md` §1" with the rule itself — one sentence:
  *"A validator reports; it has no method for barring keys, and adding one would make input policy the
  validator's business rather than the host's."*
- `german_plate_validator.dart:16,50`: same treatment. The district-list paragraph should say what the
  package does and does not promise, with no phase numbers.
- `plate_spec.dart:68`: change the example package name to `'germany_plate'`, which is a real package
  that really ships decals.
- `core_plate.dart:83-86, 110-113, 121-126`: replace the three narrating blocks with present-tense
  statements of what the surface *is*. "The keypad lives in `plate_keypad`" beats "the keypad moved to
  `plate_keypad` in P7". Move any genuine migration guidance to `CHANGELOG.md`, which is where a consumer
  looks for it.
- `yemen_plate/example/pubspec.yaml:23`: the observation about fonts being unreachable is **true and
  useful** — keep the paragraph, drop the two line numbers, and refer to `PlateCanvas`'s `Theme` wrapper
  by name instead. Line numbers in comments rot; this one already has.
- `plate_keypad/lib/src/plate_keypad.dart:98`: repair the corrupted sentence. It should read:
  ```dart
  /// The focused slot's alphabet. Keys outside it render disabled — `submit()`
  /// would reject them anyway — since it may be a subset of [digitAlphabet] or
  /// [letterAlphabet]. Null disables no keys (e.g. no slot is focused).
  ```

Then sweep for any survivor:

```bash
grep -rn "docs/split\|docs/migration\|REFACTOR_MANIFEST\|plate_number\b\|in P[0-9]\b\|districts.json" \
  --include=*.dart --include=*.yaml --include=*.md . | grep -v plate_number_holder | grep -v CHANGELOG
```

`CHANGELOG.md` is exempt — a changelog is allowed to reference the past.

### 4. Confirm nothing was published that should not have been

```bash
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  echo "== $p"; (cd "$p" && flutter pub publish --dry-run 2>&1 | tail -20)
done
```

Look for: files over 1 MB, `.log`, `.iml`, `build/`, `.dart_tool/`, anything under `docs/`. If a package
still ships something it should not, add a `.pubignore` entry — **not** a `.gitignore` entry; the two
have different jobs and P0 owns `.gitignore`.

## Verification

```bash
cd ~/StudioProjects/plate

for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos) || echo "FAIL $p"
done
(cd core_plate && flutter test)
(cd core_plate_bloc && flutter test)
(cd palestine_plate && flutter test)
(cd yemen_plate && flutter test)

# Nothing deprecated left in core.
grep -rn "@Deprecated" core_plate/lib/ core_plate_bloc/lib/
#   -> nothing, or only symbols this phase's Scope froze (with a reason)

du -sh core_plate/                       # was ~3.1 MB of docs; now small
find . -name '*.log' -o -name '*.iml' | grep -v plate_number_holder   # nothing
git ls-files | grep -i chrome-device     # nothing — if it prints, STOP and report

for p in core_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter pub publish --dry-run 2>&1 | grep -i "warning\|error")
done
```

**Success:** three deprecated symbols gone with no call site touched; `core_plate/docs/` and every
root-level plan document deleted; the four empty Palestine directories gone; no doc comment references a
plan file, a phase number or another package's line numbers; every package analyzes clean and every test
suite passes; `pub publish --dry-run` is clean for all seven.

## Dependencies

P2, P4, P5, P6, P7, P8 — run it after the code changes so a deletion cannot mask a regression, and so
the comments this phase rewrites describe the final shape rather than an intermediate one.

## Line estimate

−140 Dart lines (deprecated symbols, handlers, ignore comments, corrected docs).
−2.8 MB of files, −~30 files. No behaviour change of any kind.
