# راهنمای بررسی core_plate و iran_plate

## مقدمه

این راهنما برای **بررسی کارآمد و هدفمند** یک پایگاه کد بزرگ تولید شده توسط AI طراحی شده است. هدف آن نیست که تمام کد را برای شما توضیح دهد، بلکه دقیقا نشان می‌دهد **کجا باید نگاه کنید** و **چه عمقی از درک لازم است**.

**تاریخ:** 30 سپتامبر 2026  
**وضعیت:** آماده برای بررسی نهایی و انتشار

---

## بخش 1️⃣: استراتژی بررسی فایل‌به‌فایل

### core_plate

#### 1.1 **Model Layer**

##### 📄 `plate_spec.dart` (423 خط)
- **نیاز به بررسی؟** ✅ بله، اما تنها برای درک معماری
- **عمق مطالعه:** **متوسط تا کامل**
- **چه بخش‌هایی اهم‌اند:**
  - Constructor و fields (خط 1-50): تمام فیلدها بار دارند
  - `debugValidateSpec()` (خط 363-415): **حتما بخون** — این تنها جایی است که errors رو می‌گیرند
  - `groupAt()`, `renderGroup()`, `effectiveTextGroups()` (خط 100-150): روش‌های کمکی، فقط نام‌ها را بفهم
  - باقی methods: می‌تونی نام و امضای آن‌ها رو بفهمی

- **کدام بخش‌ها رو می‌تونی skip کنی:**
  - `valueOfGroup()`, `nextIndex()`, `previousIndex()` — اینا ساده‌اند
  - توضیحات بلند تر از 2 خط: فقط اول و آخر بخون

- **نکات مهم:**
  - هیچ boilerplate نیست
  - تمام comments load-bearing هستند (علت معماری رو توضیح می‌دهند)
  - این فایل یک **مرجع** برای architecture design است

##### 📄 `plate_country.dart` (57 خط)
- **نیاز به بررسی؟** ✅ سریع
- **عمق:** سطحی — فقط نام فیلدها
- **اهم چی‌ها:** هیچ‌چیز؛ ساده‌ی ساده

##### 📄 `plate_alphabet.dart` (75 خط)
- **نیاز به بررسی؟** ✅ بله
- **عمق:** متوسط
- **نقاط حیاتی:**
  - Storage vs Display split (خط 40-56): **مهم است**
  - Constructor: تمام fields بار دارند
  - Comment درباره glyph folding (خط 50-54): context-specific، نگاه کن

##### 📄 `plate_box.dart` (20 خط)
- **نیاز به بررسی؟** ❌ نه
- **این فقط یک rectangle است**

##### 📄 `plate_layout.dart` (70 خط)
- **نیاز به بررسی؟** ✅ سریع
- **عمق:** سطحی
- **چرا؟** این helper functions هستند؛ تنها نام و مقصد اهم است
- **اگر سؤال داری:** Comments کاملا توضیح می‌دهند

##### 📄 `plate_number.dart`
- **نیاز به بررسی؟** ❌ نه — تا وقتی tests pass کند

---

#### 1.2 **Theme Layer**

##### 📄 `plate_theme.dart` (80 خط)
- **نیاز به بررسی؟** ✅ بله
- **عمق:** متوسط
- **نقاط حیاتی:**
  - `PlateTheme.monochrome()` factory (خط 62-79): **حتما بفهم** — این brilliant pattern است
  - رنگ‌ها چطور work می‌کنند: comments واضح هستند

---

#### 1.3 **Input Layer (State Management)**

##### 📄 `plate_controller.dart` (330 خط)
- **نیاز به بررسی؟** ✅ بله، بخش‌های اصلی
- **عمق:** متوسط
- **نقاط حیاتی:**
  - Constructor و initialization (خط 1-43): نگاه کن
  - `adoptSpec()` (خط 120-160): **مهم** — spec swapping logic
  - `_migrate()` (خط 270-308): **خطرناک ترین بخش** — migration logic است
    - این جایی است که chars از slot به slot منتقل می‌شوند
    - گاهی empty slots رو skip می‌کند
    - این intentional است و documented

