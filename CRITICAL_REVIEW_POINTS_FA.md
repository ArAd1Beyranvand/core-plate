# نقاط حیاتی برای بررسی

یک راهنمای عمیق برای بررسی نقاط خطرناک و architecture-critical

---

## 1. Migration Logic: The Most Dangerous Code

### Location
`core_plate/lib/src/input/plate_controller.dart`, lines 270-308

### The Problem
هنگام تغییر spec (مثلا user switch می‌کند از taxi plate به private plate):
- جدید spec شاید slot count متفاوت داشته باشد
- قدیم spec values رو باید somehow preserve کنی
- **اگر wrong کنی، users character data رو lose می‌کنند**

### Current Implementation

```dart
void _migrate(List<String> newValues, PlateValuePreservation preservation) {
  // Three strategies:
  // 1. byIndex: slot[0] → slot[0], slot[1] → slot[1], etc.
  // 2. byGroupKey: group['serial'] → group['serial']
  // 3. none: discard everything

  if (preservation == PlateValuePreservation.none) {
    _values = newValues;
    return;
  }

  if (preservation == PlateValuePreservation.byIndex) {
    for (int i = 0; i < newValues.length; i++) {
      if (i < _values.length) {
        newValues[i] = _values[i];
      }
    }
    _values = newValues;
    return;
  }

  // byGroupKey is complex: skip empty slots when migrating
  if (preservation == PlateValuePreservation.byGroupKey) {
    final newGroups = _groupValues(newValues, _spec);
    final oldGroups = _groupValues(_values, _spec);

    for (final key in oldGroups.keys) {
      if (!newGroups.containsKey(key)) continue;
      
      final oldSlots = oldGroups[key]!;
      final newSlots = newGroups[key]!;
      
      // Skip empty values from old slots
      int oldI = 0;
      for (int newI = 0; newI < newSlots.length && oldI < oldSlots.length; newI++) {
        while (oldI < oldSlots.length && 
               (oldI >= _values.length || (_values[oldI] ?? '').isEmpty)) {
          oldI++;
        }
        if (oldI < oldSlots.length) {
          newValues[newSlots[newI]] = _values[oldSlots[oldI]];
          oldI++;
        }
      }
    }
    _values = newValues;
  }
}
```

### What to Check

#### ✅ Check 1: byIndex Logic
```dart
if (i < newValues.length) {
  newValues[i] = _values[i];
}
```

**Question:** اگر old spec 5 slots داشت و new spec 4 slot دارد، slot 4 رو drop می‌کنی؟
- **Answer:** Yes, because `newValues` length کوچک‌تر است
- **Is this correct?** نه — اگر user newSpec رو adopt کند، فقط 4 slot نیاز دارند

**Question:** اگر new spec بیشتر slot‌ها داشت، آن‌ها empty می‌مانند؟
- **Answer:** Yes, `newValues` الا از constructor پر شده از empty strings
- **Is this correct?** Yes, user باید new slots رو fill کند

**Verdict:** ✅ byIndex logic صحیح است

---

#### ✅ Check 2: byGroupKey Logic — THE TRICKY PART

```dart
int oldI = 0;
for (int newI = 0; newI < newSlots.length && oldI < oldSlots.length; newI++) {
  while (oldI < oldSlots.length && 
         (oldI >= _values.length || (_values[oldI] ?? '').isEmpty)) {
    oldI++;
  }
  if (oldI < oldSlots.length) {
    newValues[newSlots[newI]] = _values[oldSlots[oldI]];
    oldI++;
  }
}
```

**What this does:**
1. برای هر new slot در group
2. Skip any old slots که خالی هستند
3. Copy first non-empty old value

**Example:**
```
Old serial group: [empty, 'A', 'B', empty]
New serial group: [slot 5, slot 6, slot 7]

Result:
  newSlot[5] ← 'A' (first non-empty)
  newSlot[6] ← 'B' (second non-empty)
  newSlot[7] ← empty (no more old values)
```

**Edge Cases:**

**Edge Case 1:** New group larger than old
```
Old: [empty, 'A', 'B']
New: [slot 5, slot 6, slot 7, slot 8]

Result:
  [5] ← 'A'
  [6] ← 'B'
  [7] ← empty
  [8] ← empty
```
✅ Correct — user fills remaining

**Edge Case 2:** Old group larger than new (truncation)
```
Old: [empty, 'A', 'B', 'C', 'D']
New: [slot 5, slot 6]

Result:
  [5] ← 'A'
  [6] ← 'B'
  // 'C', 'D' lost
```
⚠️ **Question:** Is data loss acceptable?
- Yes, if specs are intentionally designed so user adopts with awareness
- No, if specs seem like variants of same plate

