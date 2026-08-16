# Plate Number Upgrade — Codebase Architecture

## File Map: lib/

### Core Data Models
- `lib/model/plate_number.dart` — `PlateNumber` class (values: List, valueTypes: List) and `PlateType` enum (irCar, irBicycle)
- `lib/plate_number.dart` — Library entrypoint stub (unused Calculator class)
- `lib/constants.dart` — `persianCarPlateLetters` array (16 Persian letters for car plate)
- `lib/tools.dart` — Extension methods on `String` (isDigit) and `PlateNumber` (isCompleted, isEmpty)

### Bloc State Management
- `lib/bloc/plate_card_bloc.dart` — `PlateCardBloc` main event handler; manages plate state via `ValueIsChanged`, `RemovePlateCard`, `TypeIsChanged`
- `lib/bloc/plate_card_event.dart` — `PlateCardEvent`, `ValueIsChanged(index, value)`, `RemovePlateCard`, `TypeIsChanged(type)`
- `lib/bloc/plate_card_state.dart` — `PlateCardState` with factory `emptyPlateCardState()` that hardcodes plate structure per type

### Graph Bloc (Unused in Plate UI)
- `lib/features/plate/bloc/graph_bloc.dart` — `GraphBloc` managing edge relationships (RelationType: causes, kindOf, symmetric)
- `lib/features/plate/bloc/graph_event.dart` — `RelationDirectionFlipped` event
- `lib/features/plate/bloc/graph_state.dart` — `GraphState` with edges map and `OrderedPair` class

### Car Plate UI
- `lib/car_plate/car_plate_number.dart` — `CarPlateNumber` stateful widget; builds the editable car plate UI with 8 input positions
- `lib/car_plate/letter_picker.dart` — `LetterPicker` using CupertinoPicker for letter selection
- `lib/car_plate/index.dart` — Barrel export file

### Bicycle Plate UI
- `lib/bicycle_plate/bicycle_plate_number.dart` — `BicyclePlateNumber` stateful widget; builds the editable bicycle plate UI with 8 input positions
- `lib/bicycle_plate/index.dart` — Barrel export file

### Widget Library
- `lib/widgets/plate_frame.dart` — `PlateFrame` border and background container; uses `SpecialClipper` and dynamic border color
- `lib/widgets/plate_items.dart` — `IntegerPlateItem` (digit input field) and `StringPlateItem` (letter button); defines `getPlateCardElementWidth()` and `getPlateCardElementHeight()`
- `lib/widgets/digit_row.dart` — `DigitRow` simple Row wrapper with gap parameter
- `lib/widgets/remove_button.dart` — `RemoveButton` that emits `RemovePlateCard` event
- `lib/widgets/show_plate.dart` — `ShowPlate` read-only display widget; branches to `IrCarShow` or `IrBicycleShow` helpers
- `lib/widgets/special_clipper.dart` — `SpecialClipper` custom clipper with hardcoded Radius.circular(12)

### Showcase Theme & Widgets (Designer Spec Poster)
- `lib/showcase/theme/poster_tokens.dart` — `PosterTokens` design tokens (colors, text styles, fonts); accent = Color(0xFF6EE7B7) teal
- `lib/showcase/widgets/annotation_callout.dart` — `AnnotationCallout`, `ConnectorLine`, `CalloutWithConnector` for spec poster labels
- `lib/showcase/widgets/corner_brackets.dart` — `CornerBrackets` custom paint four L-shaped corner frames (28px inset, 46px arm)
- `lib/showcase/widgets/grid_backdrop.dart` — `GridBackdrop` with gradient background and grid pattern (72px cell size)
- `lib/showcase/widgets/poster_header.dart` — `PosterHeader` masthead with name and role
- `lib/showcase/widgets/poster_footer.dart` — `PosterFooter` with tech chips and credentials
- `lib/showcase/widgets/tech_chip.dart` — `TechChip` bordered label widget

---

## Visual Styling

### Color Palette
All colors are passed in as constructor parameters (no hardcoded palette in plate widgets):
- `activeColor` — color when input is complete
- `inactiveColor` — color when input is empty or in progress
- `backgroundColor` — plate background

Showcase colors live in `lib/showcase/theme/poster_tokens.dart`:
- `PosterTokens.bg` = Color(0xFF05080B) (dark background)
- `PosterTokens.bgTop` = Color(0xFF070B10) (gradient start)
- `PosterTokens.accent` = Color(0xFF6EE7B7) (teal)
- `PosterTokens.titleColor` = Color(0xFFFFFFFF) (white text)
- `PosterTokens.bodyColor` = Color(0xFF97A3AF) (gray text)
- `PosterTokens.hairline` = Color(0x0FFFFFFF) (6% white)

