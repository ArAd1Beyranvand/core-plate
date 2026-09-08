---
name: p7
description: "P7 — promote yemen_plate's private _indicesOf helper to PlateSpec.indicesOfGroup, and rewrite palestine_plate's positional serial generator to be spec-driven like Yemen's. Invoke with /p7 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** low · **extended thinking:** ON
> **Requires:** /p1
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P7 — `PlateSpec.indicesOfGroup` and spec-driven generators

## Context (assume nothing else)

`core_plate`'s `PlateSpec` (`lib/src/model/plate_spec.dart`) exposes several ways to read a plate's
text groups: `effectiveTextGroups`, `groupAt(index)`, `renderGroup(group, values)`,
`valueOfGroup(key, values)`. All of them answer questions about *values*. **None returns the slot
indices a named group covers**, which is what anything that *writes* a group needs.

Two country packages generate synthetic plate values, and they solve it in opposite ways.

**`yemen_plate/lib/src/yemen_serial_generator.dart:130-139`** implements the missing capability as a
private file-level function:

```dart
List<int> _indicesOf(PlateSpec spec, String key) {
  for (final PlateTextGroup group in spec.textGroups) {
    if (group.key == key) return group.indices;
  }
  throw ArgumentError.value(spec.id, 'spec', 'has no text group named "$key"');
}
```

Both `YemenUnifiedSerialGenerator.generate` and `YemenNorthernSerialGenerator.generate` build a
`List<String?>` of `spec.slots.length` and fill it at the indices this returns. Handed a spec from
another package, they work. Handed the wrong spec, they throw with a useful message. **This is the
correct idiom** — with one bug: it reads `spec.textGroups` (the raw field) rather than
`effectiveTextGroups`. For a spec with no explicit groups the fallback groups carry no keys, so both
behave the same today, but the two accessors should not diverge.

**`palestine_plate/lib/src/palestine_serial_generator.dart:25-53`** never looks at the spec at all:

```dart
  /// A modern West Bank plate: `[region, s1, s2, s3, s4, governorateLetter]`.
  static List<String?> modernWestBank(Random rng) {
    final letters = PSGovernorate.letters;
    return [_digit(rng), ..._digits(rng, 4), letters[rng.nextInt(letters.length)]];
  }
```

It emits a fixed-length positional list and trusts the caller to pair it with a matching spec. It is
correct **only by coincidence**: all nine West Bank specs share one of two group tables
(`_modernGroups` = `region[0] · serial[1-4] · governorate[5]`, `_legacyGroups` =
`district[0] · serial[1-4] * usage[5,6]`), and all four Gaza specs share a third. Add one spec whose
serial sits elsewhere — a two-line layout that reads bottom row first, say — and the generator silently
produces a wrong plate with no error. Its own doc promises *"the same legal set the matching validator's
`validateFields` accepts"*, and `test/palestine_serial_generator_test.dart` round-trips 10,000 values per
scheme through the validators, which is exactly what would keep passing while the values landed in the
wrong slots.

## Scope

**In:**
- `core_plate/lib/src/model/plate_spec.dart` — one method.
- `core_plate/test/plate_spec_test.dart` — extend (P1 created it).
- `yemen_plate/lib/src/yemen_serial_generator.dart` — delete `_indicesOf`, call the core method.
- `palestine_plate/lib/src/palestine_serial_generator.dart` — rewrite to be spec-driven.
- `palestine_plate/test/palestine_serial_generator_test.dart` — update call sites, add a positional assertion.
- `core_plate/CHANGELOG.md`, `palestine_plate/CHANGELOG.md`.

**Out — frozen:**
- **The legal value sets.** `PSGovernorate.letters` (13 letters, no `I`/`O`), `PSLegacyUsage.codes`
  (23 codes), `PSGazaUsage.codes`, the Gaza `'3'` prefix, `YemenGovernorate.minCode`/`maxCode`, the
  northern no-leading-zero rule, the two-cell zero-padding rule. This phase changes *where* a value is
  written, never *which* values are drawn.
- **Seeded reproducibility.** A given `Random(seed)` must produce the same sequence of *draws* as before.
  Change the order of `rng.nextInt` calls and every seeded fixture and golden in the repo shifts. Draw in
  the same order the current code draws.