**Action:** For iran_plate, check if any spec pairs lose data on adoption:
```dart
// Example test:
final longSerial = IranPlates.taxi.groupAt('serial')!.indices.length;  // 3
final shortSerial = /* hypothetical shorter spec */.groupAt('serial')!.indices.length;
// If short < long, adoption byGroupKey loses characters
```

**Verdict:** ⚠️ Logic is correct, but **domain-dependent**. Check that no unintended truncation happens.

---

### Action Items

- [ ] Test each adoption mode (`byIndex`, `byGroupKey`, `none`) with both smaller and larger specs
- [ ] Verify no data is lost when adopting within same country (e.g., car → taxi)
- [ ] Verify truncation is intentional when adopting across countries (e.g., Iran → motorcycle spec)

---

## 2. Compositing Strategy: The Subtle Rendering Issue

### Location
`core_plate/lib/src/widgets/plate_canvas.dart`, lines 311-336 (THE BIG COMMENT BLOCK)

### The Problem

Plate rendering must satisfy **three conflicting demands:**

1. **Frame & furniture must rasterize** (for sharpness on low-DPI screens)
   - Border, dividers, corner radius
   - Should be painted once, cached, reused

2. **Glyphs must render vectorially** (at device resolution)
   - Text must be anti-aliased
   - Text must not blur when rotated/scaled
   - Text must be crisp at any DPI

3. **TextField overlays must be interactive** (for focus, cursor, selection)
   - User must type and edit
   - Focus ring must appear
   - Glyphs must update live

### The Naive Approach (Broken)

```dart
// WRONG: Single layer
Stack(
  children: [
    // Frame painted once
    CustomPaint(painter: PlatePainter()),
    // TextFields painted on top
    TextField(), TextField(), TextField(),
  ],
)
```

**Problem:**
- TextField compositing creates a raster layer
- Everything inside TextField (including glyphs) rasterizes
- Glyphs become bitmap, lose sharpness
- Result: blurry text on high-DPI displays

### The Solution: Two-Layer Compositing

```dart
// RIGHT: Frame in its own FittedBox
Stack(
  children: [
    FittedBox(
      fit: BoxFit.none, // don't scale
      child: CustomPaint(painter: PlatePainter()),
    ),
    FittedBox(
      fit: BoxFit.none,
      child: Stack(
        fit: StackFit.passthrough, // don't constrain size
        children: [
          TextField(), TextField(), TextField(),
        ],
      ),
    ),
  ],
)
```

**Why this works:**
1. Frame paints → rasterized once → cached
2. TextFields paint in separate layer → glyphs vectorial
3. `StackFit.passthrough` means text layer doesn't force size, so frame size is preserved
4. Overlap parameter (`_overlap`) makes sure text layer slightly overlaps frame, hiding seams

### The Seam Problem

```
Frame layer:          Text layer:           Result (with _overlap):
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│                 │   │  ╔═══════════╗  │   │╔═══════════════╗│
│   ┌─────────┐   │   │  ║  A  B  C  ║  │   ║  A  B  C  ║
│   │ Frame   │   │ + │  ╚═══════════╝  │ = ║           ║
│   └─────────┘   │   │                 │   ║           ║
│                 │   │                 │   ║           ║
└─────────────────┘   └─────────────────┘   ╚═════════════╝
                                             ^ text layer slightly
                                               overlaps, hiding seam
```

### The Code (Real Implementation)

```dart
// Line 340-360: Render frame
final frameSize = _plateSize(spec);
CustomPaint(
  painter: PlatePainter(spec: spec, theme: theme),
  size: frameSize,
);

// Line 370-390: Render text layer
Stack(
  fit: StackFit.passthrough, // ← KEY: don't constrain
  children: [
    ...slots.map((slot) => Positioned(
      left: slot.box.left + _overlap, // ← overlap hides seam
      top: slot.box.top + _overlap,
      width: slot.box.width - 2 * _overlap,
      height: slot.box.height - 2 * _overlap,
      child: TextField(...),
    )),
  ],
);
```

### What to Check

#### ✅ Check 1: Does `StackFit.passthrough` preserve outer constraints?

**Test:**
```dart
// PlateCanvas should not shrink if frame is large
final canvas = PlateCanvas(
  spec: IranPlates.car,  // 520×110 pixels
);
// Rendered size should be exactly 520×110, not smaller
```

**Verdict:** ✅ If rendering matches spec size, passing.

---

#### ✅ Check 2: Does overlap hide seams visually?