### Borders & Radius
- `PlateFrame` (lib/widgets/plate_frame.dart:38) — `BorderRadius.circular(12)` hardcoded
- `SpecialClipper` (lib/widgets/special_clipper.dart:6) — `Radius.circular(12)` hardcoded
- `IntegerPlateItem` default borderRadius (lib/widgets/plate_items.dart:117) — `BorderRadius.circular(12)` if not overridden
- `StringPlateItem` default borderRadius (lib/widgets/plate_items.dart:45) — `BorderRadius.circular(8)` if not overridden
- `CornerBrackets` (lib/showcase/widgets/corner_brackets.dart:24-25) — `_inset = 28.0`, `_arm = 46.0`
- `TechChip` (lib/showcase/widgets/tech_chip.dart:20) — `BorderRadius.circular(2)`

### Spacing & Sizing
All managed via `spacingScale` parameter (default 6) passed to car/bicycle plate widgets:
- Car plate (lib/car_plate/car_plate_number.dart:122-131) — padding `vertical: spacingScale * 3`, `horizontal: spacingScale`
- Bicycle plate (lib/bicycle_plate/bicycle_plate_number.dart:85-88) — padding `vertical: spacingScale * 2.5`, `horizontal: spacingScale`
- Border width (lib/car_plate/car_plate_number.dart:131, lib/bicycle_plate/bicycle_plate_number.dart:94) — `spacingScale / 1.5` and `spacingScale`
- Divider width/thickness (lib/car_plate/car_plate_number.dart:172-173) — `spacingScale / 3`
- Gaps between digits (lib/car_plate/car_plate_number.dart:147, lib/bicycle_plate/bicycle_plate_number.dart:107) — `spacingScale / 1.5` and `spacingScale * 2`
- Grid backdrop cell size (lib/showcase/widgets/grid_backdrop.dart:32) — hardcoded `_cell = 72.0`

### Text Styles
Passed as optional parameters with no defaults in plate widgets:
- `numberTextStyle` — for digit input
- `letterTextStyle` — for letter in car plate
- `chooseLetterTextStyle` — for letter picker
- Showcase text styles defined in `PosterTokens` (lib/showcase/theme/poster_tokens.dart:29-68)

---

## MediaQuery Usage for Sizing

**File: lib/widgets/plate_items.dart**

Two sizing functions compute input element dimensions based on screen size:

```dart
double getPlateCardElementWidth(BuildContext context) {
  return MediaQuery.of(context).size.width * 0.087;  // line 155
}

double getPlateCardElementHeight(BuildContext context) {
  return MediaQuery.of(context).size.height * 0.065;  // line 159
}
```

These are used in:
- `IntegerPlateItem` (line 100-102) — SizedBox width/height
- `StringPlateItem` (line 33-35) — SizedBox width/height for letter button