- `PSSerialGenerator.toFilename` — used by its own test.
- `PlateSpec`'s existing members, `PlateTextGroup`, and equality over `id`.
- All validators (P6's business).

## Steps

### 1. Add the method to `PlateSpec`

Beside `valueOfGroup`:

```dart
  /// The slot indices of the text group named [key], or an empty list when no
  /// group carries that key.
  ///
  /// The counterpart to [valueOfGroup]: that reads a register's characters,
  /// this names the positions they live in — what anything that *writes* a
  /// register needs. Walks [effectiveTextGroups], so a spec that declares no
  /// groups answers consistently with every other accessor here (its fallback
  /// groups carry no keys, so the answer is empty).
  ///
  /// Returns empty rather than throwing: a caller that wants the strict
  /// behaviour tests for it and says so in its own terms.
  List<int> indicesOfGroup(String key) {
    for (final g in effectiveTextGroups) {
      if (g.key == key) return g.indices;
    }
    return const <int>[];
  }
```

Empty-not-throwing matches `valueOfGroup`, which returns `''`. Yemen's generators keep their
`ArgumentError` by checking the result — a generator handed the wrong spec genuinely has nothing to
return, and that is the generator's rule, not the model's.

### 2. Rewrite `PSSerialGenerator`

Change all three methods to take a spec, matching Yemen's signature shape:

```dart
  /// A value for [spec], a modern West Bank plate.
  ///
  /// Positions come from the spec's own `region` / `serial` / `governorate`
  /// text groups, so a new layout with the same registers in different slots
  /// generates correctly without touching this file.
  ///
  /// Throws [ArgumentError] if [spec] carries no such groups.
  static List<String?> modernWestBank(PlateSpec spec, {Random? random}) {
    final rng = random ?? Random();
    final values = List<String?>.filled(spec.slots.length, null);
    final region = _require(spec, 'region');
    final serial = _require(spec, 'serial');
    final governorate = _require(spec, 'governorate');

    for (final i in region) { values[i] = _digit(rng); }
    for (final i in serial) { values[i] = _digit(rng); }
    final letters = PSGovernorate.letters;
    for (final i in governorate) { values[i] = letters[rng.nextInt(letters.length)]; }
    return values;
  }

  static List<int> _require(PlateSpec spec, String key) {
    final indices = spec.indicesOfGroup(key);
    if (indices.isEmpty) {
      throw ArgumentError.value(spec.id, 'spec', 'has no text group named "$key"');
    }
    return indices;
  }
```

**Preserve the draw order exactly**: region digit first, then four serial digits, then the letter — which
is what the current `[_digit(rng), ..._digits(rng, 4), letters[rng.nextInt(...)]]` does left to right.
Same for `legacyWestBank` (district, four serial digits, then a usage code split into two characters) and
`gaza` (the literal `'3'` — no draw — then four serial digits, then a usage code).

Note the one real behaviour change to document: `legacyWestBank` and `gaza` currently `.split('')` a
two-character usage code into two entries; now they write those two characters into the two indices of the
`usage` group. Identical for every existing spec; correct for a hypothetical one where those cells are
not adjacent.

### 3. Simplify Yemen's generators

Delete `_indicesOf` (`:130-139`). Replace both call sites with a local `_require`-style helper over
`spec.indicesOfGroup(key)`, keeping the `ArgumentError` message verbatim so the failure text does not
change. Net effect: Yemen's generators shrink slightly and stop reading `spec.textGroups` directly.

### 4. Update `palestine_serial_generator_test.dart`

Call sites gain a spec argument. Then add the assertion that would have caught the latent bug:

```dart
test('writes each register into the slots its spec names', () {
  final spec = PSWestBankPlates.modernCar;
  final values = PSSerialGenerator.modernWestBank(spec, random: Random(1));
  expect(values.length, spec.slots.length);
  expect(values.every((v) => v != null), isTrue);
  // The governorate letter lands in the governorate group, not at a fixed index.
  for (final i in spec.indicesOfGroup('governorate')) {
    expect(PSGovernorate.letters, contains(values[i]));
  }
  for (final i in spec.indicesOfGroup('serial')) {
    expect(values[i], matches(RegExp(r'^[0-9]$')));
  }
});
```

Keep the existing 10,000-draw round-trips through the validators exactly as they are.

## Verification

```bash
cd ~/StudioProjects/plate

(cd core_plate && flutter test && flutter analyze --no-fatal-infos)
(cd palestine_plate && flutter test)      # 10k round-trips per scheme still pass
(cd yemen_plate && flutter test)          # P4's generator round-trips still pass

# Seeded reproducibility — the values must be identical to before the phase.
# Capture before rewriting, compare after:
#   dart run bin/dump.dart > /tmp/seed-before.txt   (a scratch script; delete it after)
diff /tmp/seed-before.txt /tmp/seed-after.txt       # must be empty

grep -rn "_indicesOf" yemen_plate/lib/               # no output
grep -rn "spec.textGroups" --include=*.dart */lib/   # only plate_spec.dart itself

for p in palestine_plate yemen_plate; do (cd "$p" && flutter analyze --no-fatal-infos); done
```

**Success:** `indicesOfGroup` exists on `PlateSpec` and is used by both generators; no private index
lookup remains in any country package; seeded output is byte-identical to before; all Palestine and
Yemen tests pass; both generators now throw a clear `ArgumentError` when handed the wrong spec.

## Dependencies

P1. Independent of P2, P3, P6, P8. If run after P4, the Yemen generator round-trips already cover the
collapsed spec set — either order is fine.

## Line estimate

`plate_spec.dart` +18 · `plate_spec_test.dart` +25 · `palestine_serial_generator.dart` +22 ·
`yemen_serial_generator.dart` −6 · Palestine test +22. **Net ≈ +10 of production code.**