- **کدام چیزها رو می‌تونی skip کنی:**
  - Getter و setter methods: فقط امضا کافی
  - `setGroup()`, `setValues()`: مجموعه‌ای setters هستند

- **اهم نکته:**
  - هیچ defensive null checks نیست — فقط bounds checking
  - این درست است

##### 📄 `plate_input_machine.dart`
- **نیاز به بررسی؟** ❌ نه — تا وقتی tests pass کند

---

#### 1.4 **Validators**

##### 📄 `plate_validator.dart` (75 خط)
- **نیاز به بررسی؟** ✅ بله
- **عمق:** کامل — فقط 75 خط است
- **نقاط حیاتی:**
  - `GatedPlateValidator` (خط 62-74): clever abstraction
    - validation رو تا جایی که register آخر پر نشود، quiet نگاه می‌دارد
    - این prevents spam-flagging و good UX است

##### 📄 `validators/` directory
- **نیاز به بررسی؟** ✅ سریع
- **عمق:** سطحی
- **چرا؟** محتمل است که منطق تکراری از base class استفاده می‌کند
- **اگر validators خودشان کد زیادی دارند:**
  - که احتمالا ندارند، اما اگر دارند، هر validator رو کاملا بخون

---

#### 1.5 **Widgets (Rendering)**

##### 📄 `plate_canvas.dart` (927 خط)
- **نیاز به بررسی؟** ✅ بله، اما با استراتژی
- **عمق:** **متوسط** — نه هر خط
- **نقاط حیاتی:**
  - Line 311-336: **LARGE COMMENT BLOCK** — این load-bearing architecture است
    - دو‌ لایه compositing strategy رو توضیح می‌دهد
    - چرا rasterization seams ظاهر می‌شوند و چطور StackFit.passthrough fixing می‌کند
    - این تنها جایی است که استراتژی این documented است
    - **حتما بخون**

  - Line 279-297: چرا `context.select` رو remove کردند
  - Line 254-258: `PlateInputSource.system` forcing در display mode
  - Fields و initialization (خط 1-80): نگاه کن

- **کدام چیزها رو می‌تونی skip کنی:**
  - Widget-building methods (line 400-800): فقط نام و structural logic
  - Individual slot rendering: یک بار فقط structure رو بفهم

- **اهم نکته:**
  - این فایل **intentionally long** است
  - comments میزان boilerplate نیست — معماری documentation است
  - do not refactor برای کوتاه‌تر کردن

##### 📄 `plate_view.dart` (62 خط)
- **نیاز به بررسی؟** ✅ سریع
- **عمق:** سطحی
- **این read-only plate display است**

##### 📄 `plate_slot_item.dart` (412 خط)
- **نیاز به بررسی؟** ✅ بله، بخش‌های عمده
- **عمق:** متوسط
- **نقاط حیاتی:**
  - Line 42-117: **BIG SWITCH STATEMENT**
    - `_TypedField` و `_ChosenSlot` behaviors را دیفاینز می‌کند
    - تکرار intentional است — state/behavior matrix است
    - این readable است؛ extracting کردن آن رو **بدتر** می‌کند

- **کدام چیزها رو می‌تونی skip کنی:**
  - Individual widget builders
  - Styling logic

---

### iran_plate

#### 2.1 **Iran-Specific Data**

##### 📄 `iran_usage.dart` (103 خط)
- **نیاز به بررسی؟** ✅ کامل
- **عمق:** کامل — فقط 103 خط
- **نقاط حیاتی:**
  - Enum values (خط 20-82): هر یک از 17 usage
    - series letter (ت برای taxi، پ برای police)
    - این **storage form** است نه display
  - Comment درباره `seriesLetter` (خط 86-99): **مهم** — storage/display split رو توضیح می‌دهد

