# sk6 — The Showcase hero block

**Model: Opus 5 · medium thinking on.** The hero is the page everyone judges the
migration by, and it is the densest typography in the design.

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/theme/README.md`, `lib/screens/showcase_screen.dart`, and the Showcase
`<section>` in `design_ref/Plate Gallery.dc.html` (offsets in `MAP.md`). Look at
`design_ref/uploads/*.png` for the rendered result.

## What the design specifies

The Showcase section is `min-height: 100vh`, `grid-template-rows: 1fr auto` — hero
on top, stat band pinned to the bottom (the stat band is sk7; leave a slot for it).

The hero (`.pg-hero`) is a two-column grid, left text / right device stage,
`padding: 72px 72px 48px 72px`-ish — read the exact values.

**Left column, top to bottom:**
1. A masthead line: a short solid accent-less rule (~40×1px, `n700`) then
   `ARAD BEYRANVAND — SOLE AUTHOR` in MartianMono, +0.12em, uppercase, `n500`,
   with `SOLE AUTHOR` at a lighter weight/opacity. Read the exact markup.
2. **`Plate input` / `for the road.`** — this is the one place the design uses
   **Newsreader**, not Archivo. Serif, very large (≈76px at 1440, dropping to 56px
   under the 1180 breakpoint), line-height ≈0.98, `n100`. The trailing period is
   part of the text.
3. A body paragraph in Archivo 17–18/1.6, `n400`:
   *"One widget, one const swapped: licence-plate fields that look and behave like
   the real thing. Iranian, Palestinian, Yemeni, Lebanese and German plates ship
   today, for cars and for motorbikes."*
   Use the exact string from the design file, not this paraphrase.
4. A button row, `gap: 12px`:
   - `Open the archive` — DS `.btn-primary`: transparent fill, `1px accent`
     border, `accent` text, radius `md`, hover fill `accent @ 12%`, active @ 22%.
     Navigates to `/discover`.
   - `Read the docs` — DS `.btn-secondary`: `1px divider` border, `text` colour,
     hover fill `text @ 7%`. Opens the docs URL the current showcase already uses
     (find it in `lib/poster/chrome/poster_links.dart`; do not invent one).
5. A row containing the **MOBILE / TABLET / DESKTOP** segmented control and the
   **IRAN MADE · OPEN SOURCE** pill.
   - Segmented: DS `.seg` — one rounded `md` box, `1px divider`, children split by
     `1px divider`, each `padding: 7px 12px`, MartianMono `pill` style, uppercase.
     Selected option: `accent` text plus a `1px accent` inset ring on that cell
     only. Unselected hover: fill `text @ 7%`.
   - Pill: a small `accent` dot then `IRAN MADE · OPEN SOURCE`, MartianMono,
     uppercase, inside a `radius: 999` box with `1px n800`.
   The segmented control **drives the device stage** — it is the existing device
   cycle. Wire it to whatever `lib/showcase/device_cycle.dart` already exposes;
   selecting an option must stop the auto-cycle and pin that device.

**Right column:** the device stage. Do not build it here — sk9 owns the frames and
sk10 the backdrop. In this prompt, leave the existing device stage widget in the
right column, resized to the design's column proportion, and accept that it still
looks like the old one.

**Under 1180px:** the hero becomes one column, `padding: 64px 48px 48px`,
`gap: 48px`, `align-items: start`, h1 drops to 56px. Text above device.

## Do this

Extract the hero into `lib/screens/showcase/hero.dart` rather than growing
`showcase_screen.dart` (it is already 25k). `showcase_screen.dart` becomes the
composition: backdrop + hero + stat band slot + callouts slot.

Build the segmented control and the two button styles as reusable widgets in
`lib/widgets/nocturne/` (`NSegmented`, `NButton` with a `primary`/`secondary`/
`ghost` variant, `NPill`). sk11–sk14 reuse all three; do not inline them.

## Do not

- Do not touch the device frames, the typist, or the backdrop.
- Do not hardcode the country list in the paragraph — if the current app derives
  it from the registry, keep deriving it; the design's sentence is the fallback
  wording, not a new source of truth.
- Do not use `Wrap` for the button row at desktop width; the design keeps them on
  one line and lets the hero column stack instead.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.

Manual at 1440×900 and at 1100 wide: heading sizes, serif face on the h1 only, no
horizontal scroll at either width, segmented control pins the device.

Commit: `newdesign: sk6 showcase hero`.
