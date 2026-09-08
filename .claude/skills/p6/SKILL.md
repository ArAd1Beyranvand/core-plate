---
name: p6
description: "P6 — move the digit regex and the 'quiet until the last register is filled' control shape into core_plate, and rewrite the six country validators on top of them. Invoke with /p6 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Sonnet 5 · **reasoning:** medium · **extended thinking:** ON
> **Requires:** /p1
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P6 — Validation primitives in core

## Context (assume nothing else)

`core_plate/lib/src/validators/plate_validator.dart` (63 lines) defines three things:
`PlateValidation` (a verdict with a nullable `reason`, equal over that reason), `PlateEntry` (spec +
values + optional `activeIndex`, with `group(key)` and `activeGroup`), and the abstract
`PlateValidator` with one method, `validate(PlateEntry) → PlateValidation`.

The contract is firm and correct: *a validator never prevents input*. It answers a question; the host
decides what to do with the answer.

Six concrete validators exist across three packages, and every one repeats the same two things.

**1. The digit regex, four times:**

| File:line | Pattern |
|---|---|
| `palestine_plate/lib/src/palestine_validators.dart:6` | `RegExp(r'^[0-9]+$')` — file-level |
| `yemen_plate/lib/src/yemen_validators.dart:40` | `RegExp(r'^[0-9]+$')` — `YemenUnifiedValidator` |
| `yemen_plate/lib/src/yemen_validators.dart:129` | `RegExp(r'^[0-9]+$')` — `YemenNorthernValidator`, in the same file |
| `germany_plate/lib/src/german_plate_validator.dart:56` | `RegExp(r'^[0-9]{1,4}$')` — a length-bounded variant |

**2. One control shape, six times.** Every validator is:

```dart
  @override
  PlateValidation validate(PlateEntry entry) {
    final x = entry.group('<the last register>');
    if (x.isEmpty) return const PlateValidation.valid();
    return validateFields(a: entry.group('a'), b: entry.group('b'), ...);
  }
```

The six: `PSWestBankModernValidator` (gate `governorate`), `PSWestBankLegacyValidator` (`usage`),
`PSGazaValidator` (`usage`), `YemenUnifiedValidator` (`sideCode`), `YemenNorthernValidator` (`serial`),
`GermanPlateValidator` (`letters`). Each documents the same rationale in its own words: with nothing
barring input, the red state is the only feedback, and a plate that flashes red on its first character is
worse than no validation.

And every `validateFields` opens with variations on *"this group must be exactly N digits"* — eight
occurrences across the six.

## Scope

**In:**
- `core_plate/lib/src/validators/plate_validator.dart` — add primitives.
- `core_plate/test/plate_validator_test.dart` — new.
- `palestine_plate/lib/src/palestine_validators.dart`
- `yemen_plate/lib/src/yemen_validators.dart`
- `germany_plate/lib/src/german_plate_validator.dart`
- `core_plate/CHANGELOG.md`, `core_plate/lib/core_plate.dart` (doc line).

**Out — frozen:**
- **Every reason string.** `PSWestBankModernValidator.invalidRegion`, `.illegalLetterIO`,
  `.reservedGazaLetter`, `.invalidGovernorate`, `YemenNorthernValidator.reasonSerialLeadingZero` and the
  rest are `static const` and are asserted by name in `palestine_plate/test/palestine_validators_test.dart`.
  Not one character changes. `PlateValidation`'s equality is over the reason, so a reworded string is a
  behaviour change.
- **Every `validateFields` static.** They are public API, called directly by
  `PSSerialGenerator`'s tests and documented as "the country rule without a spec". Keep the names, the
  parameter names and the signatures.
- **The order of checks inside each `validateFields`.** Which failure a plate reports when it violates
  two rules at once is observable and is covered by the Palestine tests. Substituting a primitive must
  not reorder anything.
- **All country-specific logic:** the `I`/`O` and `P`–`T` letter rules, the 1..22 governorate range, the
  leading-zero rule, `PSLegacyUsage.forCode`, `PSGazaUsage.forCode`, the German forbidden pairs and the
  8-character cap. This phase removes plumbing, not rules.
- `PlateValidation` and `PlateEntry`'s existing members.
- `PlateCanvas`'s `autoValidate` path and `_ValidationBinding`.

## Steps

### 1. Add the primitives to `plate_validator.dart`

Two additions, both small.

```dart
/// Whether every character of [value] is an ASCII digit, and [value] is not
/// empty.
///
/// The one place the `^[0-9]+$` test lives. It was declared four times across
/// three country packages, twice in the same file. Not a method on
/// [PlateEntry], because a validator also asks it of values that never came
/// from a slot — a database row, a scan result.
bool isDigits(String value) =>
    value.isNotEmpty && value.codeUnits.every((u) => u >= 0x30 && u <= 0x39);

/// [isDigits] and exactly [length] characters long.
bool isDigitsOfLength(String value, int length) =>
    value.length == length && isDigits(value);
```

