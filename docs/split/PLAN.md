# `plate_number` → `core_plate` + country packages

Master plan. Phases live as runnable prompts in `docs/split/skills/p1-…` … `docs/split/skills/p12-…`;
progress is tracked in `PROGRESS.md` beside this file. (They were briefly `.claude/skills/`;
they are not there now, and a prompt that tells you to read `.claude/skills/...` is stale.)

**Repo layout as of the last rename.** The package repo is `plate-core` — renamed from
`plate-number-upgrade` in commit `8e52fd9`, which also deleted `example/` outright now that
`plate_number_holder` supersedes it. The two repos sit side by side:

```
StudioProjects/
  plate-core/             the package (still named `plate_number` in pubspec.yaml)
  plate_number_holder/    the showcase app, path-depends on ../plate-core
```

`plate-core` is a directory name, not a package name. The package inside it is still
`plate_number`, and the naming decision in §5.1 below is still open.

Phase 0 (splitting `example/` out into `plate_number_holder`) is **done**, and so are P0.5,
P0.75 and — through the animation performance pass rather than through its own prompt — P1.
See `PROGRESS.md` for commits.

---

## 1. What the recon actually found

2 588 lines in `lib/`. The headline: **the widget layer is already country-agnostic.**
`PlateCanvas`, `PlateSlotItem`, `PlateFrame`, `PlateCharacterPicker` and the bloc hold no
country knowledge — they read geometry, alphabets and direction off the spec, exactly as
`claude.md` §2/§3 demand. Only four call sites in the whole library name a country.

So the split is cheap. What is *not* cheap, and is where the real work is, is that the
library carries four kinds of avoidable weight:

**(a) Redundant data that must be kept in sync by hand.**
`PlateSlot` carries `index` and `next`. Verified across all three specs:

```
irCar        slots= 8   index==position: True   next==index+1: True
irBicycle    slots= 8   index==position: True   next==index+1: True
deCar        slots= 7   index==position: True   next==index+1: True
```

Both fields are derivable from list position in every spec that exists. They cost a
duplicate-index assertion, a `next`-resolves assertion, a cycle-detection walk, a
reverse-scan `_previousSlot`, and a linear `slotAt`. ~70 lines exist only to defend data
that never varies.

**(b) One concept spelled two ways.**
`LetterInputMode` (3 values) and `PlateInputSource` (4 values) describe the same thing, with
an `inputSourceFromLetterMode` adapter between them and a `@Deprecated` parameter on
`PlateCanvas` threading the old one through. `PlateSlotItem.letterInputMode` is declared,
documented — and **never read in its body**. Verified.

**(c) Logic that lives in the widget tree and therefore cannot be tested.**
`_PlateCanvasState` does five unrelated jobs: focus-node lifecycle, active-slot tracking,
navigation (advance / backspace / first-empty), picker presentation, and painting. The first
four are pure state machine, reachable today only through `pumpWidget`.

**(d) Derivations pushed onto the host app.**
`plate_number_holder`'s `device_stage.dart` contains 35 lines (`_unavailableKeysFor`) that
walk the spec's text groups, build the prefix typed so far, and ask the German validator what
to bar next. Nothing in it is app-specific. Every consumer that wants validated input would
have to write it again.

### A third close pass: two things that outrank everything above

Two more passes through the repo — one hunting specifically for state/lifecycle bugs across
the `PlateCanvas` ↔ holder boundary, one just looking at what sits in the repo root rather
than `lib/` — found two things serious enough to reorder the plan around.

**A confirmed, live bug: the showcase silently reuses plate state across incompatible specs on
every device cycle.** `PlateCanvas`'s focus nodes and `TextEditingController`s are built once
in `initState` from `widget.spec.slots` (`plate_canvas.dart:57-61`) and never rebuilt.
`_PlateCanvasState.didUpdateWidget` reacts only to `widget.controller` changing — never to
`widget.spec` changing. That is only safe if Flutter gives `PlateCanvas` a fresh `State` every
time the showcase swaps devices. It does not:

```bash
grep -n "key:\|Key(\|ValueKey\|GlobalKey" device_frame.dart plate_display.dart device_stage.dart
# → one match, on an unrelated method named _onDeckKey
```

