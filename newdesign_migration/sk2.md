# sk2 — The Nocturne token layer

**Model: Sonnet 5 · medium thinking on.** One new file, no UI. Precision matters
more than reasoning depth, but the API shape decides the next twelve prompts.

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `design_ref/MAP.md` first, then the `:root` block and the page `<style>` block
in `design_ref/Plate Gallery.dc.html`.

## Do this

Create **`lib/theme/nocturne.dart`** — the single source of truth for the new
design's values. Nothing else in this prompt.

### Colours — `abstract final class N` (short, because it will be typed a lot)

Transcribe **exactly** these, no eyeballing, no "close enough":

```
bg        #050608     surface   #141926     text      #EAF0FB
divider   white @ 10%
n100 #EAF0FB  n200 #D6E1F1  n300 #C4D0E2  n400 #A5B4C7  n500 #8592A3
n600 #6A7484  n700 #39414F  n800 #232C42  n900 #0E1219
accent #7C5CFF   accent300 #B9A7FF   accent700 #4A3A93
accent800 #2E2560  accent900 #1A1540
```

Add the derived values the design uses repeatedly, as functions not constants:
- `textAt(double opacity)` → `text` with alpha, for the `color-mix(text N%)` idiom.
- `accentAt(double opacity)` → same for accent (hover fills use 12% / 22%).

### Typography — `abstract final class NType`

Families: `archivo` (`'Archivo'`), `mono` (`'MartianMono'`), `serif`
(`'Newsreader'`), `arabic` (`'Vazirmatn'`).

Provide `TextStyle` getters matching the design's scale. Headings are Archivo
**w800**, line-height 1.12, letter-spacing −0.015em:
`h1` 42 · `h2` 32 · `h3` 25 · `h4` 20 · `h5` 16 · `h6` 13.
`h6` is the uppercase eyebrow: +0.08em tracking, `text-transform: uppercase`
(in Flutter that means you uppercase the string at the call site — note this in
the doc comment).

Body: Archivo 15 / 1.55 / w400.

Then the three mono roles the design leans on constantly — give them real names,
because "mono 10px" appears a dozen times in later prompts:
- `railNumber` — MartianMono 10, +0.10em, used for `01` / `02` / `03`.
- `kicker` — MartianMono 11, +0.12em, uppercase, used for `RULES`, `FEATURE`,
  `SCALE`, `COUNTRIES`, `INPUT`, `DETAILS`, `BUILT AGAINST`.
- `specId` — MartianMono 11, +0.02em, used for `ir.car`, `ps.gaza.car2012`.
- `pill` — MartianMono 9.5, +0.10em, uppercase, used for the MOBILE VIEW button
  and the `MOBILE / TABLET / DESKTOP` segmented control.

Add `NType.forScript(String text)` that returns Vazirmatn when the string contains
Arabic-script codepoints, Archivo otherwise. The country blocks (`ایران`,
`اليمن - خصوصي`) need it and nothing currently handles that.

### Space, radii, shadows, motion

```dart
abstract final class NSpace { s1=2.8 s2=5.6 s3=8.4 s4=11.2 s6=16.8 s8=22.4 }
abstract final class NRadius { sm=4 md=8 lg=14 pill=999 }
```

Shadows as `List<BoxShadow>` getters, plus the hairline they carry:
- `sm` → 1px inset-style hairline `white @ 8%`
- `md` → hairline `white @ 10%` + `0 10 26 black @ 70%`
- `lg` → hairline `white @ 14%` + `0 26 60 black @ 80%`

Flutter has no `box-shadow: 0 0 0 1px` spread-as-border idiom that composes with a
blur the way CSS does. Implement the hairline as a `Border.all(width: 1)` helper
`NShadow.hairline(double opacity)` and have each elevation expose **both** the
border and the shadow list, so callers put the border on the `BoxDecoration` and
the shadows alongside. Document that choice in a comment.

### Breakpoints

```dart
abstract final class NBreak { hero=1180  detail=1040  shell=900  stats=760 }
```
These come from the design's own media queries. Do **not** reuse the existing
`kWideBreakpoint = 900` from `lib/screens/gallery/theme/tokens.dart` — that file
is deleted in sk15; `NBreak.shell` replaces it and happens to share its value.

### The fading rule

Nocturne's signature: horizontal rules fade to transparent over the first and last
48px instead of ending cleanly. Provide `NRule` — a `StatelessWidget` painting a
1px `LinearGradient` (`transparent → divider @48px → divider @ width−48px →
transparent`). Every divider in later prompts uses this, **except** box outlines
and in-control separators, which stay solid. Say so in the doc comment.

## Do not

- Do not import `material.dart` colours (`Colors.*`) anywhere in this file.
- Do not create a `ThemeData` here — that is sk3.
- Do not modify any existing file. This prompt adds exactly one file.
- Do not add `google_fonts` or any package.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.
Then write a 20-line `lib/theme/README.md` listing every public name in
`nocturne.dart` with a one-line "use this for…" — later sessions read it instead of
the whole file.

Commit: `newdesign: sk2 nocturne token layer`.