**Test:**
- Render on real device
- Look at edges between frame and text layer
- Are there visible seams?

**Expected:**
- No seams visible
- Text layer slightly overlaps frame (controlled by `_overlap` constant)

**Verdict:** ⚠️ Visual — only testable on device

---

#### ✅ Check 3: Are glyphs sharp?

**Test:**
- Render plate on high-DPI screen (iPad, modern phone)
- Glyphs should be crisp, not blurry

**If blurry:**
- Problem: Text layer is rasterizing
- Check: Is TextField creating unwanted raster layer?
- Solution: Wrap TextField in `RepaintBoundary`?

**Verdict:** ⚠️ Device-dependent

---

### Action Items

- [ ] Render on device at different zoom levels (50%, 100%, 200%)
- [ ] Check for seams between frame and text layers
- [ ] Compare glyph sharpness to reference (screenshot or PDF)
- [ ] Test frame caching (fast re-renders without changes?)

---

## 3. Storage vs Display Split: The Encoding Issue

### Location
`core_plate/lib/src/model/plate_alphabet.dart` (line 47-56)  
`iran_plate/lib/src/iran_usage.dart` (line 86-99)

### The Problem

Iranian keyboards send different characters than what gets stored in databases:

**Example: Disabled Vehicles**
```
User types:  ژ (Persian letter Zhe)
Database:    ژ
Display:     ♿︎ (wheelchair symbol)
```

**Why:**
- Keyboard produces ژ (the letter)
- Database stores ژ (same letter)
- Display renders ♿︎ (symbolic representation for accessibility)

### Current Implementation

```dart
// plate_alphabet.dart
class PlateAlphabet {
  // Storage form: what goes in database
  final List<String> characters;
  
  // Display form: what user sees (optional)
  final Map<String, String> glyphs;
  
  // Validation reads storage, rendering reads display
  bool isValid(String character) => characters.contains(character);
  String render(String character) => glyphs[character] ?? character;
}

// persian_alphabets.dart — Disabled symbol alphabet
static const PlateAlphabet disabledSymbol = PlateAlphabet(
  id: 'fa.disabledSymbol',
  characters: ['ژ'],           // ← Storage form
  glyphs: {'ژ': '♿︎'},        // ← Display form
  ...
);

// iran_usage.dart
static final IranUsage.disabled = IranUsage._(
  seriesLetter: 'ژ',    // ← Storage form (same as alphabet)
  ...
);
```

### What to Check

#### ✅ Check 1: Alphabet storage and display match

**Rule:** For every alphabet with glyphs:
- `characters` must contain exactly the storage forms
- `glyphs` must map `characters` → display forms
- No glyphs for forms outside `characters`

**Test:**
```dart
// For disabledSymbol alphabet:
assert(disabledSymbol.characters.contains('ژ'));  // ✅ Storage in alphabet
assert(disabledSymbol.glyphs.containsKey('ژ'));   // ✅ Display mapped
assert(disabledSymbol.glyphs['ژ'] == '♿︎');      // ✅ Correct symbol

// No orphaned glyphs:
for (final char in disabledSymbol.glyphs.keys) {
  assert(disabledSymbol.characters.contains(char));  // ✅ Each glyph has source
}
```

---

#### ✅ Check 2: IranUsage.seriesLetter matches alphabet

**Rule:** If IranUsage references an alphabet, the usage's `seriesLetter` must be in that alphabet's storage forms.

**Test:**
```dart
// Disabled usage
assert(IranUsage.disabled.seriesLetter == 'ژ');     // ✅ Storage form
assert(PersianAlphabets.disabledSymbol.characters.contains('ژ'));  // ✅ In alphabet

// Taxi usage
assert(IranUsage.taxi.seriesLetter == 'ت');        // ✅ Storage form
assert(PersianAlphabets.taxiLetter.characters.contains('ت'));    // ✅ In alphabet
```

---

#### ✅ Check 3: Validation reads storage, not display

**Rule:** PlateValidator must check storage forms, never display forms.

**Test:**
```dart
// When user enters ♿︎ (display form):
// 1. Input source must convert to 'ژ' (storage)
// 2. Validator checks 'ژ' against alphabet.characters
// 3. If missing, reject (because storage form invalid)

// WRONG: Validation checking display
if (glyphs.containsValue(userInput)) { /* wrong */ }

// RIGHT: Validation checking storage
if (characters.contains(userInput)) { /* correct */ }
```

**Action:** Scan all validators — they should read `entry.values` (storage), not `entry.glyphs` (display).

---

#### ✅ Check 4: Rendering reads display

**Rule:** PlateCanvas rendering must show display forms where glyphs are defined.

