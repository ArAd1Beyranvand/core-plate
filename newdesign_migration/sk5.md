# sk5 — Mobile bottom bar and the breakpoint switch

**Model: Sonnet 5 · medium thinking on.**

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/shell/nocturne_rail.dart`, `lib/screens/gallery_shell_screen.dart`, and
the mobile-panel blocks in `design_ref/Plate Gallery.dc.html` — the `.pg-m` CSS in
the `<style>` block, the mobile `<header>`, and the bottom `<nav>` (offsets in
`design_ref/MAP.md`).

## What the design specifies

The mobile layout is **its own layout, not the desktop one squeezed** — the design
says so in a comment. Two pieces:

**Top header** — `display: flex`, space-between, `gap: 12px`,
`padding: 15px 18px`, `border-bottom: 1px divider`. Left: the `Plate Gallery`
mono wordmark. Right: whatever contextual control the screen needs (back arrow on
detail; nothing on the three top-level screens).

**Bottom nav** — `grid-template-columns: repeat(3, 1fr)`,
`border-top: 1px divider`, `background: n900` (`#0E1219`). Each cell is a column:
the `01`/`02`/`03` mono number above the label, centred, same colour rules as the
rail (`n500` resting, `n100` selected). The selected cell carries a short accent
bar — read the design for whether it sits above or below the label and match it.

## Do this

1. Create `lib/shell/nocturne_bottom_bar.dart` (`NocturneBottomBar`) and
   `lib/shell/nocturne_mobile_header.dart` (`NocturneMobileHeader`, taking an
   optional trailing widget).

2. In `gallery_shell_screen.dart`, switch on `NBreak.shell` (900):
   - `>= 900` → `Row(page, NocturneRail)` from sk4.
   - `< 900` → `Column(NocturneMobileHeader, Expanded(page), NocturneBottomBar)`.
   Use `LayoutBuilder`, not `MediaQuery`, so the device-preview frames in the
   showcase get the right layout for *their* width rather than the window's.
   That distinction matters — the showcase renders the app inside simulated
   devices, and reading `MediaQuery` there gives every frame the desktop layout.

3. Make the sk4 `MOBILE VIEW` button real. It flips an app-level
   `ValueNotifier<bool> forceMobilePanel`. When true, the whole app renders as the
   design's phone panel: a 390×812 box, centred, `margin: 28px auto`,
   `border: 1px divider`, `radius: 28`, `shadow-lg`, on a background of
   `radial-gradient(120% 100% at 50% 0%, #0d0f16, #050608 60%)`, with the rail
   hidden. The button's label toggles between `MOBILE VIEW` and `DESKTOP VIEW`.
   Put the notifier somewhere the shell and the rail both reach without a new
   package — an `InheritedNotifier` in `lib/shell/` is fine; do not add
   `provider`, `riverpod` or any state package.

4. Hide scrollbars inside the panel and give it `ClipRRect` so content respects
   the 28px radius.

## Do not

- Do not use a Material `BottomNavigationBar` or `NavigationBar`. They bring their
  own indicator, ripple, elevation and label behaviour, and fighting those costs
  more than drawing three `Column`s.
- Do not change any page body.
- Do not let the mobile panel affect the real mobile breakpoint — a genuinely
  narrow window and the forced panel both produce the mobile layout, but the panel
  chrome (border, radius, shadow, centring) appears only when forced.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.

Manual: at 1440 wide the rail shows; drag the window under 900 and the bottom bar
takes over with no overflow; clicking `MOBILE VIEW` at 1440 gives the centred
phone panel with the bottom bar inside it.

Commit: `newdesign: sk5 mobile bottom bar + panel toggle`.
