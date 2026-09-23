# sk4 — The desktop side-nav rail

**Model: Opus 5 · low thinking on.** Small surface, but it is the frame every
screen sits inside and it has to be exactly right.

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/theme/README.md`, `lib/screens/gallery_shell_screen.dart`,
`lib/app/app_routes.dart`, and the `pg-sidenav` block in
`design_ref/Plate Gallery.dc.html` (offsets in `design_ref/MAP.md`).

## What the design specifies

The rail is on the **right**, full viewport height, sticky, `border-left: 1px
divider`, `padding: 44px 0`, a column with `gap: 64px`:

1. **Wordmark**, padded `0 24px`: `Plate` / `Gallery` on two lines, MartianMono
   11px, +0.12em, uppercase, colour `n100`. Below it a **20×1px accent bar**,
   14px down.
2. **Nav items**, a column with `gap: 2px`. Each item is a borderless button,
   `padding: 14px 24px`, `border-left: 2px solid transparent`, baseline-aligned
   row with `gap: 12px`:
   - the number (`01`/`02`/`03`) in MartianMono 10px +0.10em,
   - the label (`Showcase`/`Discover`/`About`) in Archivo 15px,
   - when selected, a **14×1px accent bar pushed to the far right**, vertically
     centred.
   Resting colour `n500`; hover `n200`. The selected item's *text* also lifts to
   `n100`.
3. **Footer**, `margin-top: auto`, column `gap: 18px`, padded `0 24px`:
   - a pill button — `border: 1px n800`, `radius: 999`, `padding: 8px 12px`,
     MartianMono 9.5px +0.10em uppercase, colour `n300`, label `MOBILE VIEW`.
     Hover: border → `accent700`, text → `n100`.
   - three mono lines, MartianMono 10px +0.10em uppercase, colour `n600`,
     line-height 1.8: `IRAN MADE` / `OPEN SOURCE` / `MIT`.

Rail width is not stated as a token; measure it from the export and use a single
named constant (it lands around 210–230 logical px — pick one and name it
`NRail.width`).

## Do this

- Create `lib/shell/nocturne_rail.dart` with `NocturneRail` — a stateless widget
  taking the current `AppTab`, a `ValueChanged<AppTab>`, and callbacks for the
  view toggle.
- Rework `gallery_shell_screen.dart` so that above `NBreak.shell` the body is a
  `Row(children: [Expanded(page), NocturneRail(...)])`. Below the breakpoint, leave
  whatever the shell does today — sk5 replaces it.
- Hover states need `MouseRegion`; there is no ripple and no `InkWell` splash
  (sk3 disabled them). Use `MouseRegion` + `GestureDetector`, and set
  `cursor: SystemMouseCursors.click`.
- Wire `MOBILE VIEW` to a real state: it swaps the app into the design's mobile
  panel presentation. **In this prompt, make it a no-op `onPressed` with a TODO
  pointing at sk5** — the button must render and hover correctly now, and become
  functional there.
- Keyboard: each nav item must be focusable and activate on Enter/Space, with a
  2px `accent` focus ring at 2px offset (the DS `:focus-visible` rule).

## Do not

- Do not add any icon to the rail. The current app has icons next to Showcase /
  Discover / About; the new design has none. Drop them.
- Do not touch the page bodies. Only the shell chrome.
- Do not delete the old nav code yet — remove it from the widget tree, leave the
  file for sk15 if it is a separate file.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.
The existing `test/app_routes_test.dart` must still pass — if the shell rework
breaks route selection, fix the shell, not the test.

Manual check at 1440×900: rail sits right, the accent tick moves with the selected
tab, hovering a non-selected item lightens only its text.

Commit: `newdesign: sk4 side-nav rail`.