**Test:**
```dart
// When rendering disabled plate:
final slotAlphabet = spec.slotAt(2).alphabet;  // disabledSymbol
final value = controller.valueAt(2);            // 'ژ' (storage)
final display = slotAlphabet.glyphs[value] ?? value;  // '♿︎'
// Rendered text should show: ♿︎

// NOT: Rendered text should show 'ژ'
```

---

### Edge Cases

#### Edge Case 1: Multi-character Glyphs

What if a storage character has multi-character display form?
```dart
glyphs: {'ژ': '♿︎️‍🦽'}  // Multi-codepoint symbol
```

**Check:** Does rendering handle multi-codepoint strings?
- Measure glyph width correctly?
- Don't truncate?

---

#### Edge Case 2: RTL Display Forms

What if display form includes RTL marks?
```dart
glyphs: {'ع': '؛ع'}  // Prefix semicolon
```

**Check:** Does RTL text direction handle correctly?
- Does prefix appear on *left* (RTL reading)?
- Not on right?

---

### Action Items

- [ ] Verify every IranUsage.seriesLetter is in corresponding alphabet.characters
- [ ] Verify every alphabet.glyphs[key] has key in alphabet.characters
- [ ] Test disabled plate: verify ♿︎ renders, not ژ
- [ ] Test that validation rejects invalid characters (storage forms)

---

## 4. Text Group Validation: The Gate Pattern

### Location
`core_plate/lib/src/validators/plate_validator.dart` (line 62-74)

### The Problem

When user is entering a plate, we want:
- **During entry:** Validator stays quiet until the last "critical" register fills
  - Don't red-flag partial input
  - User should feel free to delete and re-enter
- **After entry:** Validator becomes strict
  - Every group must be valid
  - No half-entered values

### Current Implementation

```dart
abstract class GatedPlateValidator extends PlateValidator {
  String get gateGroup;  // e.g., 'serial'
  
  PlateValidation judge(PlateEntry entry);  // The real validator
  
  @override
  PlateValidation validate(PlateEntry entry) {
    // Quiet until gate is full
    final gate = entry.group(gateGroup);
    if (gate.isEmpty) {
      return PlateValidation.valid;  // ← Quiet!
    }
    // Gate is full, so judge strictly
    return judge(entry);
  }
}
```

### What to Check

#### ✅ Check 1: gateGroup is always the last register

**Rule:** For every GatedPlateValidator subclass, `gateGroup` should reference the last register that user fills.

**Test:**
```dart
// For Iran taxi validator
// Serial should be last register (after district, letter, serial)
gateGroup == 'serial'  // ✅ Correct

// NOT:
gateGroup == 'letter'  // ❌ Wrong (gates too early)
gateGroup == 'district'  // ❌ Wrong (gates too early)
```

---

#### ✅ Check 2: Gate condition is correct

**Current condition:** `gate.isEmpty`

**Question:** Is this always correct?
- If gate has 3 slots, all must be non-empty?
- Or is one character enough?

**Answer:** Depends on spec.
- If `textGroups[gateGroup].indices.length == 3`, then gate is 3 slots
- `isEmpty` means at least one slot is empty
- `!isEmpty` means all slots are non-empty ✅

---

#### ✅ Check 3: No validator gates on same group

**Rule:** Only one validator should gate on 'serial' (or any group).

**Test:**
```dart
// Scan all validators
// Find all that have gateGroup
// Ensure no two validators gate on same group
```

**If violation:** One validator would gate, other would not — unpredictable behavior.

---

### Edge Cases

#### Edge Case 1: Gate Group with Variable Length

What if gate group has variable slots?
```dart
// Motorcycle spec: province (3) + serial (5)
// Both groups required, but province is variable length?
```

**Check:** Can gates handle variable-length groups?
- If so, is `isEmpty` still correct?
- Should gate be: "at least N characters filled"?

---

#### Edge Case 2: User Backspaces Last Character in Gate

```
User types: S-E-R [backspace]
Gate was full (not empty), now empty
Validator should: Become quiet again
```

**Expected behavior:** ✅ Yes, `isEmpty` catches this

---

### Action Items

- [ ] Identify all GatedPlateValidator subclasses
- [ ] For each, verify gateGroup is the last register user fills
- [ ] Test: user enters partial, validator is quiet ✅
- [ ] Test: user completes gate, validator judges strictly ✅
- [ ] Test: user backspaces gate, validator quiets again ✅

---

## 5. spec.debugValidateSpec(): The Silent Killer

### Location
`core_plate/lib/src/model/plate_spec.dart` (line 363-415)

### The Problem