Zero `Key`s anywhere from `DeviceFrame` down to `PlateCanvas`. `DeviceFrame`'s content fades
via a plain `Opacity` wrapper around `builder: widget.builder` — no `AnimatedSwitcher`, no
`IndexedStack`, nothing that would force Flutter to discard and rebuild the subtree. The
widget stays at the same type and the same position in the tree across every device hop, so
Flutter's default reconciliation **reuses the same `_PlateCanvasState` object** while
`device_stage.dart` swaps `spec:` underneath it — from `irCar` (8 slots) to `deCar` (7 slots)
to `irBicycle` (8 slots) and back, each with a different slot count and a different
typed/chosen pattern per index. The focus-node and controller maps built for the first spec
are silently reused for every spec after it.

This is corrected from an earlier draft of this plan, which claimed under what is now P4 that
"the holder never hits it because it recreates the whole subtree on device swap." That claim
was wrong — checked against the actual code, not assumed — and is struck from P4 below. The
bug is live, in the showcase you can run today, on every single device transition. P4 (already
the phase that gives `PlateCanvas` a proper input-machine lifecycle) now treats this as its
primary deliverable, not an incidental fix, and gets a before/after repro step in its
verification. See P4 for the fix; nothing before P4 needs to change to accommodate this, but
P1 and P3's holder-side edits are written knowing it's there.

**The package is scaffolded as an app, not a package.** `.metadata` declares
`project_type: app`. The repo root carries full platform-runner directories — `android/`
(Gradle, `build.gradle.kts`, a `gradlew`), `linux/` (CMake, a C++ `runner/`), `windows/`
(same), `web/` (`index.html`, `manifest.json`, a favicon) — for a pure-Dart-and-Flutter-widgets
library with no platform channel and no native code. `android/`, `web/` and `macos/` are at
least listed in `.gitignore`; `linux/` and `windows/` are not (only their `build/`
subdirectories are), so those two are almost certainly tracked in git today. None of this
belongs in a package meant to be split into five publishable units in P10-P12 — a real
`flutter create --template=package` scaffold has none of it. Given its own phase, **P0.75**,
sequenced right after the README/asset cleanup and before any Dart source changes.

### Latent bugs found on the way

