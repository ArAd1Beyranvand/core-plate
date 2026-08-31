# `plate_number` → `core_plate` + sibling country packages

Master plan, **second edition**. The first edition (P0.5 → P12, workspace-with-`packages/`
layout, blocking validation) is superseded from its P6 onward. Everything through the old P5
has landed and is history; everything after it has been rewritten around two decisions the
user made on 2026-08-31:

1. **Validation never blocks input.** The library may *tell* a host that a plate is invalid.
   It may not stop a key from being typed. The whole barred-key path — `barredNextDigits`,
   `barredNextLetters`, `PlateKeypad.unavailableKeys`, the holder's `_unavailableKeysFor` —
   is deleted, not refactored. What survives is a verdict, opt-in, painted red.
2. **The country packages are siblings of `core-plate`, not children of it.** There is no
   `packages/` directory and no pub workspace. `iran-plate`, `germany-plate` and
   `plate-keypad` are their own repositories beside `core-plate`, each a publishable package
   that depends on `core_plate`.

Phases live as runnable prompts in `docs/split/phases/p1-…` … `p9-…`; progress is tracked in
`PROGRESS.md` beside this file; paste-ready wrappers are in `PROMPTS.md`.

> **The old `docs/split/skills/` directory is dead.** `p0.5` … `p5` are the record of work that
> landed; `p6` … `p12` describe a target that no longer exists and must not be run. See
> "What happened to the old numbering" at the end of this file.

---

## 0. Where things stand

**Landed** (first edition, committed): repo hygiene, package-template correction, slot
identity, plate geometry, input model, the input machine and its live state-reuse bug fix, and
value semantics. `lib/` today is 26 files across `bloc/ input/ model/ theme/ validators/
widgets/`, with `lib/plate_number.dart` as an 18-line barrel. `pubspec.yaml` no longer carries
`bloc_concurrency`.

**Not started**: everything in this file.

**Repo layout today:**

```
StudioProjects/plate/
  plate-core/             the package (still named `plate_number` in pubspec.yaml)
  plate_number_holder/    the showcase app, path-depends on ../plate-core
```

**Repo layout this plan produces:**

```
StudioProjects/plate/
  core-plate/             package `core_plate`   — the engine, knows no country
  iran-plate/             package `iran_plate`   — depends on core_plate
  germany-plate/          package `germany_plate`— depends on core_plate
  plate-keypad/           package `plate_keypad` — depends on core_plate
  plate_number_holder/    depends on all four by path
```

```
iran_plate ────┐
germany_plate ─┼──> core_plate
plate_keypad ──┘
```

`iran_plate` and `germany_plate` never see each other. `core_plate` sees neither. An app
shipping only Iranian plates compiles no German validator, no German PNGs, and no soft
keyboard.

**Directory name vs package name.** `plate-core` is a directory. The package inside it is
still called `plate_number` and is renamed to `core_plate` in P9. The directory is renamed to
`core-plate` in the same phase. Do not treat the current directory name as evidence that the
naming decision was already applied.

---

## 1. Change 1 — validation stops policing input

### What exists today

Three pieces, in three places, all built to *prevent* a keystroke:

| where | what |
|---|---|
| `lib/validators/german_plate_validator.dart:136,152` | `barredNextDigits` / `barredNextLetters` — given a prefix, return the characters that would complete a forbidden value |
| `lib/widgets/plate_keypad.dart:81,121,237` | `unavailableKeys` parameter; `_keyEnabled` returns false for a key in that set; `_Key.enabled: false` greys it out and `onTap` is set to `null` |
| holder `lib/showcase/device_stage.dart:114-148,350` | `_unavailableKeysFor` — 35 lines that find the active slot's group, build the typed prefix, and ask the German validator what to bar; fed to `PlateKeypad.unavailableKeys` |

The showcase's auto-typist already exposes how uncomfortable this is: the scripted typist
commits `88` while the interactive keypad greys out the second `8`. That tension was
*commented and deliberate*. It is now simply gone — the second `8` is tappable, and the plate
turns red once it lands.

### What it becomes

A validator answers one question — *is this plate, as it stands, valid?* — and nothing else.

- `PlateValidation { bool get isValid; String? reason; }` in core.
- `PlateValidator.validate(PlateEntry entry) → PlateValidation`. No `barredNext`. No
  `completionsOf`. No `ForbiddenByGroup` mixin (there is no per-keystroke rule left for it to
  serve).
