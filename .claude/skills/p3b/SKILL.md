---
name: p3b
description: "P3B — give core_plate a layout vocabulary for evenly-pitched registers, echo bands and stipple runs, so country packages stop unrolling for-loops by hand. Fixes three arithmetic drifts that no test could catch. Invoke with /p3b in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** high · **extended thinking:** ON
> **Requires:** /p1  (run before /p4 if you can)
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P3B — Register geometry

## Context (assume nothing else)

`core_plate` models a plate face as a bag of absolute rectangles. `PlateBox(left, top, width, height)`
(`lib/src/model/plate_box.dart`) is the only geometry primitive there is, and every positioned element —
`PlateSlot`, `PlateMirror`, `PlateRule`, `PlateLabel`, `PlateDecal` — carries one.

A real plate is not a bag of rectangles. It is a small number of **registers**: runs of equal cells at a
constant pitch, separated by wider gaps. `core_plate` already knows this semantically —
`PlateTextGroup` (`plate_spec.dart:122`) declares exactly which slots form a register, and carries a
`key` naming it (`'serial'`, `'governorate'`, `'district'`). But geometry knows nothing about it, so
every register is written out one cell at a time, by hand, and the two declarations drift.

Measured across the four country packages: **281 `PlateBox` literals**, of which roughly 140 sit inside a
provably regular run.

### The evidence

`yemen_plate/lib/src/unified_plates.dart:159-184` — the stippled separator strip, twenty-four rules:

```dart
  static const List<PlateRule> _carStipple = <PlateRule>[
    PlateRule(box: PlateBox(838, 1, 9, 7)), // CALIBRATE dot pitch
    PlateRule(box: PlateBox(838, 13, 9, 7)),
    PlateRule(box: PlateBox(838, 25, 9, 7)),
    …twenty-one more, y stepping by 12 each time…
    PlateRule(box: PlateBox(838, 277, 9, 7)),
  ];
```

That is a `for` loop, unrolled by hand, in 26 lines. `_motoStipple` (`:276`) is the same thing again,
22 rules in 24 lines. Together: 46 literals, 50 lines, to say *"a column of 9×7 dots at x=838, pitch 12."*

`yemen_plate/lib/src/northern_plates.dart:237-266` — the serial register at three lengths:

| Constant | cells | x values | width | pitch |
|---|---:|---|---:|---:|
| `_carGov2Serial4` | 4 | 140, 238, **335**, 433 | 98 | 98, **97**, 98 |
| `_carGov2Serial5` | 5 | 140, 218, 296, 374, 452 | 78 | 78 |
| `_carGov2Serial6` | 6 | 140, 205, 270, 335, 400, 465 | 65 | 65 |

One rule generates all three: *N cells filling x ∈ [140, 530).* 390/5 = 78 ✓. 390/6 = 65 ✓.
390/4 = 97.5, and the four-cell layout was rounded by hand — **so its third cell sits at 335 where the
rule puts it at 336, and its last cell ends at 531, one unit past the 530 every sibling layout ends at.**

Then `northern_plates.dart:295-490` declares the **same numbers again** as `PlateMirror`s, because a
northern plate prints its number twice — eastern numerals in the upper band, Latin in the lower. Four
mirror lists, 21 literals, roughly 150 lines, all of them a copy of the slot geometry with `top` and
`height` swapped for `_echoTop` / `_echoHeight` and the alphabet swapped for `YemenAlphabets.digits`.

### Two more drifts, same cause

| File:line | Register | Pitch sequence | Should be |
|---|---|---|---|
| `northern_plates.dart:240` | `_carGov2Serial4` | 98, **97**, 98 | 97.5 |
| `northern_plates.dart:526` | `_motoGov2Serial5` | 42, 42, **41**, 42 | 41.8 |
| `west_bank_plates.dart:399` | `modernMoto` serial | **31.5**, 32, 32 | one value |

None is catchable today. `debugValidateSpec` (`plate_spec.dart:261`) checks that boxes fit the canvas,
that mirrors point at real slots, and that alphabet ids key content one-to-one. It does not check that a
register is evenly spaced, and `yemen_plate` has no tests at all.