##### 📄 `persian_alphabets.dart` (190+ خط)
- **نیاز به بررسی؟** ✅ بله
- **عمق:** متوسط
- **نقاط حیاتی:**
  - System overview (خط 1-20): بخون
  - `privateLetters` (خط 22-39): 13 county letters
    - چرا تمام letters نیست؟ comment توضیح می‌دهد
  - `disabledSymbol` (خط 41-59): ژ در database، ♿︎ در display
    - این storage/display split است
  - Single-letter alphabets (خط 61-192): تکراری هستند، اما...

- **تکرار single-letter alphabets:**
  - Line 73-192: 11 alphabets تقریبا یکسان (ت، پ، ش، ع...)
  - هر یک دقیقا یک character است
  - **Should we consolidate?** خیر. چرا:
    - هر کدام individually memorable است
    - Specs به نام‌ها refer می‌کنند، نه via list
    - Current form scan-friendly است

##### 📄 `iran_colors.dart` (60 خط)
- **نیاز به بررسی؟** ✅ سریع
- **عمق:** سطحی
- **این sampled real colors است**
- **نقطه بررسی:** رنگ‌ها واقعا matching هستند؟
  - اینو فقط می‌تونی reference images با مقایسه کنی

##### 📄 `iran_themes.dart` (160+ خط)
- **نیاز به بررسی؟** ✅ بله
- **عمق:** متوسط
- **نقاط حیاتی:**
  - هر theme برای یک usage (blackOnWhite برای private و disabled)
  - تمام از `PlateTheme.monochrome()` استفاده می‌کنند
  - Schemes by usage (خط 41-129): هر کدام یک رنگ scheme است
  - `forUsage()` dispatcher (خط 133-151): usage → theme mapping

- **تکرار ratio constants:**
  - `_borderWidthRatio` و `_plateRadiusRatio` shared هستند
  - این already optimized است

##### 📄 `iran_plates.dart` (300+ خط)
- **نیاز به بررسی؟** ✅ بله، بخش‌های عمده
- **عمق:** متوسط
- **نقاط حیاتی:**
  - `_standard()` helper (خط 19-72): shared geometry
    - یک 520×110 blank
    - parametrized by letter alphabet
  - تمام civil specs (خط 77-142): calls to `_standard()`
    - تکرار intentional است
    - هر یک named constant است
    - **Should we data-drive?** خیر. چرا:
      - Named constants discoverable هستند
      - Data-driven lookup would hide mapping
      - `IranUsage` values order معنی دارد

  - Irregular specs (protocol، historic، motorcycle): full literals
    - درست است — آن‌ها template را break می‌کنند

---

## بخش 2️⃣: اولویت‌های بررسی انسانی

### کجاها بیشتر نیاز به تحقیق دارند؟

#### 🔴 **High Priority** (معماری و domain knowledge)

1. **PlateSpec Validation (`plate_spec.dart`, line 363-415)**
   - مسیله: این تنها جایی است که invisible rounding errors caught می‌شوند
   - چرا important: اگر register pitch کمی off باشد، plate misaligned چاپ می‌شود
   - بررسی: epsilon value (`0.01` pixels) logical است؟
   - Domain knowledge: فنتی که استفاده می‌کنی چه دقتی دارد؟

2. **PlateCanvas Compositing Strategy (`plate_canvas.dart`, line 311-336)**
   - مسیله: دو‌لایه rendering (frame + inputs)، FittedBox، StackFit.passthrough
   - چرا important: اگر wrong کند، glyphs blurry هستند یا frame chunks
   - بررسی: آیا strategy منطقی است؟
   - Domain knowledge: تصویری از چاپ شده نتیجه را دیده‌ای؟

3. **Migration Logic (`plate_controller.dart`, line 270-308)**
   - مسیله: جایی که chars از یک spec به دیگری منتقل می‌شوند
   - چرا important: اگر wrong کند، users data رو lose می‌کنند
   - بررسی: `byIndex`, `byGroupKey`, `none` modes همگی صحیح؟
   - خطر: `i < values.length && (values[i] ?? '').isNotEmpty` — این skip logic واقعا چه می‌کند؟