PlateSpec is `const`, so it's computed at build time. Most errors can't happen. But **one class of error** is invisible to the eye:

**Register pitch mismatch**

```
Ideal spacing (0.5 units apart):
┌──────────────────────────────────────┐
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐           │
│ │0 │ │1 │ │2 │ │3 │ │4 │           │
│ └──┘ └──┘ └──┘ └──┘ └──┘           │
└──────────────────────────────────────┘
   0   0.5  1.0  1.5  2.0  2.5

Actual spacing (slight rounding error):
│ │0 │ │1 │ │2 │ │3 │ │4 │
   0  0.50001  1.00002  ...  ← Accumulates!
     ↓ Text breaks not aligned
     Looks like intentional variable spacing (wrong!)
```

### Current Implementation

```dart
void debugValidateSpec() {
  // ... many checks ...
  
  // Pitch validation (line 377-387)
  for (final g in spec.effectiveTextGroups) {
    if (g.key == null || g.indices.length < 3) continue;  // 1-2 slot groups exempt
    
    final boxes = [for (final i in g.indices) spec.slotAt(i).box];
    final sameRow = boxes.every((b) => b.top == boxes.first.top && b.height == boxes.first.height);
    
    if (!sameRow) continue;  // Different rows — exempt
    
    // Check pitch: all gaps should be equal (±1 pixel tolerance)
    final gaps = [for (int i = 1; i < boxes.length; i++) boxes[i].left - boxes[i-1].right];
    final firstGap = gaps[0];
    
    for (final gap in gaps) {
      assert((gap - firstGap).abs() < 0.01, 'Register pitch: expected $firstGap, got $gap');
    }
  }
}
```

### Why This Matters

If register pitch is wrong:
- Text looks misaligned
- Appears intentional (like county codes vs serial)
- But it's actually a typo or rounding error
- **Very hard to spot visually**

### What to Check

#### ✅ Check 1: debugValidateSpec() called at build time

**Test:**
```dart
// During build, this should be called:
PlateSpec spec = IranPlates.car;
spec.debugValidateSpec();  // Fires asserts if invalid
```

**In release mode:**
- Asserts are optimized away
- ❌ This is correct behavior (expensive check, only during dev)

**In debug mode:**
- Asserts fire if pitch is wrong
- ✅ This is correct behavior

---

#### ✅ Check 2: Pitch tolerance is reasonable

**Current:** `0.01` pixels (epsilon)

**Question:** Is this tight enough?
- At 96 DPI: `0.01 * 96 = 0.96` pixels
- At 300 DPI: `0.01 * 300 = 3` pixels
- **Too loose on print!**

**Better:** Make tolerance DPI-aware?
```dart
final tolerance = 0.5;  // ±0.5 pixels is visible
assert((gap - firstGap).abs() < tolerance);
```

---

#### ✅ Check 3: Which groups are validated?

**Current rules:**
- Skip groups with NULL key (not validated)
- Skip groups with < 3 slots (not enough to show pattern)
- Skip groups on different rows (can't have uniform pitch)
- Check pitch on same row, 3+ slots

**Test:**
```dart
// IranPlates.car
// digit-pair (2 slots) — skipped ✅
// letter (1 slot) — skipped ✅
// serial-triple (3 slots) — checked ✅
// province-pair (2 slots) — skipped ✅
```

---

### Action Items

- [ ] Run in debug mode, check asserts fire for any invalid specs
- [ ] Verify pitch epsilon is tight enough for print resolution
- [ ] Review which groups are gated on (3+ slots, same row)
- [ ] Test: modify one spec's pitch slightly, verify assert catches it

---

## Summary: What to Focus On

If you have **1 hour**, check these three:

1. **Migration Logic** (plate_controller.dart, 270-308)
   - Run adoption tests with different spec pairs
   - Verify no data loss in byGroupKey mode

2. **Compositing Strategy** (plate_canvas.dart, 311-336)
   - Render on device, check for seams
   - Verify text is sharp, not blurry

3. **Storage/Display Split** (plate_alphabet.dart, iran_usage.dart)
   - Verify disabled plates render ♿︎, not ژ
   - Check validation reads storage forms

If you have **3 hours**, add:

4. **Gate Pattern** (plate_validator.dart, 62-74)
   - Test validators quiet during entry, judge after
   - Verify gateGroup is always last register

5. **debugValidateSpec()** (plate_spec.dart, 363-415)
   - Run in debug mode, trigger asserts
   - Verify pitch validation is tight

---

**Final Note:** These are not bugs. They're design decisions that are correct but subtle. Verify them visually and in tests, not by reading code alone.