| | |
|---|---|
| ~~`PlateNumber` has no `==`~~ — **fixed** | Fixed outside this plan, in the animation performance pass. `PlateNumber` now has `==`/`hashCode` over `values`, *and* the canvas no longer selects the whole value: `_FrameBinding` selects `isCompleted`, `_SlotBinding` selects its own `String?`, so a keystroke rebuilds one slot. P5 must not re-add either. |
| `PlateCardState` has no `==` | Still true. Cheap to add (`PlateSpec` equality is `id`-based) and it is what stops the bloc's no-op emissions waking the per-slot subscriptions. P5. |
| `PlateAlphabet` has no `==` | `plate_keypad.dart:254` decides RTL with `letterAlphabet == PlateAlphabet.persianPlateLetters`. That is *identity* comparison. A caller who builds an equal alphabet inline silently gets LTR. |
| `bloc_concurrency` in `pubspec.yaml` | Zero references in `lib/`, `test/` or the holder. Dead dependency shipped to every consumer. |
| `PlateKeypadTheme.copyWith` | Never called anywhere. 18 dead lines. |
| `PlateSpec.slotAt` | Linear scan, called once per glyph per frame. |
| `test/bloc_test.dart:25-27` calls `PlateNumber.copyWith` directly | A **second** call site P5 originally missed — the plan said "one call site" (in `PlateCardBloc`). Both must move to a direct constructor call in the same phase, or the test won't compile after `copyWith` is deleted. |
| `GermanPlateValidator`'s district regex accepts any 1–3 Latin letters | `docs/districts.json` — untracked by any `pubspec.yaml`, staged into this session by hand — lists ~150 real `Unterscheidungszeichen` codes. The validator never reads it: `AA`, `ZZ`, `QQ` all pass today though none is a real district. Whether to wire the real list in is a product decision, not a refactor one, but the fact that curated real-world data sits in the repo unused belongs in the plan. See **P7.5** below. |
| `docs/forbidden.json` duplicates `_forbiddenLetterPairs`/`_forbiddenNumbers` | Same pairs, same comment about FZV §8, hand-copied into `german_plate_validator.dart` as Dart `const Set`s instead of the JSON being the source of truth. Two places to update if the list ever changes. Fold into P7 — load-or-inline is one decision, not two files. |
| **`README.md` documents a package that no longer exists** | Every code sample imports `bicycle_plate/index.dart` and `car_plate/index.dart` (deleted), constructs `PlateCardBloc(PlateType.irCar)` (no `PlateType` in the codebase — the bloc takes a `PlateSpec`), references `TypeIsChanged`, `PlateTypeSelector`, `bloc.plateType`, and a "Features" list (`spacingScale`, custom letter widgets) describing an API that predates `PlateSpec` entirely. This is the first thing anyone evaluating the package reads, and none of it compiles. New phase — **P0.5**, see below; it does not depend on the split and should not wait for it. |
| **9.6 MB of untracked-by-pubspec assets ship inside the package** | `assets/CopyQ.ckUzym.png` (584 KB), `CopyQ.emHrGZ.png` (361 KB), `CopyQ.fSSaTj.png` (513 KB) — clipboard-tool screenshots, by their name — plus `example1.png`, `example2.gif` (1.1 MB), `motor.png`. None is declared in `pubspec.yaml`'s `flutter.assets:`, so Flutter's bundler never pulls them into an app build, but `.gitignore` doesn't exclude them either (`flutter_*.png` is ignored; these don't match), so they are tracked in git and would ship in the tarball on `flutter pub publish`. `example1.png` and `example2.gif` are at least referenced — by the stale `README.md` above. The three `CopyQ.*` files and `motor.png` are referenced nowhere. Two root-level `screenshot2.png`/`screenshot3.png` (1.1 MB combined) are also untracked-by-ignore and unreferenced by anything in `lib/` or `README.md`. Covered by **P0.5**. |
| `PlateCardBloc`'s three `on<...>` handlers take a raw, ungenericized `Emitter emit` | Should be `Emitter<PlateCardState> emit`. `analysis_options.yaml` includes only stock `flutter_lints` with zero project-specific rules, so nothing catches this today. Two-line fix, folded into **P5**, which is already open in this area for the equality work. |
| `PlateSlotItem._buildTypedField` builds a full `ThemeData.light()` per slot | To override three `textSelectionTheme` colors. Up to 8 times per plate, every build that reaches a typed field — a real object, not a cheap one, and it hardcodes light mode regardless of the host app's actual theme. Folded into **P3**, which already rewrites this method for `SlotBehavior`. |
| `lib/dev/flag_panel_gallery.dart` is a third, previously-unchecked call site of `PlateFlag`'s old constructor | `PlateFlag(countryCode: 'ir')` and `CountryPanel(country: PlateCountry.iran)`, reached through four deep `package:plate_number/model/...` imports rather than the barrel. Every symbol it touches moves in P8/P11. Folded explicitly into **P8** below — the original draft only anticipated `plate_canvas.dart` and `country_panel.dart` as call sites, which was incomplete. |
| `plate_typist.dart`'s letter-picker path is dead code at the one real call site | `useLetterPicker: false` always, in `device_stage.dart`'s only call to `PlateTypist.run`. `_pickLetter` (44 lines) and the `if (useLetterPicker)` branch in `_runStep` never execute. Holder-only, demo-only code — noted here for completeness, deliberately **not** given a phase: it costs nothing to leave (dead code in an unpublished showcase app is a different order of problem than dead code in a published package), and this plan already has enough holder-side surface area in P1/P4/P7. Worth a one-line mention in a future holder cleanup, not a reason to add a fifteenth phase. |

---

## 2. Target package layout

```
plate-core/
  pubspec.yaml            pub workspace root (Dart ≥3.6; SDK constraint already allows it)
  packages/
    core_plate/           the engine — no country knows about it, it knows no country
    plate_keypad/         optional soft keyboard (depends on core_plate)
    iran_plate/           country + alphabets + ir.car + ir.bicycle + flag
    germany_plate/        country + de.car + decals + validator + flag
  plate_number/           thin facade: depends on all four, re-exports them
```

```
iran_plate ────┐
germany_plate ─┼──> core_plate
plate_keypad ──┘

plate_number ──> all four        (compatibility shim, retired in P12)
```

`iran_plate` and `germany_plate` never see each other. An app shipping only Iranian plates
compiles neither the German validator nor its PNGs nor the soft keyboard.

**Why `plate_keypad` is its own package.** It is ~460 lines of fake soft keyboard with its own
theme class, useful only under `PlateInputSource.packageKeypad`. Consumers who drive input
from the IME or their own pad — which is most of them — should not compile it. It is the one
piece of the library that is genuinely optional.

