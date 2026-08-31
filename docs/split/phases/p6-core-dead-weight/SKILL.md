---
name: p6-core-dead-weight
description: "Phase P6 of the plate split (second edition) — remove dead code, dead dependencies and documentation that describes a package that no longer exists, so nothing worthless gets copied into four packages. Use when the user asks to run P6 or clean up the core."
---

# P6 — Dead weight

Follow `CLAUDE.md` working style. **Requires P5 committed** (P5 may make something dead that
this phase would otherwise have kept, and it establishes the `src/` layout this phase reads).
This project does not use automated tests: do not write or update anything under `test/`, and
do not run `flutter test`. Finish analyzer-clean in both repos, committed; report diffstat and
hashes only.

The last cleaning phase. After it the core is what gets split, so anything left here is
something four packages inherit and someone has to maintain.

**This phase deletes things. `claude.md` §5 (scope) is suspended for deletions specifically —
finding dead code *is* the phase — but not for rewrites.** If something looks wrong rather than
dead, report it; do not improve it.

## Do

### 1. The known dead list

These were found during the recon and are expected still to be there. Confirm each is genuinely
unreferenced (grep both repos, not just `lib/`) before removing it, and say so in the report:

| what | where | evidence |
|---|---|---|
| `PlateKeypadTheme.copyWith` | `plate_keypad.dart` | never called anywhere; ~18 lines |
| `args` dependency | `pubspec.yaml` | a CLI argument parser in a Flutter widget package — check for any import before removing |
| `bloc_test` dev dependency | `pubspec.yaml` | this project has no tests; if `test/` is gone or empty it has nothing to serve |
| `country_flags` | `pubspec.yaml` | should already be gone in P3 — if it is still there, P3 left the fallback branch in and that is a bug, not a cleanup |
| `bloc_concurrency` | `pubspec.yaml` | removed in the first edition; verify it has not come back |

Do not remove `flutter_svg` without checking: after P3 the flags are SVGs, so it is live.

### 2. Find the rest yourself

The list above is what was known months ago. Sweep for:

- **Public names nothing constructs.** P5's classification table is the map — anything it put
  in "public API" that neither `lib/` nor the holder nor a doc comment ever names is a
  candidate. Be careful: a package's public API legitimately contains things *this repo* does
  not use. `PlateText` may have no call site and still be right to keep. Judgement, and say so.
- **Unreachable branches.** P2 removed the barring path and P3 removed the `country_flags`
  fallback; check for orphaned `if`s and now-constant conditions left behind.
- **Fields written and never read**, and constructor parameters threaded through and dropped.
  The first edition found `PlateSlotItem.letterInputMode` declared, documented and never read
  in its body; that class of bug is exactly what survives a refactor.
- **`@Deprecated` shims whose release has passed.** P2's
  `typedef GermanPlateValidationResult` and any P3 `PlateSpecs` shim are one release old at
  most — those stay. Anything older goes, with a `CHANGELOG.md` line.

### 3. Documentation that lies

This is most of the value of the phase, and it is the part that is easy to skip because nothing
fails when you do.

- **`README.md`.** Check whether it still describes the current API. The first edition found it
  importing `bicycle_plate/index.dart`, constructing `PlateCardBloc(PlateType.irCar)` and
  listing features that predate `PlateSpec` — none of which compiles. P0.5 rewrote it once, and
  P1–P5 have changed the API again since. It is the first thing anyone reading this package
  sees. **Do not write the four-package README here** — that is P9's, after the packages exist.
  Write the one that is true today.
- **`CHANGELOG.md`.** Should carry the API changes P2 and P3 made (removed `barredNext*`,
  removed `unavailableKeys`, `PlateFlag`'s constructor, required keypad alphabets, moved
  country constants). If those entries are missing, add them now rather than reconstructing
  them in P9.
- **Doc comments that name a country** in files P3 did not touch. P3's grep excluded
  `lib/countries/` and the barrel; re-run it over `lib/src/` with no exclusions and read what
  comes back — a doc comment is allowed to say "for example, the Iranian car plate", but
  "the visual language of a real Iranian licence plate" on a generic theme is a claim about
  the code that is false.
- **Comments that describe removed behaviour.** Grep for `barred`, `unavailable`, `forbidden`,
  `bar` in comments across both repos. P2 was told to rewrite several; check it did.
- **`analysis_options.yaml`.** It includes stock `flutter_lints` and nothing else — which is
  how a raw, ungenericized `Emitter` in `plate_card_bloc.dart` went uncaught. Add:

  ```yaml
  analyzer:
    language:
      strict-casts: true
      strict-inference: true
      strict-raw-types: true
  ```

  Run `flutter analyze` immediately after adding it and fix what it surfaces — this is the
  right phase for that because the alternative is discovering it in P7/P8 while also moving
  files. **Do not add lint rules beyond those three.** The point is closing the specific gap
  that let a real bug through, not a lint audit the user did not ask for. This config becomes
  the one each package includes in P7/P8, so getting it settled here is worth a phase slot.

### 4. `docs/`

`docs/` currently holds the first edition's plan, an `ARCHITECTURE_BEFORE_REFACTOR.md.md`
(double extension), an `all prompts.md`, a stale lock file, a `poster_assets.zip`, a `migration/`
directory for an unrelated finished poster migration, and the superseded
`docs/split/skills/p6-…` through `p12-…`.

Delete what is superseded — the old `skills/p6` … `p12` directories are named explicitly in
`PLAN.md`'s closing section — and leave what is history. When in doubt, ask rather than
deleting: a stale document is cheap, a deleted one is gone. Do not touch `docs/split/phases/`,
`PLAN.md`, `PROGRESS.md` or `PROMPTS.md`.

## What this phase must not do

- No renames, no new packages, no moves between directories (P5 did the moves, P7/P8 do the
  packages).
- No behaviour changes. Deleting dead code changes no behaviour by definition; if a deletion
  changes behaviour, the code was not dead and you have found something more interesting than a
  cleanup. Stop and report it.
- No "while I'm here" rewrites of live code.

## Widgets, not widget functions

Per `PLAN.md` §5, in the files this phase edits. By now the library should have none left; if
one turns up, convert it under the judgement rule or report why not.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze && flutter run
```

(Do not run `flutter test`.)

Then:

```bash
cd plate-core
grep -rniE "barred|unavailableKeys" lib/         # → empty
grep -rniE "iran|german|persian" lib/src/        # → empty (comments included)
flutter pub deps --style=compact                 # read it; every direct dep should be one you can name a use for
```

Run the showcase and the flag gallery once more. A deletion phase that breaks something breaks
it silently — the analyzer will not catch a removed asset declaration or a dropped dependency
that only mattered at runtime.

Expected: ~40 lines out of `lib/`, at least one dependency gone, a `README.md` and
`CHANGELOG.md` that are true, and a stricter analyzer config that the four packages will
inherit.
