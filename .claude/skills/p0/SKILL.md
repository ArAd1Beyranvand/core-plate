---
name: p0
description: "P0 — capture the build baseline, introduce a pub workspace, and fix the core_plate version constraints that would break every published consumer. Invoke with /p0 — it must run before any other phase."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** low · **extended thinking:** off
> **Requires:** none — this is the first phase
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P0 — Workspace & constraint baseline

## Context (assume nothing else)

`~/StudioProjects/plate/` holds seven Flutter packages that publish independently:
`core_plate` (0.5.0, the engine), `core_plate_bloc` (0.1.0), `plate_keypad` (0.1.0),
`iran_plate` (0.1.0), `germany_plate` (0.1.0), `palestine_plate` (0.1.0), `yemen_plate` (0.2.0).
Each has an `example/` sub-package. There is no root `pubspec.yaml` and no melos.

Two facts make this phase first:

1. **Four packages declare a `core_plate` constraint that excludes the `core_plate` they are built against.**
   `iran_plate`, `germany_plate`, `palestine_plate` and `plate_keypad` all say `core_plate: ^0.1.0`,
   which means `>=0.1.0 <0.2.0`. `yemen_plate` says `^0.2.0`. The engine is at 0.5.0. They compile only
   because of `dependency_overrides`. Published today, every one would resolve a core that predates
   `PlateController`, `PlateView`, `PlateSelector`, `PlateAsset`, `SlotBehavior`, `PlateMirror` and the
   required `onChooseCharacter` parameter, and fail to compile in a consumer's project.

2. **Nine `dependency_overrides` blocks paper over it, in three different mechanisms:**
   inside `palestine_plate/pubspec.yaml` (a published file), inside `pubspec_overrides.yaml`
   (`core_plate_bloc`, `yemen_plate`, `palestine_plate/example`), and inside example pubspecs
   (`core_plate/example`, `iran_plate/example`, `germany_plate/example`, `plate_keypad/example`).
   `plate_keypad/example` overrides `plate_keypad` but **not** `core_plate`, so alone among the examples
   it resolves the engine from pub.dev.

## Scope

**In:** `pubspec.yaml` and `pubspec_overrides.yaml` in every package and every `example/`; a new root
`pubspec.yaml`; the root `.gitignore`; capturing the analyze/test baseline.

**Out — frozen:**
- Every `.dart` file. This phase changes no Dart.
- `pubspec.lock` files. `flutter pub get` will regenerate them; that is expected. Do not hand-edit one.
- `plate_number_holder/` — out of scope for the entire roadmap. Do not add it to the workspace, do not read it.
- Package `version:` fields. Bumping versions is P11's job, after the API actually changes.
- All `analysis_options.yaml` files. Consolidating those six near-identical copies is tempting and is
  deliberately deferred — it changes lint output, which would contaminate the baseline this phase exists to capture.

## Steps

### 1. Capture the baseline FIRST, before editing anything

```bash
cd ~/StudioProjects/plate
mkdir -p /tmp/plate-baseline
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos) > "/tmp/plate-baseline/analyze-$p.txt" 2>&1
  echo "$p exit=$?"
done
(cd palestine_plate && flutter test) > /tmp/plate-baseline/test-palestine.txt 2>&1
echo "palestine test exit=$?"
```

`palestine_plate/test/failures/` currently holds four diff PNGs for `wb_modern_car_green`, all newer than
`test/goldens/wb_modern_car_green.png`, so the golden test is probably already failing. **Read
`/tmp/plate-baseline/test-palestine.txt` and decide now:**

- If the golden fails and the diff is a rendering regression → stop and report it. Do not proceed;
  a refactor on top of an unexplained rendering change cannot be verified.
- If the golden fails and the diff is a deliberate, already-accepted visual change → run
  `cd palestine_plate && flutter test --update-goldens`, delete `test/failures/`, and record in the
  commit message that the golden was re-baselined in P0.

Whichever it is, **write the decision into the commit message.** Every later phase compares against it.

### 2. Create the root workspace

The SDK floor is `>=3.10.0`, so pub workspaces are available. Create `~/StudioProjects/plate/pubspec.yaml`:

```yaml
name: plate_workspace
publish_to: none

environment:
  sdk: '>=3.10.0 <4.0.0'

workspace:
  - core_plate
  - core_plate/example
  - core_plate_bloc
  - core_plate_bloc/example
  - plate_keypad
  - plate_keypad/example
  - iran_plate
  - iran_plate/example
  - germany_plate
  - germany_plate/example
  - palestine_plate
  - palestine_plate/example
  - yemen_plate
  - yemen_plate/example
```