**Why the `plate_number` facade survives until P12.** So `plate_number_holder` keeps a single
import through the entire refactor and every phase stays independently verifiable. It is
~25 lines of `export`.

---

## 3. Line budget

Each phase's number is what that phase removes from `lib/`, net of what it adds.

| phase | | net lines |
|---|---|---|
| ~~P1~~ | slot identity — drop `index` / `next` — **landed** | −70 (claimed; not measured separately, it arrived inside the performance pass) |
| P2 | plate geometry — `PlateBox`, `PlatePanel` | −80 |
| P3 | input model — delete `LetterInputMode`, add `SlotBehavior` | −60 |
| P4 | extract the input machine from `PlateCanvas`; **fixes the confirmed live state-reuse bug** (§1 above) | ±0 (structural — but this is the highest-risk phase in the plan, not the lightest) |
| P5 | value semantics — equality, `_props`, kill `copyWith` | −85 |
| P6 | plate text into the model, merge `ShowPlate`/`PlateText` | −35 |
| P7 | validation as data | −60 lib, −35 holder |
| P8 | country decoupling — `PlateAsset`, alphabet `direction` | −35 |
| P9 | keypad compaction — one `_KeyGrid` | −90 |
| | **`lib/` after P9** | **2 588 → ~2 075** |

Then P10–P12 redistribute those ~2 075 lines:

| package | ~lines |
|---|---|
| `core_plate` | 1 475 |
| `plate_keypad` | 315 |
| `iran_plate` | 130 |
| `germany_plate` | 130 |
| `plate_number` facade | 25 |

**Core ends at ~57 % of today's single package**, and the number a consumer actually compiles
for one country is ~1 600 rather than 2 588 — before counting the two dependencies (`bloc_concurrency`,
`country_flags`) that stop shipping at all.

**The 2 588-line baseline is stale.** It predates P1, P0.5, P0.75 and the performance pass, all
of which changed `lib/`. Re-measure before quoting a percentage; the *shape* of the budget —
where the weight is and which phase removes it — is what still holds.

P1–P9 are worth doing on their own merits. If the split were abandoned after P9 the library
would still be materially better. P10–P12 are then close to mechanical.

---

## 4. Phase index

Ordering principle: **data-structure changes first** (they cascade into everything downstream),
then behaviour extraction, then packaging. Each phase ends analyzer-clean with
`plate_number_holder` still running.

| | skill | what it changes | breaks |
|---|---|---|---|
| P0.5 | `p0.5-repo-hygiene` | rewrites `README.md` to the real API; deletes/relocates dead assets | `README.md`, `assets/`, `.gitignore`, `pubspec.yaml` |
| P0.75 | `p0.75-package-template` | removes `android/`/`linux/`/`windows/`/`web/` app scaffolding; `.metadata` → `project_type: package` | repo root only, no Dart source |
| P1 | `p1-slot-identity` | `PlateSlot` loses `index`/`next`; positions come from list order | `plate_canvas`, `plate_spec`, **and the full `device_stage.dart` chain — see its expanded holder section** |
| P2 | `p2-plate-geometry` | `PlateBox` + `PlatePanel`; `PlateSpec` 12 face fields → 5 | all three specs, `plate_canvas`, `country_panel` |
| P3 | `p3-input-model` | `LetterInputMode` deleted; `SlotBehavior` resolved once | `plate_slot_item`, `plate_canvas`, holder's `plate_display` |
| P4 | `p4-input-machine` | focus/navigation out of `_PlateCanvasState` | `plate_canvas`, `plate_input_controller` |
| P5 | `p5-value-semantics` | `==` where it is load-bearing; `_props`; ids | models, theme, bloc state, **and `test/bloc_test.dart`'s direct `copyWith` call** |
| P6 | `p6-plate-text` | group rendering into `PlateSpec`; one empty-state widget | `show_plate`, `plate_spec` |
| P7 | `p7-validation-as-data` | `PlateValidator` in core; Germany becomes two `Set`s; forbidden-pairs sourced from `docs/forbidden.json` once, not duplicated | validator, canvas, holder |
| P7.5 | `p7.5-district-data` | decide + implement whether `docs/districts.json`'s ~150 real codes back the district check | `german_plate_validator`, `docs/districts.json` |
| P8 | `p8-country-decoupling` | `PlateAsset` on `PlateCountry`; alphabet `direction` | `plate_flag`, `plate_keypad`, `country_panel`, pubspec |
| P9 | `p9-keypad-compaction` | one `_KeyGrid` for both pads | `plate_keypad` only |
| P10 | `p10-core-package` | `packages/core_plate` + workspace + facade | every import |
| P11 | `p11-country-packages` | `iran_plate`, `germany_plate` | specs, assets, tests |
| P12 | `p12-keypad-package-and-cutover` | `plate_keypad`; holder points at real packages | holder pubspec |