Prefer the code-unit walk over a `RegExp`: it is allocation-free, it is what
`PSLegacyUsage.forCode:71` already does by hand to guard the `'+9'` / `' 9'` cases `int.tryParse`
accepts, and it removes four `RegExp` objects from three packages.

Then the control shape, as an abstract base:

```dart
/// A [PlateValidator] that stays quiet until one named register has something
/// in it.
///
/// Every validator in this workspace has this shape, and for one reason: a
/// validator never bars a keystroke, so the invalid state is the only feedback
/// there is, and a plate that flashes red at its first character is worse than
/// no validation. The register named by [gateGroup] is the last one the user
/// reaches, so by the time it is non-empty there is a whole plate to judge.
///
/// Subclasses implement [judge] and never see the empty-plate case.
abstract class GatedPlateValidator extends PlateValidator {
  const GatedPlateValidator();

  /// The [PlateTextGroup.key] whose emptiness keeps this validator quiet.
  String get gateGroup;

  /// The verdict on a plate whose [gateGroup] is non-empty.
  PlateValidation judge(PlateEntry entry);

  @override
  PlateValidation validate(PlateEntry entry) =>
      entry.group(gateGroup).isEmpty ? const PlateValidation.valid() : judge(entry);
}
```

`PlateValidator` stays abstract and unchanged — a host with a validator that is not gated must keep
working.

### 2. Rewrite the six validators

Each becomes, e.g.:

```dart
class YemenNorthernValidator extends GatedPlateValidator {
  const YemenNorthernValidator();

  @override
  String get gateGroup => 'serial';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
        governorate: entry.group('governorate'),
        serial: entry.group('serial'),
      );

  // ... every reason string, every constant and validateFields unchanged,
  //     with `_digits.hasMatch(x)` replaced by `isDigits(x)`
}
```

Substitutions, one for one:

- `palestine_validators.dart`: delete the file-level `_digits`; `!_digits.hasMatch(serial)` combined with
  `serial.length != 4` becomes `!isDigitsOfLength(serial, 4)`. **Check the order** — the existing code
  tests length first, then the pattern; both produce the same reason, so collapsing them is safe, but
  verify against `palestine_validators_test.dart` before committing.
- `yemen_validators.dart`: delete **both** `_digits` statics.
  `YemenUnifiedValidator.validateFields` tests `number.isNotEmpty && !_digits.hasMatch(number)` before
  the length check — preserve that order exactly, because an empty number reports
  `reasonNumberLength`, not `reasonNumberNotNumeric`, and the two are distinguishable.
- `german_plate_validator.dart`: `_identifierDigitPattern` is `^[0-9]{1,4}$`, a bounded variant. Replace
  with `digits.isEmpty || (isDigits(digits) && digits.length <= 4)` and keep
  `_districtPattern` and `_identifierLetterPattern` as `RegExp`s — those match letters including `ÄÖÜ`
  and are not digit tests.

### 3. Test

Add `core_plate/test/plate_validator_test.dart`:

- `isDigits`: true for `'0'`, `'0123456789'`; false for `''`, `'1a'`, `'+9'`, `' 9'`, `'١٢٣'`
  (eastern Arabic numerals are **not** ASCII digits — this is the case a naive `int.tryParse` gets wrong
  and it matters, because `yemen_plate` stores ASCII and renders eastern glyphs).
- `isDigitsOfLength`: exact-length behaviour at the boundaries.
- `GatedPlateValidator`: with a stub subclass, `judge` is not called when the gate group is empty; it is
  called when non-empty; a gate key no group carries means `entry.group(...)` returns `''` and the
  validator stays permanently quiet — assert that explicitly, since it is the silent-failure mode of the
  whole design.
- `PlateValidation` equality over `reason` (pins what `PlateController.reportValidation` depends on).

## Verification

```bash
cd ~/StudioProjects/plate

(cd core_plate && flutter test && flutter analyze --no-fatal-infos)

# The real proof: Palestine's validator tests assert exact reason strings and
# exact failure precedence, and they were written before this phase existed.
(cd palestine_plate && flutter test)

for p in yemen_plate germany_plate; do (cd "$p" && flutter analyze --no-fatal-infos); done
(cd yemen_plate && flutter test)          # the P4 suite, incl. generator round-trips

# No RegExp left in a validator.
grep -rn "RegExp" --include='*validator*.dart' */lib/
#   -> only germany's _districtPattern and _identifierLetterPattern

# No reason string moved.
git diff -- '*validators*.dart' '*validator*.dart' | grep -E "^[-+].*static const String"
#   -> no output
```

**Success:** all four Palestine test files pass unchanged; no reason string differs; the only `RegExp`s
left in validator code are Germany's two letter patterns; the six validators lose their gate boilerplate.

## Dependencies

P1. Independent of P2, P3, P4, P5, P7, P8 — can run in any order among them.

## Line estimate

`plate_validator.dart` +42 · new test +80 · `palestine_validators.dart` −22 ·
`yemen_validators.dart` −24 · `german_plate_validator.dart` −8.
**Net ≈ −60 of production code, +68 including the test.**