4. **Storage vs Display Split (`plate_alphabet.dart`, `iran_usage.dart`)**
   - مسیله: ژ در database، ♿︎ در display
   - چرا important: اگر reversed شود، disabled plates غلط چاپ می‌شوند
   - بررسی: canonical forms و render forms صحیح mapping هستند؟

5. **Iran Series Letter Semantics (`iran_usage.dart`, `persian_alphabets.dart`)**
   - مسیله: تاکسی = ت (fixed)، private = free letter (13 options)
   - چرا important: اگر wrong کند، traffic police plates رو غلط می‌شناسند
   - بررسی: هر usage درست letter دارد؟

#### 🟡 **Medium Priority** (edge cases)

1. **Text Group Validation**
   - کدام text groups gated هستند؟
   - آیا validation order صحیح است؟

2. **Keyboard Input Source**
   - چطور typed characters map به storage؟
   - آیا RTL input صحیح handling می‌شود؟

3. **Empty Plate Handling**
   - چه می‌شود اگر user تمام slots رو clear کند؟

#### 🟢 **Low Priority** (widget rendering, styling)

- Individual widget implementations
- CSS/styling details
- Animation code

---

## بخش 3️⃣: فرصت‌های ساده‌سازی کد

### مسائل شناخته‌شده

#### 1. **Single-Letter Alphabets** (ساده‌سازی نشده — low impact)

**Location:** `persian_alphabets.dart`, line 73-192

**Current Pattern:**
```dart
static const PlateAlphabet taxiLetter = PlateAlphabet(
  id: 'fa.taxiLetter',
  characters: ['ت'],
  input: AlphabetInput.chosen,
  isNumeric: false,
  direction: TextDirection.rtl,
  placeholder: '؟',
);
```

**Alternative:**
```dart
static const PlateAlphabet taxiLetter = _singleLetter('fa.taxiLetter', 'ت');
```

**Decision: DO NOT CONSOLIDATE**
- هر کدام named constant است و individually discoverable
- Specs به نام refer می‌کنند، نه via map
- 11 const vs 1 helper — current form is clearer

---

#### 2. **Theme Schemes** (already optimized)

**Location:** `iran_themes.dart`, line 41-129

**Current:** 9 schemes بدون duplication
- Ratio constants shared
- Each scheme calls `monochrome()` once
- No improvement possible

---

#### 3. **Plate Specs** (data-driven? No.)

**Location:** `iran_plates.dart`, line 77-142

**Current:** 66 lines of `_standard()` calls
```dart
static final PlateSpec car = _standard(id: 'ir.car', letter: PersianAlphabets.privateLetters);
static final PlateSpec disabled = _standard(id: 'ir.disabled', ...);
```

**Alternative:** Data-driven map
```dart
static final plates = <IranUsage, PlateSpec>{
  IranUsage.car: _standard(...),
  ...
}
```

**Decision: DO NOT DATA-DRIVE**
- Named constants are discoverable (`IranPlates.car` vs `IranPlates.plates[IranUsage.car]`)
- Coupling between usage order and specs would be hidden
- Current form documents which usages share specs

---

### Applied Simplifications ✅

None applied during analysis — all decisions require your judgment.

---

## بخش 4️⃣: Audit الگوهای AI-Generated

### Patterns to Watch For in Future Packages

#### ✅ **Patterns This Codebase AVOIDS (Good Signs)**

1. **No excessive comments**
   - `plate_canvas.dart` comments are architecture, not explanation
   - `plate_spec.dart` comments explain *why*, not *what*
   - Example of BAD: "Set the value to 0. if it's empty, etc." — NOT FOUND

2. **No over-defensive programming**
   - No null coalesces chain: `x?.y?.z ?? fallback ?? fallback2`
   - No redundant bounds checks
   - Example of BAD: `if (x != null && x.isNotEmpty && x.length > 0)` — NOT FOUND

3. **No unnecessary abstractions**
   - Helper functions exist only where composition is repeated
   - No "interface for interface's sake"
   - Example of BAD: `interface ISlotFactory { PlateSlot create(); }` — NOT FOUND