### What this does *not* explain

Be honest about the size question, because the answer is mostly reassuring. Measured in **code lines per
distinct plate geometry** (comments and blanks excluded):

| Package | code | declared specs | real geometries | code / geometry |
|---|---:|---:|---:|---:|
| `germany_plate` | 150 | 1 | 1 | **150** |
| `iran_plate` | 180 | 2 | 2 | **90** |
| `palestine_plate` | 904 | 13 | 13 | **70** |
| `yemen_plate` | 1,817 | 55 | **11** | **165** |

Per plate design, all four packages cost about the same. `yemen_plate` is large because Yemen genuinely
has eleven plate geometries where Germany has one — and because 44 of its 55 declared specs are usage
clones, which is **P4's** deletion, not this phase's. What is left over after P4 is the gap between
Palestine's 70 and Yemen's 165, and that gap is almost exactly the unrolled echo bands and stipple runs
above: Yemen is the only package with mirrors (30) and the only one with a stipple (46 rules).

So: P4 removes the fake specs, and **P3B removes the hand-unrolled loops**. Neither one is the other's job.

## The design

Three pure functions in core, returning lists. No widget, no state, no new type on `PlateSpec` — this is
geometry, which is already core's business, expressed as constructors rather than as literals.

```dart
/// [count] equal cells over [alphabet], the first at [left], each [width] wide
/// and [height] tall at [top], stepping by [pitch] (default: flush, [width]).
///
/// A plate is registers, not rectangles: `PlateTextGroup` already says which
/// slots form one, and this says where they sit. Writing a register cell by
/// cell is a for-loop unrolled by hand, and a hand-unrolled loop drifts — see
/// `_carGov2Serial4`, whose third cell was one unit out for exactly this reason.
List<PlateSlot> plateRegister({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
});

/// [count] cells filling [left, right) exactly — the same register expressed
/// by the span it must fill rather than by cell width.
///
/// Prefer this when the register is defined by its bounds, as Yemen's northern
/// serial is: four, five or six cells all filling x in [140, 530). It cannot
/// round wrong, which is the whole point.
List<PlateSlot> plateRegisterAcross({
  required PlateAlphabet alphabet,
  required int count,
  required double left,
  required double right,
  required double top,
  required double height,
});

/// One mirror per entry of [sources], laid out as a register — the echo band a
/// plate that prints its number twice needs.
List<PlateMirror> plateEcho({
  required Iterable<int> sources,
  required double left,
  required double top,
  required double width,
  required double height,
  double? pitch,
  double? glyphHeight,        // defaults to height
  PlateAlphabet? alphabet,
});

/// [count] identical rules at a constant pitch: a stippled separator.
List<PlateRule> plateStipple({
  required int count,
  required double left,
  required double top,
  required double width,
  required double height,
  double stepX = 0,
  double stepY = 0,
});
```

### The const question — read this before writing any code

`PlateSpec` is `const`, and the package doctrine is *"adding a plate means adding a const, never a
widget."* A Dart `const` constructor cannot run a loop, so a list produced by one of these functions is
`final`, not `const` — and a `const PlateSpec` cannot take a `final` list.

**The right resolution is to relax `const` to `final` on the affected spec constants, not to contort the
primitive.** Three reasons:

1. `PlateSpec` equality is over `id` alone (`plate_spec.dart:250`). Const canonicalization was never
   load-bearing for identity — `PlateCanvas.didUpdateWidget` compares `spec.id`, not `identical()`.
2. `static final` is initialised lazily, once, per isolate. There is no per-build or per-keystroke cost.
   (The alternative — making `PlateSpec.slots` a computed getter over a register list — *would* have
   one: `PlateController._sanitize` reads `spec.slotAt(index)` on every keystroke. Do not do that.)
3. The blast radius is six lines in the whole repo. Every const-context use of a spec constant:

   ```
   germany_plate/example/lib/main.dart:12          const spec = GermanPlates.car;
   iran_plate/example/lib/main.dart:12             const spec = IranPlates.car;
   core_plate/example/lib/main.dart:12             const spec = IranPlates.car;
   palestine_plate/test/palestine_validators_test.dart:85, :153, :212
   ```

   All six become `final spec = …`, which compiles unchanged. P10 rewrites three of them anyway.

