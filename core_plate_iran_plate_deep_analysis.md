# Deep Code Analysis: core_plate و iran_plate

**نویسنده:** Claude Haiku 4.5  
**تاریخ:** 2026-09-30  
**سطح تفصیل:** Granular — هر function، هر condition، هر loop

---

## فهرست

1. [PlateController](#platecontroller) — کنترل کاراکترهای پلاک
2. [PlateCanvas](#platecanvas) — رندر و ترکیب UI
3. [PlateSpec](#platespec) — تعریف هندسی طراحی پلاک
4. [PlateValidator](#platevalidator) — تایید صحت پلاک
5. [PlateInputMachine](#plateinputmachine) — مدیریت focus و navigation
6. [PlateAlphabet](#platealphabet) — مجموعه کاراکترها و رندر
7. [IranPlates](#iranplates) — مشخصات ایرانی
8. [PersianAlphabets](#persianalphets) — الفبای فارسی
9. [IranUsage](#iranuage) — انواع پلاک ایران

---

## PlateController

**فایل:** `core_plate/lib/src/input/plate_controller.dart`

### نقش کلی

یک `ChangeNotifier` است که:
- مالک کاراکترهای پلاک (`_values` list)
- کنترل focus و navigation
- صحت‌سنجی (validation) را اجرا می‌کند
- می‌تواند بین `PlateSpec`های مختلف migrate کند

### Fields

```dart
PlateSpec _spec              // طراحی فعلی
List<String?> _values        // کاراکترهای ذخیره‌شده (canonical form)
List<ValueNotifier<String?>> _slots  // ValueNotifier برای هر slot
ValueNotifier<bool> _completed  // آیا پلاک پر است؟
PlateInputTarget? _target    // ارتباط با PlateInputMachine
```

### Constructor — `PlateController({required PlateSpec spec, List<String?>? values})`

**خط 30-41:**

```dart
_spec = spec
_values = [for (var i = 0; i < spec.slotCount; i++) _printedCharacter(spec, i)]
```

1. **`_values` initialization:** 
   - طول = `spec.slotCount`
   - هر slot شروع با `_printedCharacter(spec, i)` می‌شود
   - `_printedCharacter()` برمی‌گرداند:
     - اگر الفبای slot دقیقا یک کاراکتر دارد: آن کاراکتر (fixed)
     - وگرنه: `null`

2. **Values population (اگر `values != null`):**
   ```dart
   for (var i = 0; i < spec.slotCount && i < values.length; i++) {
     final printed = _printedCharacter(spec, i);
     if (printed != null) continue;  // slot fixed است، skip
     _values[i] = _sanitize(spec, i, values[i]);
   }
   ```
   - فقط slots ای که fixed نیستند آپدیت می‌شوند
   - `_sanitize()` کاراکتر را validate و canonical form می‌کند

3. **Initialization completion:**
   ```dart
   _foundSlots()           // ValueNotifier برای هر slot
   _completed = ValueNotifier<bool>(_computeCompleted())
   ```

### Factory Constructors

#### `PlateController.fromValues(PlateSpec spec, List<String?> values)`

**خط 44-45:**

صرفا `PlateController(spec: spec, values: values)` را صدا می‌زند. syntactic sugar.

#### `PlateController.fromText(PlateSpec spec, String text)`

**خط 50-61:** Text → slot values تبدیل می‌کند.

```dart
final values = List<String?>.filled(spec.slotCount, null)
var index = 0
for (final character in text.characters) {
  if (index >= spec.slotCount) break
  final alphabet = spec.slots[index].alphabet
  if (!alphabet.accepts(character)) continue  // character رد، slot skip
  values[index] = alphabet.canonical(character)  // canonical form
  index++
}
```

**منطق:**
- هر کاراکتر از text را iterate می‌کند
- اگر الفبای slot آن کاراکتر را قبول نکند: **skip** (gap ایجاد نمی‌کند)
- اگر قبول کند: canonical form ذخیره، به slot بعدی برو

**مثال:** Text `"12A3"` برای [digits, letters, digits] spec:
- `'1'` → slot 0 (digits accept) → `values[0] = '1'`
- `'2'` → slot 1 (letters reject) → skip
- `'A'` → slot 1 (letters accept) → `values[1] = 'A'`
- `'3'` → slot 2 (digits accept) → `values[2] = '3'`
- نتیجه: `['1', 'A', '3']`

### Getters

#### `values`: Unmodifiable list

```dart
List<String?> get values => List<String?>.unmodifiable(_values)
```

- Copy نمی‌کند، wrapper می‌شود
- اگر کسی سعی کند تغییر دهد: exception

#### `slot(int index)`: ValueListenable

```dart
ValueListenable<String?> slot(int index) =>
  index >= 0 && index < _slots.length ? _slots[index] : const _AlwaysNull<String?>()
```

- Widget می‌تواند بر روی یک slot subscibe کند
- اگر index invalid: `_AlwaysNull()` برگردد (never notifies)

### Core Methods

#### `setAt(int index, String? value)`

**خط 81-90:** یک کاراکتر در یک slot تنظیم کند.

```dart
if (index < 0 || index >= _values.length) return  // bounds check
if (_printedCharacter(_spec, index) != null) return  // printed slot، ignore
final next = _sanitize(_spec, index, value)
if (next == null && value != null && value.isNotEmpty) return  // رد شد
_values[index] = next
_slots[index].value = next
_completed.value = _computeCompleted()
notifyListeners()
```

**منطق:**
- اگر slot "printed" است (fixed character): no-op
- اگر `value` خالی یا `null`: صرفا `null` ذخیره
- اگر `value` غیر خالی و رد شود: no-op
- موارد دیگر: `_sanitize()` آن را canonical form می‌کند

#### `setValues(List<String?> values)`

**خط 94-103:** تمام slots یکجا.

```dart
for (var i = 0; i < _values.length; i++) {
  final printed = _printedCharacter(_spec, i)
  final next = printed ?? (i < values.length ? _sanitize(_spec, i, values[i]) : null)
  _values[i] = next
  _slots[i].value = next
}
_completed.value = _computeCompleted()
notifyListeners()
```

- Printed slots: خودشان را keep می‌کنند
- Non-printed slots: مقدار از `values` می‌گیرند (یا `null` اگر `i >= values.length`)
- **یک بار** `notifyListeners()` می‌شود

#### `setGroup(String key, String value)`

**خط 119-132:** یک TextGroup را پر کند (by key).

```dart
final group = _groupNamed(_spec, key)
if (group == null) return
final characters = value.characters
for (var n = 0; n < group.indices.length; n++) {
  final index = group.indices[n]
  if (_printedCharacter(_spec, index) != null) continue
  final character = n < characters.length ? characters[n] : ''
  _values[index] = _sanitize(_spec, index, character)
  _slots[index].value = _values[index]
}
_completed.value = _computeCompleted()
notifyListeners()
```

**مثال:** `group(key: 'district', value: '12')` برای group `[0, 1]`:
- `n=0`: `values[0] = '1'`
- `n=1`: `values[1] = '2'`
- اگر `group.indices.length > value.length`: remaining slots پاک می‌شوند

### Validation

#### `validation` Getter

```dart
PlateValidation? get validation => _probe?.call()
```

- On-demand validator call
- اگر `_probe == null`: always `null`

#### `installValidation(PlateValidation? Function()? probe)`

```dart
_probe = probe
_lastVerdict = null
```

- `PlateCanvas` این را صدا می‌زند
- Store probe function، last verdict را reset

#### `reportValidation(PlateValidation? value)`

```dart
if (_lastVerdict == value) return  // same verdict، no-op
_lastVerdict = value
notifyListeners()
```

- فقط اگر verdict تغییر کند: notify

### Migration — `_migrate()` Static Method

**خط 270-308:** کاراکترها را بین dwo spec انتقال دهد.

```dart
static List<String?> _migrate(
  PlateSpec from,
  PlateSpec to,
  List<String?> values,
  PlateValuePreservation preserve
) {
  // 1. preserve == none → تمام null
  if (preserve == PlateValuePreservation.none) {
    return List<String?>.filled(to.slotCount, null)
  }

  // 2. byKey preservation
  final byKey = preserve == PlateValuePreservation.byGroupKey &&
    (_hasKeyedGroups(from) || _hasKeyedGroups(to))
  if (!byKey) {
    // 3. byIndex fallback
    return [
      for (var i = 0; i < to.slotCount; i++)
        i < values.length ? _sanitize(to, i, values[i]) : null
    ]
  }

  // 4. Full byKey migration
  final result = List<String?>.filled(to.slotCount, null)

  // Printed slots اول
  for (var i = 0; i < to.slotCount; i++) {
    result[i] = _printedCharacter(to, i)
  }

  // هر group در `to` را از `from` پیدا کن
  for (final target in to.effectiveTextGroups) {
    final key = target.key
    if (key == null) continue
    final source = _groupNamed(from, key)
    if (source == null) continue

    // غیر-خالی کاراکترها را جمع کن (gaps را skip)
    final characters = <String>[
      for (final i in source.indices)
        if (i < values.length && (values[i] ?? '').isNotEmpty)
          values[i]!,
    ]

    // به target indices بنویس
    for (var n = 0; n < target.indices.length; n++) {
      final index = target.indices[n]
      final character = n < characters.length ? characters[n] : ''
      result[index] = _sanitize(to, index, character)
    }
  }

  return result
}
```

**مثال:**

```
From: [district: '12', letter: 'A', serial: '345']
To:   [district: '1', letter: 'B', serial: '34']

Preserve: byGroupKey

نتیجه:
  district: ['1', '2'] → '12' → source.indices=[0,1]
  → characters = ['1', '2']
  → تا 1 target slot: result[0] = '1'

  letter: 'A' → source.indices=[1]
  → characters = ['A']
  → target.indices=[1]: result[1] = 'A'

  serial: '345' → source.indices=[2,3,4]
  → characters = ['3', '4', '5']
  → تا 2 target slots: result[2]='3', result[3]='4'

نهایی: ['1', 'A', '3', '4']
```

### `adoptSpec()` Public Method

**خط 152-162:** PlateSpec را تغییر دهد.

```dart
void adoptSpec(
  PlateSpec next,
  {PlateValuePreservation preserve = PlateValuePreservation.byGroupKey}
) {
  final migrated = _migrate(_spec, next, _values, preserve)
  _spec = next
  _values = migrated
  for (final slot in _slots) {
    slot.dispose()
  }
  _foundSlots()  // ValueNotifier برای هر slot جدید
  _completed.value = _computeCompleted()
  notifyListeners()
}
```

- ValueNotifier را dispose/recreate می‌کند تا widget‌ها notified شوند

### Helper Methods

#### `_sanitize(PlateSpec spec, int index, String? value)`

```dart
if (value == null || value.isEmpty) return null
final slot = spec.slotAt(index)
if (slot == null || !slot.alphabet.accepts(value)) return null
return slot.alphabet.canonical(value)
```

- `null` یا خالی → `null`
- رد → `null`
- قبول → canonical form

#### `_printedCharacter(PlateSpec spec, int index)`

```dart
final characters = spec.slots[index].alphabet.characters
return characters.length == 1 ? characters.single : null
```

- Alphabet دقیقا یک کاراکتر → آن
- وگرنه → `null`

#### `_foundSlots()`

```dart
_slots = [for (var i = 0; i < _spec.slotCount; i++) ValueNotifier<String?>(_values[i])]
```

- هر slot یک ValueNotifier
- initial value = `_values[i]`

#### `_computeCompleted()`

```dart
return _values.isNotEmpty && !_values.any((v) => v == null || v.isEmpty)
```

- تمام slots پر نباید (و list خالی نباید)

---

## PlateCanvas

**فایل:** `core_plate/lib/src/widgets/plate_canvas.dart`

### نقش کلی

یک `StatefulWidget` است که:
- PlateSpec را render می‌کند (UI)
- PlateController را مدیریت می‌کند (خود یا host-supplied)
- PlateInputMachine را برای focus/navigation صدا می‌زند
- Auto-validation و input handling

### State — `_PlateCanvasState`

#### Key Fields

```dart
late PlateInputMachine _machine       // focus و navigation
late PlateController _controller      // characters و completion
bool _ownsController = false          // آیا private controller است؟
ThemeData? _selectionTheme            // cached text selection theme
Color? _selectionThemeColor
_PlateFaceClipper? _faceClipper       // cached clip
```

#### `initState()`

```dart
super.initState()
_adoptController()
_installMachine()
```

- Controller را adopt کن (خود یا host's)
- Machine را برای این spec بسازی

#### `didUpdateWidget(PlateCanvas oldWidget)`

**خط 118-141:** Widget parameter تغییر کند.

```dart
// Case 1: Spec تغییر
if (widget.spec.id != oldWidget.spec.id) {
  _controller.adoptSpec(widget.spec, preserve: widget.onSpecChange)
  oldWidget.controller?.detach(_machine)
  widget.controller?.detach(_machine)
  _machine.dispose()
  _installMachine()
}
// Case 2: Controller تغییر
else if (widget.controller != oldWidget.controller) {
  oldWidget.controller?.installValidation(null)
  oldWidget.controller?.detach(_machine)
  widget.controller?.attach(_machine)
  widget.controller?.installValidation(_probeValidation)
  _adoptController(replacing: true)
}
```

**درست شدن:**
- اگر spec تغییر: `adoptSpec()` باعث migration
- اگر controller تغییر: new one را attach کن، old one را stand down

#### `_adoptController({bool replacing = false})`

**خط 159-172:** کدام controller استفاده شود.

```dart
final host = widget.controller
if (host == null) {
  // Host یکی نداد
  if (replacing && _ownsController) return  // already own one
  _controller = PlateController(spec: widget.spec)
  _ownsController = true
  return
}
// Host یکی داد
if (replacing && identical(_controller, host)) return  // same
final stoodDown = replacing && _ownsController ? _controller : null
_controller = host
_ownsController = false
stoodDown?.dispose()
```

#### `_installMachine()`

**خط 175-193:** PlateInputMachine برای current spec.

```dart
assert(debugValidateSpec(widget.spec))
final machine = PlateInputMachine(
  spec: widget.spec,
  inputSource: _resolveInputSource(),
  readValues: () => _controller.values,
  commit: (index, value) => _controller.setAt(index, value),
  onActiveIndexChanged: _reportActiveIndex,
)..onSheetRequested = _openPicker
_machine = machine
widget.controller?.attach(machine)
widget.controller?.installValidation(_probeValidation)

// Seed active slot
if (machine.activeIndex != null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !identical(_machine, machine)) return
    _reportActiveIndex(machine.activeIndex)
  })
}
```

### Build Method

**خط 236-399:** UI tree کامل.

#### Theme Resolution

```dart
var theme = widget.theme ?? PlateTheme.of(context)
// borderWidthRatio override
if (spec.borderWidthRatioOverride != null) {
  theme = theme.copyWith(borderWidthRatio: spec.borderWidthRatioOverride!)
}
// Ink override (monochrome set)
if (spec.inkOverride != null) {
  final ink = spec.inkOverride!
  theme = theme.copyWith(
    ink: ink,
    plateBorder: ink,
    dividerColor: ink,
    activeColor: ink,
  )
}
```

#### Behavior Resolution

```dart
final behaviors = <SlotBehavior>[
  for (final s in spec.slots)
    resolveSlotBehavior(
      mode: widget.mode,
      input: s.alphabet.input,
      source: _machine.inputSource,
    ),
]
```

- هر slot: `sheet` یا `field`؟
- Resolved یکبار، تمام downstream استفاده می‌کند

#### THE FACE IS TWO LAYERS

**خط 311-387:** اصلی‌ترین بخش comments.

```dart
final artwork = _PlateArtwork(...)  // FittedBox 1: NO TextFields
final inputs = _ValidationBinding(...) or _PlateInputs(...)  // FittedBox 2: TextFields

final face = Stack(
  fit: StackFit.passthrough,
  children: [artwork, inputs],  // Two FittedBoxes, same geometry
)
```

**چرا؟**

1. **TextFields composite layers** (EditableText → CompositedTransformTarget)
2. اگر یک FittedBox باشد: flag رasterized می‌شود
3. دو FittedBox: اول کے artwork (`no compositing`) vector بماند
4. دوم کے inputs: رasterized اما animated slots فقط اینجا

#### Validation

```dart
if (widget.autoValidate && validator != null) {
  // _ValidationBinding: verdict → activeColor change
  _ValidationBinding(
    controller: _controller,
    validate: (values) => validator.validate(_entryFor(values)),
    onVerdict: _publishVerdict,
    builder: (verdict) => _PlateInputs(
      theme: verdict.isValid ? theme : theme.copyWith(activeColor: theme.alertColor),
      ...
    ),
  )
} else {
  _PlateInputs(theme: theme, ...)
}
```

### Binding Classes

#### `_FrameBinding` — Border و face

```dart
ValueListenableBuilder<bool>(
  valueListenable: controller.completed,
  builder: (context, isCompleted, _) => PlateFrame(...),
)
```

- فقط `isCompleted` flip اپ rebuild

#### `_SlotBinding` — یک character

```dart
ValueListenableBuilder<String?>(
  valueListenable: controller.slot(index),
  builder: (context, value, _) {
    machine.syncController(index, value)
    return PlateSlotItem(...)
  },
)
```

- یک keystroke: یک slot rebuild

#### `_ValidationBinding` — verdict only

```dart
PlateSelector<PlateValidation>(
  controller: controller,
  selector: (c) => validate(c.values),
  builder: (context, verdict) => _VerdictListener(...),
)
```

- Equality-based: فقط اگر `verdict != oldVerdict`

---

## PlateSpec

**فایل:** `core_plate/lib/src/model/plate_spec.dart`

### نقش کلی

یک `@immutable` const class است که:
- موارد هندسی و ساختاری از پلاک را تعریف می‌کند
- TextGroups و validation keys
- Metadata برای rendering

### Fields

```dart
String id                        // stable identifier
PlateCountry country
double canvasWidth, canvasHeight
PlatePanel panel                 // colored block
bool noPanel = false
PlateBand? rightBand, innerBand
List<PlateSlot> slots
List<PlateRule> rules, labels, decals, mirrors
TextDirection textDirection
double? borderWidthRatioOverride
Color? inkOverride
List<PlateTextGroup> textGroups
```

### Key Getters

#### `slotCount`

```dart
int get slotCount => slots.length
```

#### `effectiveTextGroups`

```dart
List<PlateTextGroup> get effectiveTextGroups => textGroups.isNotEmpty
  ? textGroups
  : [for (var i = 0; i < slots.length; i++) PlateTextGroup([i])]
```

- اگر `textGroups` empty: default one-per-slot
- هر slot: PlateTextGroup([i])

#### `renderGroup(PlateTextGroup group, List<String?> values)`

```dart
StringBuffer buffer = StringBuffer(group.prefix)
for (final i in group.indices) {
  final value = i < values.length ? (values[i] ?? '') : ''
  buffer.write(slotAt(i)?.alphabet.render(value) ?? '')
}
return buffer.toString()
```

- Prefix اول (e.g. "IR " for province)
- سپس هر slot's value، rendered through alphabet's glyphs

#### `valueOfGroup(String key, List<String?> values)`

```dart
final group = _groupNamed(key)
if (group == null) return ''
final buffer = StringBuffer()
for (final i in group.indices) {
  buffer.write(i < values.length ? (values[i] ?? '') : '')
}
return buffer.toString()
```

- **Unrendered** values (canonical form)
- فقط characters، بدون prefix

#### `indicesOfGroup(String key)`

```dart
_groupNamed(key)?.indices ?? const <int>[]
```

- slot indices برای این group

### Equality

```dart
bool operator ==(Object other) => other is PlateSpec && other.id == id
int get hashCode => id.hashCode
```

- **فقط `id` مهم است**
- تمام بقیه fields: equality تاثیری ندارند

### Validation — `debugValidateSpec()`

**خط 331-418:** Debug-only consistency checks.

#### Check 1: Rects in canvas

```dart
void checkInCanvas(PlateBox b, String what) {
  assert(
    b.left >= 0 &&
    b.top >= 0 &&
    b.right <= spec.canvasWidth &&
    b.bottom <= spec.canvasHeight,
    'rect outside canvas',
  )
}
for (var i = 0; i < spec.slots.length; i++) {
  checkInCanvas(spec.slots[i].box, 'PlateSlot $i')
}
// ... mirrors, bands
```

#### Check 2: Mirrors echo real slots

```dart
for (var i = 0; i < spec.mirrors.length; i++) {
  final m = spec.mirrors[i]
  assert(
    m.source >= 0 && m.source < spec.slots.length,
    'PlateMirror $i echoes invalid slot ${m.source}',
  )
}
```

#### Check 3: Registers evenly pitched

```dart
for (final g in spec.effectiveTextGroups) {
  if (g.key == null || g.indices.length < 3) continue  // need ≥3 for pitch
  final boxes = [for (final i in g.indices) spec.slots[i].box]
  final sameRow = boxes.every((b) => b.top == boxes.first.top && b.height == boxes.first.height)
  if (!sameRow) continue
  
  final pitch = boxes[1].left - boxes[0].left
  for (var n = 1; n < boxes.length; n++) {
    assert(
      (boxes[n].left - boxes[0].left - n * pitch).abs() < 0.01,
      'Register "${g.key}" unevenly pitched',
    )
  }
}
```

#### Check 4: Alphabet IDs consistent

```dart
final byId = <String, String>{}
final byContent = <String, String>{}

// Collect all alphabets
for (final a in <PlateAlphabet>[
  for (final slot in spec.slots) slot.alphabet,
  for (final m in spec.mirrors) if (m.alphabet != null) m.alphabet!,
]) {
  final contentKey = _contentKey(a)  // character/glyph pairs
  
  // Check: same id → same content
  final seenContent = byId[a.id]
  assert(
    seenContent == null || seenContent == contentKey,
    'Alphabet id "${a.id}" appears with different content',
  )
  byId[a.id] = contentKey
  
  // Check: same content → same id
  final seenId = byContent[contentKey]
  assert(
    seenId == null || seenId == a.id,
    'Two ids sharing same content',
  )
  byContent[contentKey] = a.id
}
```

---

## PlateValidator

**فایل:** `core_plate/lib/src/validators/plate_validator.dart`

### PlateValidation

```dart
@immutable
class PlateValidation {
  const PlateValidation.valid() : reason = null
  const PlateValidation.invalid(String this.reason)
  
  final String? reason
  bool get isValid => reason == null
  
  @override
  bool operator ==(Object other) => other is PlateValidation && other.reason == reason
  int get hashCode => reason.hashCode
}
```

- **Equality:** فقط `reason`
- اگر دو `invalid("same text")`: مساوی‌اند
- اگر کنترل‌کننده دو بار کال شود: هم verdict = listener not fired

### PlateEntry

```dart
@immutable
class PlateEntry {
  const PlateEntry({required this.spec, required this.values, this.activeIndex})
  
  final PlateSpec spec
  final List<String?> values
  final int? activeIndex
  
  String group(String key) => spec.valueOfGroup(key, values)
  PlateTextGroup? get activeGroup => activeIndex == null ? null : spec.groupAt(activeIndex!)
}
```

- **Snapshot** از plate as it stands
- Validator می‌تواند `activeIndex` check کند اگر ام می‌خواهد "quiet until last group"

### PlateValidator

```dart
abstract class PlateValidator {
  const PlateValidator()
  PlateValidation validate(PlateEntry entry)
}
```

- Abstract method: `validate(PlateEntry)`
- Host می‌تواند خود یا auto-validate کند

### GatedPlateValidator

**خط 62-74:** گیت تا آخرین group پر نشود.

```dart
abstract class GatedPlateValidator extends PlateValidator {
  String get gateGroup  // PlateTextGroup.key
  PlateValidation judge(PlateEntry entry)  // verdict on non-empty gate
  
  @override
  PlateValidation validate(PlateEntry entry) =>
    entry.group(gateGroup).isEmpty
      ? const PlateValidation.valid()  // gate empty → valid (quiet)
      : judge(entry)                   // gate filled → judge
}
```

**استفاده:**
- Iran plates: `gateGroup: 'province'`
- تا صارف اخری pair (province) کامل نکند: always valid
- بعد: judge می‌کند اگر بقیه valid هستند

---

## PlateInputMachine

**فایل:** `core_plate/lib/src/input/plate_input_machine.dart`

### نقش کلی

Focus nodes و TextEditingControllers را مدیریت می‌کند.
با PlateController decouple است:
- می‌خواند through `readValues()`
- می‌نویسد through `commit(index, value)`

### Constructor

**خط 16-46:**

```dart
PlateInputMachine({
  required this.spec,
  required this.readValues,
  required this.commit,
  required this.inputSource,
  this.onActiveIndexChanged,
})
```

**Setup:**

```dart
// 1. Focus nodes و controllers برای هر slot
for (var i = 0; i < spec.slots.length; i++) {
  _focusNodes.add(FocusNode()..addListener(_handleFocusChange))
  _controllers.add(
    spec.slots[i].alphabet.input == AlphabetInput.typed
      ? TextEditingController()
      : null  // chosen alphabet ← no controller
  )
}

// 2. Mirror focus nodes و controllers
for (var i = 0; i < spec.mirrors.length; i++) {
  final mirror = spec.mirrors[i]
  final alphabet = mirror.alphabet ?? spec.slots[mirror.source].alphabet
  if (mirror.editable && alphabet.input == AlphabetInput.typed) {
    _mirrorFocusNodes.add(FocusNode()..addListener(_handleFocusChange))
    _mirrorControllers.add(TextEditingController())
  } else {
    _mirrorFocusNodes.add(null)
    _mirrorControllers.add(null)
  }
}

// 3. Seed active slot
_activeIndex = spec.slots.isNotEmpty ? 0 : null
```

### Focus Management

#### `_handleFocusChange()`

```dart
int? active
for (var i = 0; i < _focusNodes.length; i++) {
  if (_focusNodes[i].hasFocus) {
    active = i
    break
  }
}

// Mirror focus → source slot
if (active == null) {
  for (var i = 0; i < _mirrorFocusNodes.length; i++) {
    if (_mirrorFocusNodes[i]?.hasFocus ?? false) {
      active = spec.mirrors[i].source
      break
    }
  }
}

if (active != _activeIndex) {
  _activeIndex = active
  onActiveIndexChanged?.call(active)
}
```

- اگر هر mirror focus شود: active = source slot
- اگر هر slot focus شود: active = slot index

#### `advanceFrom(int index)`

```dart
final next = spec.nextIndex(index)
if (next == null) {
  _focusNodes[index].unfocus()
  return
}

final nextBehavior = resolveSlotBehavior(
  mode: PlateMode.input,
  input: spec.slots[next].alphabet.input,
  source: inputSource,
)

if (nextBehavior == SlotBehavior.sheet) {
  onSheetRequested?.call(next)  // picker
} else {
  _focusNodes[next].requestFocus()
}
```

- اگر آخر: unfocus
- اگر next: `sheet` behavior → open picker
- وگرنه: focus next

### Value Sync

#### `syncController(int index, String? value)`

```dart
final field = _controllers[index]
if (field == null) return  // chosen alphabet
final stored = value ?? ''
final text = stored.isEmpty ? '' : spec.slots[index].alphabet.render(stored)
if (field.text == text) return  // unchanged
field.value = TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
)
```

- Stored form → rendered form (display glyph)
- Cursor at end

#### `syncMirrorController(int mirrorIndex, PlateAlphabet alphabet, String? value)`

مثل `syncController` اما through mirror's alphabet.

### Character Entry

#### `submitCharacter(String c)`

```dart
final index = _activeIndex
if (index == null || !spec.slots[index].alphabet.accepts(c)) return
commit(index, c)
advanceFrom(index)
```

#### `backspaceCharacter()`

```dart
final index = _activeIndex
if (index == null) return
final values = readValues()
final current = values[index]
final target = (current == null || current.isEmpty) ? spec.previousIndex(index) : index
if (target == null) return
commit(target, '')
_focusNodes[target].requestFocus()
```

- اگر current slot خالی: backspace to previous
- وگرنه: backspace current و stay

#### `focusFirstEmptySlot()`

```dart
final values = readValues()
for (var i = 0; i < spec.slots.length; i++) {
  final v = values[i]
  if (v == null || v.isEmpty) {
    _focusNodes[i].requestFocus()
    return
  }
}
_focusNodes.first.requestFocus()  // اگر تمام پر: first
```

---

## PlateAlphabet

**فایل:** `core_plate/lib/src/model/plate_alphabet.dart`

### نقش کلی

یک slot زبان کاراکترها:
- کدام کاراکترها قبول (characters)
- چگونه render شوند (glyphs)
- کدام input behavior (typed vs chosen)

### Constructor

```dart
const PlateAlphabet({
  required this.id,
  required this.characters,
  required this.input,
  required this.isNumeric,
  this.glyphs = const <String, String>{},
  this.direction = TextDirection.ltr,
  this.placeholder = '?',
})
```

### Character Operations

#### `accepts(String value)`

```dart
bool accepts(String value) => characters.contains(canonical(value))
```

- Accepts both forms: storage و glyph
- Canonical آن سپس check

#### `canonical(String value)`

```dart
String canonical(String value) {
  if (glyphs.isEmpty) return value
  for (final entry in glyphs.entries) {
    // اولین entry match: ترتیب مهم است
    if (entry.value == value) return entry.key
  }
  return value
}
```

- گیف → storage
- اگر `glyphs` کے `{'۵': '5'}` و input `۵`: return `'5'`

#### `render(String value)`

```dart
String render(String value) => glyphs[value] ?? value
```

- Storage → glyph
- `'5'` → `'۵'` (یا خود اگر نہ glyph)

### Equality

```dart
bool operator ==(Object other) =>
  identical(this, other) || (other is PlateAlphabet && other.id == id)
int get hashCode => id.hashCode
```

- **فقط `id`** (PlateSpec نظیر)

### Constants

```dart
static const PlateAlphabet latinDigits = PlateAlphabet(
  id: 'latin.digits',
  characters: ['0'...'9'],
  input: AlphabetInput.typed,
  isNumeric: true,
)

static const PlateAlphabet latinUppercase = PlateAlphabet(
  id: 'latin.upper',
  characters: ['A'...'Z'],
  input: AlphabetInput.typed,
  isNumeric: false,
)
```

---

## IranPlates

**فایل:** `iran_plate/lib/src/iran_plates.dart`

### نقش کلی

17 specifications ایرانی، تمام `const` یا `final`.
تمام standard format از `_standard()` derived.

### `_standard()` Builder

**خط 16-72:** Shared blank.

```dart
static PlateSpec _standard({
  required String id,
  required PlateAlphabet letter,
  PlateBox letterBox = const PlateBox(175, 17, 55, 76),
  String squareCaption = 'ایران',
  List<PlateLabel> extraLabels = const <PlateLabel>[],
}) {
  return PlateSpec(
    id: id,
    country: IranCountry.iran,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: const PlatePanel(box: PlateBox(0, 0, 56.4, 110)),
    textDirection: TextDirection.rtl,
    slots: [
      ...plateRegister(
        alphabet: PersianAlphabets.digits,
        count: 2,
        left: 65,
        top: 17,
        width: 47,
        height: 76,
        pitch: 55,
      ),  // indices [0, 1]: district
      PlateSlot(alphabet: letter, box: letterBox),  // index [2]: letter
      ...plateRegister(
        alphabet: PersianAlphabets.digits,
        count: 3,
        left: 238,
        top: 17,
        width: 47,
        height: 76,
        pitch: 55,
      ),  // indices [3, 4, 5]: serial
      ...plateRegister(
        alphabet: PersianAlphabets.digits,
        count: 2,
        left: 428,
        top: 40,
        width: 32,
        height: 52,
        pitch: 38,
      ),  // indices [6, 7]: province
    ],
    rules: const [PlateRule(box: PlateBox(404, 4.4, 5, 101.2))],  // divider
    labels: [
      PlateLabel(text: squareCaption, box: const PlateBox(412, 18, 103, 16), glyphHeight: 16),
      ...extraLabels,
    ],
    textGroups: const [
      PlateTextGroup([0, 1], key: 'district'),
      PlateTextGroup([2], key: 'letter'),
      PlateTextGroup([3, 4, 5], key: 'serial'),
      PlateTextGroup([6, 7], prefix: 'IR ', key: 'province'),
    ],
  )
}
```

**هندسی:**
```
[0][1] [2] [3][4][5] [6][7]
district | letter | serial | province
  pair    single   triple    pair
```

**TextGroups:**
- `district`: [0, 1]
- `letter`: [2]
- `serial`: [3, 4, 5]
- `province`: [6, 7] + prefix "IR "

### Plate Definitions

#### Standard Classes (all using `_standard()`)

```dart
static final PlateSpec car = _standard(id: 'ir.car', letter: PersianAlphabets.privateLetters)

static final PlateSpec disabled = _standard(
  id: 'ir.disabled',
  letter: PersianAlphabets.disabledSymbol,
  letterBox: const PlateBox(170, 16, 66, 77),  // wider
)

static final PlateSpec taxi = _standard(
  id: 'ir.taxi',
  letter: PersianAlphabets.taxiLetter,
  letterBox: const PlateBox(175, 41, 55, 52),  // lower
  extraLabels: const [PlateLabel(text: 'TAXI', box: PlateBox(158, 12, 89, 26), glyphHeight: 26)],
)

// ... publicTransport, agricultural, government, temporary, police, irgc, army, ministryOfDefence, generalStaff, political, service
```

#### Non-Standard Classes

##### `protocol`

```dart
static final PlateSpec protocol = PlateSpec(
  id: 'ir.protocol',
  slots: plateRegisterAcross(
    alphabet: PersianAlphabets.digits,
    count: 5,
    left: 294,
    right: 497,
    top: 16,
    height: 76,
  ),
  labels: const [
    PlateLabel(text: 'تشریفات', box: PlateBox(63, 4, 221, 52), glyphHeight: 48),
    PlateLabel(text: 'PROTOCOL', box: PlateBox(63, 56, 221, 42), glyphHeight: 42),
  ],
  textGroups: const [
    PlateTextGroup([0, 1, 2, 3, 4], key: 'serial'),
  ],
)
```

- 5 digits فقط
- No letter, no district, no province

##### `historic`

```dart
static final PlateSpec historic = PlateSpec(
  id: 'ir.historic',
  canvasWidth: 300,
  canvasHeight: 150,
  borderWidthRatioOverride: 0.04,
  slots: plateRegisterAcross(
    alphabet: PersianAlphabets.digits,
    count: 5,
    left: 114,
    right: 285,
    top: 76,
    height: 58,
  ),
  labels: const [PlateLabel(text: 'تاریخی', box: PlateBox(114, 12, 171, 46), glyphHeight: 46)],
  textGroups: const [
    PlateTextGroup([0, 1, 2, 3, 4], key: 'serial'),
  ],
)
```

- American standard size (300x150)
- 5 digits

##### `motorcycle`

```dart
static final PlateSpec motorcycle = PlateSpec(
  id: 'ir.motorcycle',
  canvasWidth: 175,
  canvasHeight: 110,
  borderWidthRatioOverride: 0.05,
  slots: [
    ...plateRegister(alphabet: PersianAlphabets.digits, count: 3, left: 74, top: 13, width: 22, height: 36, pitch: 30),
    ...plateRegister(alphabet: PersianAlphabets.digits, count: 5, left: 8, top: 58, width: 27, height: 44, pitch: 33),
  ],
  textGroups: const [
    PlateTextGroup([0, 1, 2], key: 'province'),
    PlateTextGroup([3, 4, 5, 6, 7], key: 'serial'),
  ],
)
```

- 3 digits اوپر (province)
- 5 digits نیچے (serial)

### Lookup Methods

#### `forUsage(IranUsage usage)`

```dart
static PlateSpec forUsage(IranUsage usage) => switch (usage) {
  IranUsage.private => car,
  IranUsage.disabled => disabled,
  ...
  IranUsage.protocol => protocol,
  IranUsage.historic => historic,
  IranUsage.motorcycle => motorcycle,
}
```

#### `all` Getter

```dart
static List<PlateSpec> get all => <PlateSpec>[
  for (final IranUsage usage in IranUsage.values)
    forUsage(usage)
]
```

- Gallery تمام 17 سے walk می‌کند

---

## PersianAlphabets

**فایل:** `iran_plate/lib/src/persian_alphabets.dart`

### Digits

```dart
static const PlateAlphabet digits = PlateAlphabetDigits.iranian
```

- Shared from `plate_alphabet` package
- Storage: `'0'...'9'`
- Display: `'۰'...'۹'`

### Private Letters

```dart
static const PlateAlphabet privateLetters = PlateAlphabet(
  id: 'fa.privateLetters',
  characters: ['ب', 'ج', 'د', 'س', 'ص', 'ط', 'ق', 'ل', 'م', 'ن', 'و', 'ه', 'ی'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  direction: TextDirection.rtl,
  placeholder: '؟',
)
```

- 13 letters (Wikipedia article)
- No glyphs (storage = display)
- `chosen`: picker کھول

### Disabled Symbol

```dart
static const PlateAlphabet disabledSymbol = PlateAlphabet(
  id: 'fa.disabledSymbol',
  characters: ['ژ'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  direction: TextDirection.rtl,
  placeholder: '♿︎',
  glyphs: {'ژ': '♿︎'},
)
```

- Storage: `'ژ'` (police database)
- Display: `'♿︎'` (what's printed)
- Chosen: no picking (only one option)

### Fixed Letters (Taxis, Police, etc.)

```dart
static const PlateAlphabet taxiLetter = PlateAlphabet(
  id: 'fa.taxiLetter',
  characters: ['ت'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  direction: TextDirection.rtl,
  placeholder: '؟',
)
```

- ہر class: یک مخصوص حرف
- `chosen`: یہاں keyboard ٹائپنگ ممکن نہیں

### Political and Service Letters

```dart
static const PlateAlphabet politicalLetter = PlateAlphabet(
  id: 'fa.politicalLetter',
  characters: ['D'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  placeholder: '?',  // NO direction: default LTR
)

static const PlateAlphabet serviceLetter = PlateAlphabet(
  id: 'fa.serviceLetter',
  characters: ['S'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  placeholder: '?',
)
```

- لاطینی letters
- کوئی `direction` override: پہلے سے LTR

### `forUsage()` Lookup

```dart
static PlateAlphabet? forUsage(IranUsage usage) => switch (usage) {
  IranUsage.private => privateLetters,
  IranUsage.disabled => disabledSymbol,
  IranUsage.taxi => taxiLetter,
  ...
  IranUsage.protocol || IranUsage.historic || IranUsage.motorcycle => null,
}
```

- یہ تین کلاسوں میں کوئی حرف نہیں

---

## IranUsage

**فایل:** `iran_plate/lib/src/iran_usage.dart`

### Enum Definition

```dart
enum IranUsage {
  private(seriesLetter: null, latin: null, description: 'Private vehicles'),
  disabled(seriesLetter: 'ژ', latin: 'Ž', description: 'Private vehicles of people with disabilities'),
  taxi(seriesLetter: 'ت', latin: 'T', description: 'Taxis'),
  // ... 14 دوسرے
}
```

### Fields

```dart
final String? seriesLetter  // stored form (e.g. 'ت')
final String? latin         // transliteration (e.g. 'T')
final String description    // human-readable
```

### Design Rationale

```
Usage (enum) → letter (PersianAlphabets.forUsage)
            → spec (IranPlates.forUsage)
            → theme (IranThemes.forUsage)
```

- Closed enum: state-owned plate classes
- یہ کبھی user-extensible نہیں

---

## Subtle Issues و Design Decisions

### 1. PlateController._migrate() — Gap Skipping

**Issue:** نیچے اوپر:

```dart
final characters = <String>[
  for (final i in source.indices)
    if (i < values.length && (values[i] ?? '').isNotEmpty)
      values[i]!,
]
```

**Behavior:** اگر source `[0, 1, 2]` ہے اور values `['1', '', '3']`:
- Skipped ہے `values[1]` (خالی)
- نتیجہ characters: `['1', '3']`
- اگر target `[0, 1]`: result `['1', '3']`

یہ **intentional** ہے: نیمہ-بھرے register کو carry کریں، لیکن gaps کو collapse کریں۔

### 2. PlateCanvas — Two FittedBox Layers

**Why:**
- یک FittedBox: TextFields rasterize (flag blurry)
- دو FittedBox: ہر ایک independently scale
- Layer 1 (artwork): no TextFields, vector رہتا ہے
- Layer 2 (inputs): TextFields composite، لیکن animated

### 3. PlateAlphabet.canonical() — First Match

```dart
for (final entry in glyphs.entries) {
  if (entry.value == value) return entry.key
}
```

**Issue:** اگر دو storage characters `'5'` print کریں (impossible normally)، پہلا match قدر میں واپسی ہوتی ہے۔ **Order matters.**

### 4. GatedPlateValidator — Silent Until Gate

Iran validator: "don't judge until province pair is filled"

```dart
entry.group(gateGroup).isEmpty
  ? const PlateValidation.valid()  // quiet
  : judge(entry)
```

یہ **user experience:** صارف typing ہے، پہلے error نہ دیکھیں۔

### 5. PlateInputMachine — Mirror Focus Reports as Source

```dart
if (active == null) {
  for (var i = 0; i < _mirrorFocusNodes.length; i++) {
    if (_mirrorFocusNodes[i]?.hasFocus ?? false) {
      active = spec.mirrors[i].source
      break
    }
  }
}
```

- دو rows (mirror): ایک value
- کیبوڈ: source slot کا الفبے دکھاتا ہے (کونسی row focused)

---

## Edge Cases اور Potential Issues

### 1. Empty Spec

```dart
PlateController(spec: plateWithZeroSlots)
_activeIndex = spec.slots.isNotEmpty ? 0 : null
```

- Handled: `_activeIndex = null`

### 2. Out-of-Bounds Index

```dart
ValueListenable<String?> slot(int index) =>
  index >= 0 && index < _slots.length ? _slots[index] : const _AlwaysNull<String?>()
```

- Widget outliving shrinking spec: `_AlwaysNull` اور no crash

### 3. Backspace at First Slot

```dart
final target = (current == null || current.isEmpty) ? spec.previousIndex(index) : index
if (target == null) return
```

- اگر index 0 اور خالی: `previousIndex(0)` = `null` → no-op

### 4. Multiple Glyphs for One Character

```dart
for (final entry in glyphs.entries) {
  if (entry.value == value) return entry.key
}
```

**Not supported:** `{'ж': '۵', 'зн': '۵'}` ہو تو صرف `'ж'` match ہے۔

### 5. Validation Equality

```dart
bool operator ==(Object other) => other is PlateValidation && other.reason == reason
```

دو `PlateValidation.invalid("same text")`: برابر۔ اگر host دوبارہ کال کریں، no rebuild.

---

## خلاصہ: Data Flow

```
┌─────────────────────────────────────┐
│ IranUsage enum                      │
└────────────────────┬────────────────┘
                     │
         ┌───────────┴──────────┬──────────────────┐
         │                      │                  │
    letter (PersianAlphabets)  spec (IranPlates)  theme (IranThemes)
         │                      │
         │                      └─────────────────┐
         │                                        │
    ┌────┴──────────┐                      ┌─────┴─────────┐
    │ PlateAlphabet │                      │  PlateSpec    │
    │ - characters  │                      │ - slots       │
    │ - glyphs      │                      │ - textGroups  │
    │ - input       │                      │ - geometry    │
    └────┬──────────┘                      └──────┬────────┘
         │                                        │
         └──────────────────┬─────────────────────┘
                            │
                      ┌─────▼──────────┐
                      │ PlateCanvas    │
                      └────────┬───────┘
                               │
                    ┌──────────┼──────────┐
                    │          │          │
            ┌───────▼──┐ ┌─────▼─┐ ┌────▼──────┐
            │Controller│ │Machine│ │Validator  │
            └──────────┘ └───────┘ └───────────┘
```

---

**اختتام**

یہ تجزیہ توضیح دیتا ہے کہ `core_plate` اور `iran_plate` کیسے کام کرتے ہیں — مکمل loop:
- **Data**: PlateSpec + PlateAlphabet
- **State**: PlateController
- **Interaction**: PlateInputMachine
- **Rendering**: PlateCanvas (two-layer compositing)
- **Validation**: GatedPlateValidator pattern

ہر choice ایک سبب ہے: performance (two FittedBoxes)، usability (gated validation)، extensibility (PlateEntry)۔