- `PlateCanvas` takes `validator` **and** `autoValidate` (default `false`). With
  `autoValidate: false` the canvas never calls the validator and never paints red — a
  developer who wants their own timing reads `PlateInputController.validation` and decides.
  With `autoValidate: true` the canvas validates on every committed value and paints the
  alert.
- The alert is exactly what the holder paints today: the frame/underline goes red. No dialog,
  no snackbar, no thrown exception, no rejected keystroke.
- `PlateKeypad` loses `unavailableKeys` entirely. `_keyEnabled` keeps its *other* reason for
  disabling a key — "this character is not in the active alphabet, so `submit()` would reject
  it anyway" — which is a fact about the alphabet, not a validation policy, and stays.
  `_Key.enabled` and `theme.disabledInk` therefore survive; only the validation input goes.

**The one thing to be careful about.** `_Key`'s disabled state is currently reached by two
routes and the doc comments conflate them. After P2 there is one route. Reword the comments;
do not delete the mechanism.

This is P2. It is a deletion phase that happens to add a small interface, and it should come
out net-negative on lines in both repos.

---

## 2. Change 2 — the split is siblings, and the core has to earn it

The user's framing: *"it needs actually cleaning the core. So it's 80 % of your focus."*
That is reflected directly in the phase count — **six phases clean the core, three extract
packages** — and in the ordering rule below.

### Why sibling packages change the plan more than they look like they should

The first edition put everything under one repo root with a pub workspace and a `plate_number`
facade absorbing every move, so the holder's imports never changed until the very last phase.
Siblings give that up. There is no workspace to resolve members, no facade sitting above them,
and each package has its own `pubspec.yaml`, version, `CHANGELOG.md` and `LICENSE` from the
moment it exists. Consequences the phases below are written around:

- **Every extraction phase is a two-repo commit minimum** (the new package + the holder), and
  P8 is a four-repo commit. There is no "the facade absorbs it" escape hatch.
- **Path dependencies are the wiring during development.** `iran-plate/pubspec.yaml` gets
  `core_plate: {path: ../core-plate}`. If and when these are published, those become version
  ranges; the layout does not change.
- **An extracted package can never import back into core's `src/`.** With one package that was
  a style rule. With four it is a compile error — which is the point, and why the core surface
  has to be settled (P5) *before* anything moves out.
- **The `plate_number` facade does not survive.** With siblings there is no natural home for
  it: it would be a fifth repo whose only content is four `export` lines. The holder depends
  on the four packages directly. If a convenience meta-package is wanted later it is a new
  repo, not a leftover.

### Why six cleaning phases

Everything that is wrong with the core is wrong in a way that only *becomes* a problem when it
is split. Fixing it after the split means fixing it four times across four repos, with a
version bump each. Fixing it before means one commit in one repo. Concretely, what P1–P6
clear out:

- **Country knowledge in core** (P3). `PlateFlag` hard-codes Iran's SVG path;
  `PlateKeypad` defaults to the Persian alphabets and infers RTL by comparing against
  `PlateAlphabet.persianPlateLetters`; `CountryPanel` defaults to `PlateCountry.iran`;
  `PlateSlotItem` hard-codes `'؟'` as its placeholder; `PlateCountry.iran` / `.germany` are
  static members of a class that will live in core. Every one of these is a compile error
  waiting for P8.
- **Validation in the wrong shape** (P2) — see §1.
- **Rendering logic in the widget rather than the model** (P1). Grouping lives partly in
  `ShowPlate`, partly in `PlateSpec`. `PlateEntry` in P2 needs it in the model.
- **Two of everything in the keypad** (P4). Two grids, two highlight paths, two widget
  functions.
- **An undecided public surface** (P5). Today every file is public because
  `lib/plate_number.dart` exports all of them and nothing is under `src/`. A package's export
  list is its contract; four packages need four honest ones, and they are impossible to write
  while the core's own is accidental.
- **Dead weight and stale documentation** (P6). Known-dead: `PlateKeypadTheme.copyWith` (never
  called, 18 lines), the `args` dependency in `pubspec.yaml`, doc comments across
  `plate_alphabet.dart` and `plate_theme.dart` that describe "a real Iranian licence plate"
  for country-neutral code, a `README.md` and `CHANGELOG.md` that predate all of this.

Only after all of that is P7 (keypad out), P8 (countries out), P9 (rename + cutover) close to
mechanical — which is the test of whether P1–P6 did their job. **If an extraction phase finds
itself changing logic, an earlier phase left a leak; stop and report rather than fixing it
in place.**

---

## 3. Phase index