**No other MediaQuery calls exist in lib/** — all other sizing is via passed parameters or hardcoded dimensions.

---

## PlateCardBloc Index Mapping to Visual Positions

### Car Plate Structure (PlateType.irCar)

Empty state defined in `PlateCardState.emptyPlateCardState()` (lib/bloc/plate_card_state.dart:23-39):
```dart
values: [null, null, null, null, null, null, null, null]  // 8 positions
valueTypes: [Int, Int, SelectableString, Int, Int, Int, Int, Int]  // position 2 is letter
```

**Visual layout (lib/car_plate/car_plate_number.dart, RTL Directionality):**

From left to right in the UI:
1. Country name section (Iran)
2. Last two digits
3. Divider
4. Three digits + letter + two more digits

**Position-to-visual mapping:**
- Index 0 — 1st digit (far right, entered first)
- Index 1 — 2nd digit
- Index 2 — **Letter (SelectableString, center of plate)**
- Index 3 — 3rd digit
- Index 4 — 4th digit
- Index 5 — 5th digit
- Index 6 — 6th digit (upper section, accessed via focusNodes[6])
- Index 7 — 7th digit (upper section, accessed via focusNodes[6])

**UI order (DigitRow rows in lib/car_plate/car_plate_number.dart:143-227):**
- Upper right: indices [6, 5] (entered last, shown top)
- Lower middle: indices [4, 3, 2=letter, 1, 0] (entered during main input flow)

### Bicycle Plate Structure (PlateType.irBicycle)

Empty state (lib/bloc/plate_card_state.dart:41-48):
```dart
values: [null, null, null, null, null, null, null, null]  // 8 positions
valueTypes: [Int, Int, Int, Int, Int, Int, Int, Int]  // all digits
```

**Visual layout (lib/bicycle_plate/bicycle_plate_number.dart, RTL Directionality):**

From top to bottom:
- Top row: indices [2, 1, 0] (3 digits)
- Bottom row: indices [7, 6, 5, 4, 3] (5 digits)

**Position-to-visual mapping:**
- Index 0 — top row, rightmost
- Index 1 — top row, middle
- Index 2 — top row, leftmost
- Index 3 — bottom row, rightmost (wrapped in BlocBuilder)
- Index 4 — bottom row, center-right
- Index 5 — bottom row, center
- Index 6 — bottom row, center-left
- Index 7 — bottom row, leftmost

**Focus flow (lib/bicycle_plate/bicycle_plate_number.dart:109-152):**
Entry: [2→1→0] then [3→4→5→6→7]

---

## Platform Compatibility Issues

### dart:ffi Import — **BREAKS ON WEB AND DESKTOP**

**Affected files:**

1. **lib/bloc/plate_card_bloc.dart (line 1)**
   ```dart
   import 'dart:ffi';
   ```
   - Used implicitly to access `ffi.Int` type alias in `PlateCardState.emptyPlateCardState()` (line 28, 35)
   - `dart:ffi` is **NOT available on Flutter Web** (web does not support FFI)
   - `dart:ffi` works on mobile/desktop but not web

2. **lib/car_plate/car_plate_number.dart (line 1)**
   ```dart
   import 'dart:ffi' as ffi;
   ```
   - Used in `_CarPlateNumberState.initState()` (line 62) to check `if (valueType == ffi.Int)`
   - Same web incompatibility issue

### Mitigation Required
To support Flutter Web or Desktop:
1. Remove `dart:ffi` imports
2. Replace `ffi.Int` and `Int` type checks with a custom enum or marker class that represents integer types
3. Define `class IntType extends SelectableString {}` in `lib/model/plate_number.dart` and use `IntType()` instead of `ffi.Int`
4. Update all valueTypes lists in `PlateCardState.emptyPlateCardState()` to use `IntType()` instead of `Int`
5. Update type checks in `_CarPlateNumberState.initState()` to check `if (valueType is IntType)`

### No Other Platform Issues
- No `dart:html` (web-only)
- No `dart:io` (mobile/desktop-only file access)
- No `dart:async` FFI-specific code
- All Flutter widgets are cross-platform compatible
- All custom painters (CornerBrackets, GridBackdrop) use Canvas API (web-compatible)
- CupertinoPicker in LetterPicker works on web (rendered via Material fallback or Cupertino)

---

## Summary Table

| Concern | Location | Details |
|---------|----------|---------|
| **Visual Styling** | Constructor params (colors), spacingScale (layout), hardcoded radii (12px, 8px) | Decentralized—passed at widget instantiation |
| **Color Tokens** | `lib/showcase/theme/poster_tokens.dart` | Only for showcase theme; plate widgets use params |
| **MediaQuery** | `lib/widgets/plate_items.dart:154-160` | 2 functions for digit/letter box sizing based on screen |
| **Car Index Map** | `lib/bloc/plate_card_state.dart:26-36` + `lib/car_plate/car_plate_number.dart:143-227` | 8-position array; index 2 is letter (SelectableString) |
| **Bicycle Index Map** | `lib/bloc/plate_card_state.dart:43-47` + `lib/bicycle_plate/bicycle_plate_number.dart:106-153` | 8-position array; all Int; 3-digit top row + 5-digit bottom row |
| **Web/Desktop Blocker** | `lib/bloc/plate_card_bloc.dart:1` + `lib/car_plate/car_plate_number.dart:1` | `dart:ffi` import breaks web; use custom IntType enum instead |

---

## Tokens

`lib/theme/plate_theme.dart` — `PlateTheme` immutable data class (`PlateTheme.standard()`). Plate chrome colours are fixed and must never be tinted by a caller's accent; only `activeColor`/`inactiveColor` (input-mode field outlines) are meant to vary.

### Colours
| Field | Standard value | Role |
|-------|----------------|------|
| `plateBackground` | `Color(0xFFFFFFFF)` | Plate background |
| `plateBorder` | `Color(0xFF111111)` | Outer plate edge |
| `ink` | `Color(0xFF0A0A0A)` | Digits / letter |
| `dividerColor` | `Color(0xFF111111)` | Vertical rule left of province code |
| `panelBlue` | `Color(0xFF16479D)` | I.R. IRAN block |
| `panelText` | `Color(0xFFFFFFFF)` | Text on the panel |
| `flagGreen` | `Color(0xFF239F40)` | Flag stripe |
| `flagWhite` | `Color(0xFFFFFFFF)` | Flag stripe |
| `flagRed` | `Color(0xFFDA0000)` | Flag stripe |
| `screwColor` | `Color(0xFFB9BDC2)` | Mounting screw heads |
| `activeColor` | `Color(0xFF0A0A0A)` (ink) | Completed input outline (input-mode only) |
| `inactiveColor` | `Color(0x66666666)` (40% grey) | Empty/in-progress input outline (input-mode only) |

### Ratios (fraction of plate HEIGHT) & aspects
| Field | Standard value |
|-------|----------------|
| `borderWidthRatio` | `0.04` |
| `plateRadiusRatio` | `0.09` |
| `panelWidthRatio` | `0.16` |
| `dividerWidthRatio` | `0.02` |
| `digitGapRatio` | `0.06` |
| `carAspect` | `520 / 110` |
| `motorcycleAspect` | `175 / 110` |

### API
`const` constructor · `copyWith(...)` · `static PlateTheme lerp(a, b, t)` · `static PlateTheme of(BuildContext)` (falls back to `PlateTheme.standard()`) · `PlateThemeScope` InheritedWidget provider.