Dependencies:

- **P0.5 depends on nothing** and blocks nothing downstream. It touches no Dart code that later
  phases edit. Run it whenever — first, if the goal is "stop the bleeding" before a long
  refactor; last, if the goal is momentum on the actual code. It is listed first because it is
  the cheapest, highest-visibility fix in the whole plan: a stranger reading this package today
  cannot get past the README's first `import`.
- **P0.75 depends on nothing** either, and is sequenced right after P0.5 rather than anywhere
  else purely by convention (both are "fix the repo, not the code" phases). It touches no file
  any Dart phase edits. Safe to run in parallel with P0.5, or skip entirely if the team decides
  the platform folders are staying for now — nothing downstream assumes they are gone.
- **P9 is independent.** It touches only `plate_keypad.dart` and can be run any time after P8
  (which removes the Persian defaults it would otherwise re-introduce).
- **P6 is independent** of P4/P5 and can be pulled forward if you want an early win.
- **P7.5 depends on P7** (it edits the same file `ForbiddenByGroup` lands in) but is split out
  because it is a product decision — validate against a real district list or not — not a
  mechanical refactor, and bundling a decision into a refactor phase is how decisions get made
  by default instead of on purpose.

---

## 4b. Widgets, not widget functions

Added after the first pass through this plan, and folded into every phase from P1 on rather
than given a phase of its own: `claude.md` §1 forbids widget-returning functions, and the
codebase still has a few. Each phase converts the ones in the files it already edits, under one
constraint — **only where the widget class is not materially longer than the function it
replaces.** A short helper used once inside a single `build`, or one closing over several
locals that would each become a field, an argument and a `final`, gets inlined into its caller
instead of promoted. If a conversion would roughly double what it removes and buy no rebuild
isolation, the phase leaves it and says so. Builder callbacks are the standing exception.

Where they actually are, so no phase has to go looking:

| file | functions | phase |
|---|---|---|
| `plate_slot_item.dart` | `_buildTypedField`, `_buildChosenSlot` | P3 (rewrites both anyway) |
| `plate_keypad.dart` | `_buildDigitKey`, `_buildLettersLayer` | P9 (`_KeyGrid` is their replacement) |
| holder `showcase/device_stage.dart` | `_buildDevice` | P7, if it comes out at a similar length |

`plate_canvas.dart` has none left — `_FrameBinding`, `_SlotBinding` and `_PlateFaceClipper` are
already classes, which is exactly why the performance pass could isolate their rebuilds.

---

## 5. Decisions still open

These change the shape of P10–P12. Worth settling before P10, cheap to settle now.

1. **Package names.** `core_plate` / `iran_plate` / `germany_plate` (as requested) versus
   `plate_core` / `plate_ir` / `plate_de`. The prefixed form sorts together on pub.dev and
   reads as a family; the suffixed form reads better in code (`iran_plate` is a noun).
   The plan is written for the suffixed form; a rename is one `sed` before P10.

2. **Publish to pub.dev, or path-only?** If published, each package needs its own version,
   CHANGELOG and LICENSE, and `iran_plate` must depend on a published `core_plate` *range*
   rather than a path — which makes the `plate_number` facade permanent rather than
   temporary, since that is what a user would sensibly depend on. If path-only, retire the
   facade in P12 as planned.

3. **Keep `bloc`?** `PlateCardBloc` is 27 lines over three events. It costs consumers `bloc`,
   `flutter_bloc` and `bloc_test`. A `ValueNotifier<PlateCardState>` would do the same job with
   zero dependencies. **Recommendation: keep it** — it is the package's published contract and
   the holder app is bloc-shaped throughout — but P4 deliberately gives the input machine *no*
   bloc dependency (it takes a read callback and a commit callback), so this stays a
   one-file decision later rather than a rewrite.

4. **Does `PlateCharacterPicker` belong in core?** It is Cupertino-flavoured and 62 lines, and
   `PlateCanvas.onChooseCharacter` already lets a host supply its own. Candidate for
   `plate_keypad` (renamed `plate_input_ui`) in P12. Not decided here.