Ordering principle unchanged from the first edition: **data-structure changes first**, then
behaviour, then surface, then packaging. Each phase ends analyzer-clean with
`plate_number_holder` still running.

| | phase | what it changes | breaks |
|---|---|---|---|
| P1 | `p1-plate-text` | group rendering moves into `PlateSpec`; one empty-state widget | `show_plate`, `plate_spec` |
| P2 | `p2-validation-advisory` | **validation stops blocking input**; `PlateValidator` + `autoValidate` in core; `unavailableKeys` and both `barredNext*` deleted | validator, canvas, keypad, holder |
| P3 | `p3-country-decoupling` | `PlateAsset` on `PlateCountry`; alphabet `direction` + `placeholder`; country constants into `lib/countries/` | `plate_flag`, `plate_keypad`, `country_panel`, `plate_slot_item`, pubspec |
| P4 | `p4-keypad-compaction` | one `_KeyGrid` for both pads | `plate_keypad` only |
| P5 | `p5-core-surface` | `lib/src/` layout; the barrel becomes a decision, not a dump | every import in both repos |
| P6 | `p6-core-dead-weight` | dead code, dead deps, docs that lie | pubspec, docs, scattered comments |
| P7 | `p7-extract-keypad` | `../plate-keypad` package | holder pubspec + keypad imports |
| P8 | `p8-extract-countries` | `../iran-plate`, `../germany-plate` | specs, assets, validator, holder |
| P9 | `p9-cutover` | `plate_number` → `core_plate`; `plate-core/` → `core-plate/`; isolation proof; docs | everything left |

Dependencies, stated honestly rather than "strictly linear":

- **P1 → P2.** P2's `PlateEntry` is built on the grouping P1 moves into `PlateSpec`.
- **P2 → P4.** P4 rewrites the grids; it must not carry `unavailableKeys` through into
  `_KeyGrid` only for P2 to have deleted it. Run P2 first or P4 does double work.
- **P3 → P4.** P3 removes the Persian defaults and the `letterAlphabet ==
  persianPlateLetters` RTL sniff; P4 would otherwise re-introduce them into the shared grid.
- **P5 depends on P1–P4** because it decides what is public, and P1–P4 are still adding and
  deleting public names. Running it earlier means running it twice.
- **P6 is independent** of everything except that it should not run *before* P5 (P5 may make
  something dead that P6 would otherwise have kept).
- **P7 depends on P5** and nothing else in the cleaning set — the keypad is the least entangled
  thing in the library, which is exactly why it goes first among the extractions.
- **P8 depends on P3 and P7.** P3's acceptance grep is P8's precondition.
- **P9 depends on everything.**

---

## 4. Line budget

Estimates, not measurements. The 2 588-line baseline from the first edition is stale — it
predates four landed phases — so **re-measure `lib/` before P1 and record it in
`PROGRESS.md`**; a percentage quoted against a stale baseline is worse than no percentage.

| phase | | net lines |
|---|---|---|
| P1 | plate text into the model | −35 |
| P2 | validation stops blocking | −45 lib, −45 holder |
| P3 | country decoupling | −35 |
| P4 | keypad compaction | −90 |
| P5 | core surface | ±0 (moves, plus a barrel that shrinks) |
| P6 | dead weight | −40 lib, −1 dependency |

P2's holder number is bigger than the first edition's −35 because `_unavailableKeysFor`
(35 lines) now goes away *entirely* rather than moving into core, and the keypad's
`unavailableKeys` plumbing goes with it.

Then P7–P9 redistribute what is left:

| package | ~lines |
|---|---|
| `core_plate` | 1 400 |
| `plate_keypad` | 280 |
| `iran_plate` | 130 |
| `germany_plate` | 130 |

The number that matters is not the total; it is **what one consumer compiles**. An app that
wants Iranian car plates and drives input from the system keyboard compiles `core_plate` +
`iran_plate` and nothing else. P9's isolation check is what proves it, and it is the only
place in this plan where the claim is verified rather than asserted.

---

## 5. Widgets, not widget functions

Unchanged from the first edition, restated here so no phase has to go looking. `claude.md` §1
forbids widget-returning functions. Each phase converts the ones in the files it already
edits, under one constraint: **only where the widget class is not materially longer than the
function it replaces.** A short helper used once inside a single `build`, or one closing over
several locals that would each become a field, an argument and a `final`, gets inlined into
its caller instead of promoted. If a conversion would roughly double what it removes and buy
no rebuild isolation, the phase leaves it and says so in its report. Builder callbacks
(`BlocBuilder`, `AnimatedBuilder`, `LayoutBuilder`, `ValueListenableBuilder`) are the standing
exception.