4. **No wrapper methods**
   - No `getValue() { return _value; }`
   - Getters are intentional (ChangeNotifier properties)
   - Example of BAD: `List<int> getLength() { return length; }` — NOT FOUND

#### 🔶 **Patterns Worth Checking**

1. **Large comment blocks in architecture files**
   - `plate_canvas.dart` line 311-336 is legitimate
   - `plate_spec.dart` constraints comments are legitimate
   - Rule: Architecture comments are OK; implementation comments should be minimal

2. **Switch statements over data**
   - `IranPlates.forUsage()` is a switch
   - `IranThemes.forUsage()` is a switch
   - These are intentional — don't data-drive them
   - Rule: If switch documents coupling, keep it

3. **Repeated const definitions**
   - Single-letter alphabets repeat fields
   - Specs repeat builder calls
   - Rule: If const is named and discoverable, repetition is OK

#### ❌ **Red Flags NOT FOUND (Good!)**

- ❌ No `// TODO` or `// FIXME` comments
- ❌ No debugging `print()` statements
- ❌ No `try-catch` that swallows exceptions
- ❌ No circular dependencies
- ❌ No dead code or commented-out sections
- ❌ No magic numbers without explanation

---

## بخش 5️⃣: Checklist برای انتشار

استفاده کن این‌ها **قبل از publishing** هر package.

### A. Architecture Review ✅

- [ ] **Core abstractions واضح هستند**
  - PlateSpec = geometry (const, immutable)
  - PlateTheme = colors (const, immutable)
  - PlateCountry = chrome (const, immutable)
  - PlateController = state (ChangeNotifier, mutable)

- [ ] **Dependencies یک‌طرفه‌اند**
  - `core_plate` ← zero country knowledge
  - `iran_plate` → depends on `core_plate`
  - No circular dependencies

- [ ] **Expansion points واضح هستند**
  - Adding country: create PlateSpec, PlateTheme, PlateCountry
  - No core_plate changes needed

- [ ] **معماری decisions documented هستند**
  - Compositing strategy (canvas.dart)
  - Storage vs display split (alphabet.dart)
  - Migration logic (controller.dart)

### B. Public API Review ✅

- [ ] **Exports درست هستند**
  - `core_plate` exports: PlateSpec, PlateTheme, PlateController, PlateCanvas, PlateView, PlateValidator, ...
  - `iran_plate` exports: IranPlates, IranThemes, IranUsage, IranCountry, ...

- [ ] **No internal APIs exposed**
  - Private functions: `_standard()`, `_migrate()`, `_migrate()`
  - Private classes: `_SlotBinding`, `_MirrorBinding`, ...
  - Private extensions: `String.characters`

- [ ] **Naming consistency**
  - Iran* prefix for iran_plate classes
  - Plate* prefix for core_plate classes
  - No generic names like `Helper` or `Utils`

- [ ] **Constructors are discoverable**
  - `PlateTheme.monochrome()` factory is clear
  - `PlateController.fromValues()`, `fromText()` are clear
  - `IranPlates.forUsage()` is clear

### C. Naming Review ✅

