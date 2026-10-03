---
name: mv6-archive-strip
description: MV6 — "The archive, registered" — stats rendered as a licence-plate strip (PG band, four stat cells, ایران/MIT corner) with real counts.
model: Sonnet 5.5, low reasoning
---

# MV6 — Archive plate strip

Read `MOBILE_SPEC.md` (stats data-source row + tokens) and the file that computes today's counts.

## In — `mobile/archive_strip.dart`
- `SectionHeader(leading: 'THE ARCHIVE, REGISTERED')`.
- Strip = one rounded plate-shaped box, 1 px accent-tinted border, soft outer accent glow:
  - left band: ring icon + `PG` (mono, bold), accent-tinted ground — mirrors the Iran plate's blue band;
  - four cells from a `const` list of `(label, valueGetter)`: PKGS, COUNTRIES, SPECS, FORMS —
    **real values** from the existing count source (11 / 16 / 140 / 2 today), not the mockup's numbers;
  - right corner: `ایران` (small) over `MIT` (accent, mono). `ایران` stays RTL in its own `Text`.
  - cells divided by hairlines; numbers sized with `FittedBox(fit: BoxFit.scaleDown)` so a 3-digit
    value fits at 360 wide.
- Caption row: `IRAN MADE · OPEN SOURCE` left, `V1 · <version>` right — version from the holder's
  `pubspec` / existing version constant if one exists; otherwise `V1 · 2026` literal with `TODO(MV6)`.

## Out
Removing the old 2×2 grid (MV7).

## Verify
`flutter analyze`. 360 and 430 wide: no overflow, numbers match the old grid. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