Keep `const` wherever it still works — Germany's single spec, Iran's labels and rules, every
`PlateCountry`, `PlateAlphabet` and `PlateTheme`. Only the specs whose slot or mirror lists are now
generated become `final`. Say so in each package's CHANGELOG.

## Scope

**In:**
- `core_plate/lib/src/model/plate_layout.dart` — new, the four functions.
- `core_plate/lib/src/model/plate_spec.dart` — one new assertion in `debugValidateSpec`.
- `core_plate/lib/core_plate.dart` — export.
- `core_plate/test/plate_layout_test.dart` — new.
- `yemen_plate/lib/src/northern_plates.dart`, `unified_plates.dart`
- `palestine_plate/lib/src/west_bank_plates.dart`, `gaza_plates.dart`
- `iran_plate/lib/src/iran_plates.dart`
- `germany_plate/lib/src/germany_plates.dart`
- The six `const spec =` sites above.
- All five CHANGELOGs.

**Out — frozen:**
- **`PlateBox`, `PlateSlot`, `PlateMirror`, `PlateRule`, `PlateSpec`'s fields.** No new field on
  `PlateSpec`, no `registers:` parameter, no computed `slots` getter. The primitive is a set of functions
  that *build* the existing types. Anything that changes `PlateSpec`'s shape puts geometry on the hot
  path and is out of scope.
- **`PlateCanvas` and the whole widget layer.** They read `spec.slots` and `spec.mirrors` exactly as
  before and cannot tell the difference. If this phase touches a widget file, it has gone wrong.