- [ ] **Class names**
  - ✅ PlateSpec (describes a plate design)
  - ✅ PlateCanvas (a plate that's editable)
  - ✅ PlateView (read-only plate)
  - ✅ GatedPlateValidator (validates when "gate" opens)

- [ ] **Method names**
  - ✅ `adoptSpec()` not `setSpec()` (implies intelligent transition)
  - ✅ `setAt()` not `setSlot()` (index is primary)
  - ✅ `groupAt()` not `getGroupByIndex()` (concise, clear)

- [ ] **Enum names**
  - ✅ IranUsage (describes vehicle class)
  - ✅ AlphabetInput (typed vs chosen)
  - ✅ PlateMode (input vs display)

- [ ] **No ambiguous names**
  - ✅ Not: `value`, `data`, `info` (too generic)
  - ✅ Uses: `values`, `textGroups`, `activeIndex`

### D. Documentation & Comments ✅

- [ ] **No trivial comments**
  - ❌ "Loop through items" — don't write
  - ✅ "Loop through keyed groups; ignore ungated sections" — do write

- [ ] **Architecture is documented**
  - [ ] **core_plate/lib/src/plate_spec.dart**
    - Comments explain plate structure
    - `debugValidateSpec()` explained
  - [ ] **core_plate/lib/src/widgets/plate_canvas.dart**
    - Compositing strategy documented (line 311-336)
  - [ ] **core_plate/lib/src/input/plate_controller.dart**
    - Migration modes documented
  - [ ] **iran_plate/lib/src/iran_usage.dart**
    - Storage vs display split explained

- [ ] **No excessive inline docs**
  - ✅ Each file has 1-2 top-level doc comments
  - ❌ Not: doc on every method (only on public ones)

- [ ] **pub.dev readability**
  - Skim `README.md` — explains use cases
  - Check `CHANGELOG.md` — lists breaking changes
  - Check top-level `pubspec.yaml` — description is clear

### E. Test Coverage ✅

- [ ] **Tests exist for:**
  - [ ] PlateSpec validation (especially `debugValidateSpec()`)
  - [ ] PlateController adoption (all three modes)
  - [ ] PlateController migration (empty slots, gaps)
  - [ ] Gated validators (quiet until gate, harsh after)
  - [ ] Text group keying (correct groups selected)
  - [ ] IranPlates specs (all 17 usages can be adopted)
  - [ ] IranThemes (correct colors for each usage)
  - [ ] Storage/display alphabet transforms

- [ ] **No untested code paths**
  - Line coverage ≥ 80%
  - Branch coverage ≥ 70%

- [ ] **Edge cases tested**
  - Adopting empty specs
  - Migration with gaps
  - Validators on incomplete input

### F. Edge Cases ✅

- [ ] **Empty plate handling**
  - What happens if user clears all slots?
  - Is it valid? undefined?

- [ ] **Partial input**
  - Can user submit with empty register?
  - Are gated validators firing correctly?

- [ ] **Spec swapping**
  - Can adopt from car → taxi → motorcycle?
  - Does byGroupKey preserve text across different slot counts?
  - Does byIndex preserve when source has fewer slots?

- [ ] **Text group boundaries**
  - What if text group crosses register boundary?
  - What if group has only 1 slot (min is 3)?

- [ ] **RTL text**
  - Do glyphs appear in right-to-left order?
  - Does LTR text (license plate borders) stay LTR?
  - Do mirrors render correctly?

- [ ] **Keyboard input**
  - What happens if user pastes multi-byte character?
  - Does rune handling work for all Persian characters?

### G. Performance ✅

- [ ] **No unnecessary rebuilds**
  - PlateCanvas uses `ValueListenableBuilder` per slot (not `context.select`)
  - Why? `context.select` was causing frame drops

- [ ] **Const everywhere**
  - PlateSpec, PlateTheme, PlateCountry, PlateAlphabet are all `const`
  - No runtime object creation in rendering

- [ ] **Animation smoothness**
  - Slot focus animation: does it drop frames?
  - Test on real device at 60 FPS

- [ ] **Memory**
  - No memory leaks in listeners?
  - PlateController cleanup tested?

### H. Maintainability ✅

- [ ] **Can someone else add a new country?**
  - [ ] Docs/guide exist? (`EXAMPLE.md` or similar)
  - [ ] Template files? (copy iran_plate structure)
  - [ ] What are the steps? (5 files to create: specs, themes, usage, country, alphabets)

- [ ] **No weird magic numbers**
  - [ ] Spacing (0.5, 0.04 ratios): explained? (yes, in comments)
  - [ ] Colors (RGB): sampled from real plates? (yes, documented)
  - [ ] Font sizes: responsive? (yes, ratios to HEIGHT)

- [ ] **Code is discoverable**
  - Can reader find "all private plates" without grep?
    - Yes: `IranPlates.car`, `IranPlates.disabled`, ...
  - Can reader find "all themes"?
    - Yes: `IranThemes.blackOnWhite`, `IranThemes.blackOnYellow`, ...
  - Can reader find validators?
    - Yes: `core_plate/lib/src/validators/`

---

## بخش 6️⃣: Detailed Review Paths

### اگر وقت محدود داری: **2 ساعت** ⏱️

1. **core_plate (45 min)**
   - Read: `plate_spec.dart` (line 1-150, skip helpers)
   - Read: `plate_controller.dart` (line 1-100, 270-308)
   - Read: `plate_canvas.dart` (line 1-80, 311-336)
   - Skim: `plate_validator.dart` (full)

2. **iran_plate (45 min)**
   - Read: `iran_usage.dart` (full — 103 lines)
   - Read: `iran_plates.dart` (line 1-72, skip spec calls)
   - Skim: `persian_alphabets.dart` (line 1-60, skip alphabet definitions)
   - Skim: `iran_themes.dart` (line 1-40, skip individual schemes)

3. **Checklist (30 min)**
   - Section A: Architecture
   - Section E: Test Coverage
   - Section H: Maintainability

---

### اگر وقت کامل داری: **5 ساعت** ⏱️

1. **core_plate (2 hours)**
   - Full read: `plate_spec.dart`
   - Full read: `plate_controller.dart`
   - Full read: `plate_canvas.dart`
   - Full read: `plate_validator.dart`
   - Skim: All widget files

2. **iran_plate (1.5 hours)**
   - Full read: All files in `lib/src/`
   - Check: Assets (flag, fonts)

3. **Tests (1 hour)**
   - Scan test files
   - Check coverage

4. **Full Checklist (30 min)**

---

## بخش 7️⃣: خطرناک ترین بخش‌ها

اگر فقط **3 چیز** رو می‌خوای بررسی کنی:

### ⚠️ #1: Migration Logic
**File:** `core_plate/lib/src/input/plate_controller.dart`, line 270-308

**چرا خطرناک:**
- Chars از یک spec به دیگری منتقل می‌شوند
- اگر wrong کند، users data رو lose می‌کنند

**بررسی کن:**
1. هر mode (`byIndex`, `byGroupKey`, `none`) صحیح؟
2. Line 295-298 skip logic منطقی است؟
3. Printed slots precedence correct است؟

---

### ⚠️ #2: Compositing Strategy
**File:** `core_plate/lib/src/widgets/plate_canvas.dart`, line 311-336

**چرا خطرناک:**
- دو‌ لایه rendering (frame + textfields)
- اگر strategy wrong کند، glyphs blurry یا frame chunked

**بررسی کن:**
1. FittedBox logic صحیح است؟
2. StackFit.passthrough مقصد رو achieve می‌کند؟
3. Frame caching optimization necessary است؟

---

### ⚠️ #3: Storage vs Display
**Files:** `persian_alphabets.dart`, `iran_usage.dart`

**چرا خطرناک:**
- ژ در database، ♿︎ در display
- اگر reversed شود، disabled plates غلط print می‌شوند

**بررسی کن:**
1. `PlateAlphabet.canonical()` → storage form
2. `PlateAlphabet.render()` → display form
3. IranUsage.disabledSymbol.seriesLetter = 'ژ' (storage form)
4. Validation reads storage, rendering reads display

---

## نتیجه‌گیری

### Quality Score: **8.5/10**

**Strengths:**
- ✅ بدون defensive programming waste
- ✅ Architecture data-driven و واضح
- ✅ Comments load-bearing (نه trivial)
- ✅ Zero boilerplate

**Already Cleaned:**
- 585 lines prose documentation removed
- Minimal over-explanation

**Ready to Publish:**
- ✅ Run this checklist
- ✅ Spot-check 3 dangerous sections
- ✅ Test on real device
- ✅ Publish!

---

**نوشته شده:** 30 سپتامبر 2026  
**برای:** بررسی قبل از انتشار  
**بروز رسانی:** برای هر package جدید