Where they are today:

| file | functions | phase |
|---|---|---|
| `plate_keypad.dart` | `_buildDigitKey`, `_buildLettersLayer` | P4 (`_KeyGrid` is their replacement) |
| holder `showcase/device_stage.dart` | `_buildDevice` | P2, if it comes out at a similar length |

`plate_canvas.dart` has none — `_FrameBinding`, `_SlotBinding` and `_PlateFaceClipper` are
already classes, which is why the animation performance pass could isolate their rebuilds.
**Nothing in this plan may undo that isolation.** Every phase that touches the canvas or the
holder's stage inherits the rule: a rebuild that is currently scoped to one slot, one frame or
one key stays scoped there.

---

## 6. Decisions

Settled on 2026-08-31, recorded here so no phase re-opens them:

1. **Layout: siblings.** Separate directories beside `core-plate`, each its own package
   depending on `core_plate`. No `packages/` subdirectory, no pub workspace.
2. **Validation: verdict only, opt-in.** Red when `autoValidate` is on and the plate is
   invalid. Never blocks a key. See §1.
3. **Package names:** `core_plate`, `iran_plate`, `germany_plate`, `plate_keypad` (directories
   `core-plate`, `iran-plate`, `germany-plate`, `plate-keypad`).
4. **The `plate_number` facade is retired.** The holder depends on the four packages directly.
5. **Keep `bloc`.** `PlateCardBloc` is the package's published contract and the holder is
   bloc-shaped throughout. P5 nonetheless keeps the input machine free of any bloc dependency,
   so this stays a one-file decision if it is ever revisited.

Still open, and each is a question a phase must **ask, not assume**:

6. **Publish to pub.dev, or path-only?** (P9.) If published, each package needs its own
   version, `CHANGELOG.md` and `LICENSE`, and the three dependants must name a published
   `core_plate` range rather than a path — with the paths kept only as
   `dependency_overrides` for local development. If path-only, the paths stay as they are.
7. **Does `PlateCharacterPicker` belong in core?** (P7.) **Answered 2026-08-31: no — it moves
   into `plate_keypad`.** The Cupertino slot picker leaves core with the keypad, taking core's
   last `package:flutter/cupertino.dart` import. `PlateCanvas.onChooseCharacter` is now
   `required` — the accepted API break; core ships no built-in chooser, and a host with
   `chosen`-alphabet slots passes `PlateCharacterPicker.show` from `plate_keypad`.
8. **Does `docs/districts.json` back the German district check?** (P8.) ~150 real
   `Unterscheidungszeichen` codes sit in the repo, read by nothing; the validator's regex
   accepts any 1–3 Latin letters, so `QQ` passes today. Wiring the real list in is a product
   decision — stricter validation, a data file to maintain — not a refactor one. It rides
   along with P8 because that is the phase that already moves the validator, but it is asked
   separately.

Also unresolved and deliberately left alone: `docs/forbidden.json` duplicates
`_forbiddenLetterPairs` / `_forbiddenNumbers` by hand. P2 resolves it while it is already in
that file — one source of truth, either direction, stated in the commit message.

---

## What happened to the old numbering

The first edition ran P0.5, P0.75, P1 … P12, with a P7.5 wedged in. Everything from its P6 on
described the `packages/`-inside-one-repo target and the blocking validator, both of which are
now wrong. Rather than patch fourteen files, the remaining work is renumbered as a clean
**P1 … P9** in `docs/split/phases/`.

Mapping, for anyone reading an old commit message or an old note:

| old | new |
|---|---|
| P0.5, P0.75, P1–P5 | landed; history, not re-run |
| P6 plate text | **P1**, unchanged in substance |
| P7 validation as data | **P2**, *inverted* — it no longer bars keys |
| P7.5 district data | folded into **P8** as a question |
| P8 country decoupling | **P3**, unchanged in substance |
| P9 keypad compaction | **P4**, minus the `unavailableKeys` plumbing |
| — | **P5** core surface (new — the split needs it) |
| — | **P6** dead weight (new — was scattered through the old phases) |
| P10 core package | **P9**, and it is a rename rather than a `packages/` move |
| P11 country packages | **P8**, as sibling repos |
| P12 keypad + cutover | split: **P7** (extract) and **P9** (cut over) |

`docs/split/skills/p6-…` through `p12-…` are superseded and should be deleted. `p0.5` …
`p5` are the record of what landed and are worth keeping until P9, which rewrites the
documentation anyway.