Note `plate_number_holder` is deliberately absent.

Add `resolution: workspace` to all fourteen member pubspecs.

### 3. Fix the constraints

In every package that depends on `core_plate`, change the constraint to admit the version actually in
the repo. Use `^0.5.0` (not `any`, not a path) so the published artefact is honest:

| File | Was | Becomes |
|---|---|---|
| `iran_plate/pubspec.yaml` | `core_plate: ^0.1.0` | `core_plate: ^0.5.0` |
| `germany_plate/pubspec.yaml` | `core_plate: ^0.1.0` | `core_plate: ^0.5.0` |
| `palestine_plate/pubspec.yaml` | `core_plate: ^0.1.0` | `core_plate: ^0.5.0` |
| `plate_keypad/pubspec.yaml` | `core_plate: ^0.1.0` | `core_plate: ^0.5.0` |
| `yemen_plate/pubspec.yaml` | `core_plate: ^0.2.0` | `core_plate: ^0.5.0` |
| `core_plate_bloc/pubspec.yaml` | `core_plate: ^0.5.0` | unchanged |

Do the same in the seven example pubspecs, and for their own package constraints
(`iran_plate: ^0.1.0` etc. stay at `^0.1.0` — those versions are accurate).

### 4. Delete every override

With a workspace, path overrides are unnecessary — the workspace resolves siblings.

- Delete `core_plate_bloc/pubspec_overrides.yaml`, `yemen_plate/pubspec_overrides.yaml`,
  `palestine_plate/example/pubspec_overrides.yaml`.
- Delete the `dependency_overrides:` block from `palestine_plate/pubspec.yaml` (lines 41–45).
  This one is the worst of the nine: it is in a *published* file.
- Delete the `dependency_overrides:` blocks from all seven `example/pubspec.yaml` files, and the
  now-orphaned explanatory comments above them.

### 5. Break the engine-example → country dependency

`core_plate/example/pubspec.yaml` depends on `iran_plate`, and `core_plate/example/lib/main.dart:3`
imports it. That makes the engine's own example depend on a country package, which is exactly what
`core_plate.dart:10-14` says must never happen, and it is a byte-level near-clone of
`iran_plate/example/lib/main.dart`.

**In this phase, only remove the pubspec dependency and leave a `TODO(P10)` marker** — rewriting the
example's Dart is P10's job, and this phase changes no Dart. Concretely: comment out the `iran_plate`
dependency line with a one-line note pointing at P10, and confirm the example is excluded from the
workspace build if it no longer resolves. If removing it breaks `flutter analyze` for that example,
leave the dependency in place, add the `TODO(P10)` comment, and record it as carried forward.

### 6. Root `.gitignore`

Confirm these are ignored repo-wide; add any that are not:

```
**/.dart_tool/
**/build/
**/*.iml
**/pubspec_overrides.yaml
*.log
```

`palestine_plate/example/.dart_tool/chrome-device/` contains a full Chrome profile — cookies,
`Login Data`, session storage. Verify it is not tracked: `git ls-files | grep chrome-device`.
If it is tracked, **stop and report it** rather than removing it silently; purging it from history is
a decision for the repo owner.

## Verification

```bash
cd ~/StudioProjects/plate
flutter pub get                      # resolves the whole workspace at once

# one core_plate, resolved from the workspace, in every package
for p in iran_plate germany_plate palestine_plate yemen_plate plate_keypad core_plate_bloc; do
  echo "== $p"; (cd "$p" && flutter pub deps --style=compact 2>/dev/null | grep -m1 core_plate)
done

# no overrides left
find . -name pubspec_overrides.yaml -not -path './plate_number_holder/*'   # must print nothing
grep -rn "dependency_overrides" --include=pubspec.yaml . | grep -v plate_number_holder   # nothing

# analyze parity with the baseline
for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos) > "/tmp/plate-after/analyze-$p.txt" 2>&1
  diff "/tmp/plate-baseline/analyze-$p.txt" "/tmp/plate-after/analyze-$p.txt" && echo "$p: unchanged"
done

(cd palestine_plate && flutter test)
(cd palestine_plate/example && flutter run -d linux --debug &) ; sleep 30 ; # app comes up
```

**Success:** the workspace resolves; no override files remain; `flutter analyze` output is byte-identical
to the baseline for every package; `palestine_plate`'s tests are in the state P0 decided on; every example
still runs.

## Dependencies

None. This is the first phase.

## Line estimate

±0 Dart. −180 lines of YAML (nine override blocks and their comments), +18 (root pubspec, `resolution:` keys).