- **Every irregular position.** Labels, decals, panels, the isolated first and last cells of a Palestinian
  plate, `_carGovSingle` (which straddles the pair's two cells), the `·` dot labels. A register primitive
  is for registers; forcing an irregular element through it is worse than a literal.
- **The three drifts stay corrected exactly as specified below and nowhere else.** Do not "tidy" any other
  coordinate. Every other number in every spec file is a `// CALIBRATE` value proportioned from a
  photograph.
- `plate_number_holder/`.

## Steps

### 1. Write the primitives and their tests first

`plate_layout.dart` is ~90 lines of pure Dart with no Flutter import beyond `PlateAlphabet`'s.
Test it before rewriting a single spec:

- `plateRegister(count: 5, left: 140, width: 78, …)` yields x = 140, 218, 296, 374, 452.
- `pitch` defaults to `width` (flush cells) and is honoured when given (gapped cells).
- `plateRegisterAcross(count: 6, left: 140, right: 530, …)` yields width 65 and x = 140…465;
  `count: 4` over the same span yields width **97.5** and x = 140, 237.5, 335, 432.5.
- `count: 0` returns an empty list; `count: 1` returns one cell at `left`. `count < 0` throws.
- `plateEcho(sources: [2,3,4,5], …)` yields four mirrors with `source` 2,3,4,5 in order, and
  `glyphHeight` defaulting to `height`.
- `plateStipple(count: 24, top: 1, stepY: 12, …)` yields y = 1, 13, … 277.
- Every function returns an unmodifiable or freshly-built list, never a shared one.

### 2. Extend `debugValidateSpec` — the guard that would have caught all three drifts

Add one assertion: **the slots of every keyed `PlateTextGroup` whose boxes share a `top` and `height` must
be evenly pitched.**

```dart
  // A register drifts silently: a hand-written run of cells is a for-loop
  // unrolled by hand, and one rounded coordinate is invisible until someone
  // measures the plate. Checked only for groups whose cells share a row, so a
  // two-line layout (which splits one register across two bands) is exempt.
  for (final g in spec.effectiveTextGroups) {
    if (g.key == null || g.indices.length < 3) continue;
    final boxes = [for (final i in g.indices) if (spec.slotAt(i) != null) spec.slots[i].box];
    if (boxes.length != g.indices.length) continue;
    final sameRow = boxes.every((b) => b.top == boxes.first.top && b.height == boxes.first.height);
    if (!sameRow) continue;
    final pitch = boxes[1].left - boxes[0].left;
    for (var n = 1; n < boxes.length; n++) {
      assert(
        (boxes[n].left - boxes[n - 1].left - pitch).abs() < 0.01,
        'Register "${g.key}" in spec "${spec.id}" is unevenly pitched: cell $n '
        'sits at ${boxes[n].left}, but a pitch of $pitch puts it at '
        '${boxes[0].left + n * pitch}. Build it with plateRegister/'
        'plateRegisterAcross rather than cell by cell.',
      );
    }
  }
```

**Run the suite now, before rewriting anything.** It must fail on exactly the three specs named above and
pass on everything else. If it flags a fourth, that is a fourth drift and belongs in the report. If it
flags a two-line layout, tighten the `sameRow` guard rather than weakening the assertion.

`debugValidateSpec` runs inside an `assert`, so this costs nothing in release.

### 3. Rewrite the regular runs, package by package, smallest first

Work in this order so a mistake surfaces on the cheapest package: **germany → iran → palestine → yemen.**

- **`germany_plates.dart`** — the four-digit serial at `:40` (x = 288, 338, 388, 438, width 46, pitch 50)
  becomes one `plateRegister` call. The two district letters stay literal: two cells is not a register
  worth naming. Germany's spec can stay `const` if only the district letters remain literal — check.
- **`iran_plates.dart`** — the car's three-digit group at `:41` and the bicycle's two rows at `:111`
  and `:123`. The car's first pair (65, 120) and its province pair (428, 466) are separate registers;
  declare each. Do **not** merge them: the pitch differs and the gap is where the divider sits.
- **`west_bank_plates.dart` / `gaza_plates.dart`** — each spec is one to three registers separated by the
  gaps the `·` labels occupy. `_modernCarSlots` (`:112`) is `region`(1) + gap + `serial`(4 @ pitch 59) +
  gap + `governorate`(1): write the middle four as a register and leave the two isolated cells literal.
  Same shape for `_legacyCarSlots` and Gaza's `_sevenCellSlots`. **`modernMoto` (`:399`) carries a drift**
  (31.5, 32, 32) — correct it, see step 4.
- **`unified_plates.dart`** — `_carStipple` and `_motoStipple` become two `plateStipple` calls. The three
  car slot registers (`:214`, `:225`, `:236`) fill x ∈ [292, 832): use `plateRegisterAcross`. The moto
  registers (`:311`, `:320`, `:330`) are gapped, not flush — use `plateRegister` with an explicit `pitch`.
- **`northern_plates.dart`** — the largest win. The three car serial registers become
  `plateRegisterAcross(left: 140, right: 530, …)`, which produces 97.5 / 78 / 65 and makes the drift
  impossible by construction. Then the four mirror lists become `plateEcho` calls over the same span at
  `_echoTop` / `_echoHeight` with `alphabet: YemenAlphabets.digits`. `_carEchoGovTens`,
  `_carEchoGovUnits` and `_carEchoGovSingle` stay literal — they are not a register.

### 4. Correct the three drifts, deliberately and visibly

This phase changes rendered pixels in exactly three places. Treat each as a listed correction, not a
side effect:

| Spec | Was | Becomes | Visible change |
|---|---|---|---|
| `YemenNorthernPlates.carGov2Serial4` (+ its mirrors) | cells at 140, 238, **335**, 433; right edge **531** | 140, 237.5, 335, 432.5; right edge 530 | third and fourth cells shift ≤1 unit on a 540-wide canvas |
| `YemenNorthernPlates.motoGov2Serial5` (+ mirrors) | pitch 42, 42, **41**, 42 | uniform 41.8 | fourth cell shifts ≤1 unit |
| `PSWestBankPlates.modernMoto` | pitch **31.5**, 32, 32 | uniform | one cell shifts 0.5 unit |

Record each in the package CHANGELOG under a `Fixed` heading, with the before and after coordinates.
A reader who measured a plate against the old geometry deserves to know it moved.

**`PSWestBankPlates.modernMoto` is not in the Palestine golden** (`wb_modern_car_green` renders
`modernCar`), so `flutter test` must still pass byte-identical. If the golden moves, something outside
these three specs changed — revert and find it.

### 5. Flip `const` to `final` only where required

After each rewrite, the analyzer tells you exactly which constants can no longer be `const`. Change those
and their six const-context call sites. Do not pre-emptively convert anything the analyzer does not
complain about.

## Verification

```bash
cd ~/StudioProjects/plate

# 1. The primitives, in isolation.
(cd core_plate && flutter test test/plate_layout_test.dart)

# 2. The guard fires on the three known drifts BEFORE the rewrite, and on
#    nothing after it.
(cd core_plate && flutter test && flutter analyze --no-fatal-infos)
for p in iran_plate germany_plate palestine_plate yemen_plate; do
  (cd "$p" && flutter analyze --no-fatal-infos && flutter test 2>/dev/null)
done

# 3. The pixel proof for everything except the three corrections.
(cd palestine_plate && flutter test)          # golden byte-identical
git status --porcelain palestine_plate/test/goldens/    # empty

# 4. No hand-unrolled run survives. Re-run the detector:
python3 - <<'PY'
import re, glob
box = re.compile(r'(PlateSlot|PlateMirror|PlateRule)\((?:[^()]|\([^()]*\))*?PlateBox\(([^)]*)\)', re.S)
for f in sorted(glob.glob('*/lib/**/*plates.dart', recursive=True)):
    src = open(f).read(); items = []
    for m in box.finditer(src):
        n = [x.strip() for x in m.group(2).split(',')]
        if any(not re.match(r'^-?[\d.]+$', v) for v in n): continue
        items.append((m.group(1), [float(v) for v in n]))
    run = []
    for it in items:
        if run and it[0] == run[-1][0] and it[1][1:] == run[-1][1][1:]:
            run.append(it)
        else:
            if len(run) >= 3: print(f'{f}: {len(run)} consecutive {run[0][0]} literals still unrolled')
            run = [it]
    if len(run) >= 3: print(f'{f}: {len(run)} consecutive {run[0][0]} literals still unrolled')
PY
#   -> no output

# 5. The widget layer never noticed.
git status --porcelain core_plate/lib/src/widgets/     # empty

# 6. Line count.
for p in iran_plate germany_plate palestine_plate yemen_plate; do
  echo -n "$p "; find $p/lib -name '*.dart' | xargs cat | wc -l
done
```

**Visual check.** Run whichever example still exists for Yemen and render `carGov2Serial4` beside
`carGov2Serial5`. Both serials must now end flush at the same right edge; before this phase the four-cell
layout ran one unit past. That single unit is the phase's whole thesis made visible.

**Success:**
- `plate_layout.dart` exists with four tested functions; the widget layer is untouched.
- `debugValidateSpec` rejects an unevenly-pitched keyed register, and every spec in every package passes it.
- The detector finds no run of three or more consecutive equal-size literals anywhere.
- The Palestine golden is byte-identical; the three drift corrections are itemised in CHANGELOGs.
- `yemen_plate/lib` drops ~230 lines, `palestine_plate/lib` ~50, `iran_plate/lib` ~40, `germany_plate/lib` ~18.

## Dependencies

P1 (the engine test suite). Independent of P2, P3, P6, P7, P8.

**Run it before P4 if you can.** P4 collapses 55 Yemen specs to 11; doing that over register-form
geometry is cleaner than doing it over 281 literals and then converting. If P4 has already run, P3B still
applies — there is simply less to convert, and the two mirror lists P4 deleted never needed converting.
Either order ends in the same place; neither is blocked by the other.

## Line estimate

`plate_layout.dart` +90 · `plate_spec.dart` +22 · `plate_layout_test.dart` +95 ·
`yemen_plate` −230 · `palestine_plate` −50 · `iran_plate` −40 · `germany_plate` −18 · CHANGELOGs +25.
**Net ≈ −315 of production code, −106 including the new tests.**

Line count is the smaller half of the return. The larger half is that three arithmetic drifts existed in
a repo with no way to detect them, and after this phase a fourth cannot be written.
