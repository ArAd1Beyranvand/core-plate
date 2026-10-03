---
name: mv3-package-carousel
description: MV3 — "One plate per package" swipe carousel; one card per package with a real rendered plate, country name and spec id.
model: Sonnet 5.5, medium reasoning with thinking
---

# MV3 — Package carousel

Read `MOBILE_SPEC.md` (data-source row for packages), tokens, and the catalogue file it points to.

## In — `mobile/package_carousel.dart`
- `SectionHeader(leading: 'ONE PLATE PER PACKAGE', trailing: 'SWIPE →')`.
- `PageView` with `viewportFraction` so the next card peeks (design ≈ 0.70–0.75; take the exact value
  from the spec). `padEnds: false`, left gutter = page gutter.
- Card: plate rendered through the existing frozen plate widget (`PlateDisplay` / `PlateView`) with that
  package's default spec and a fixed demo value — **display only, no input, no focus nodes**.
  Below a hairline: country name (sans) + spec id (mono, dim).
- Card list built from the catalogue as `const` data: one entry per package. If the catalogue has no
  "default spec per package", add a `const` map **in the holder**, never in a package.
- Each card in a `RepaintBoundary`.

## Thinking note
Plates of different aspect ratios (Iran wide car vs. Palestine/Yemen) must sit in one fixed-height
slot: `FittedBox(fit: BoxFit.contain)` inside a fixed `SizedBox`, centred. No `IntrinsicHeight`.

## Out
Composition into the body (MV7). Any package `lib/`.

## Verify
`flutter analyze`. Temporary run in isolation (e.g. a scratch route, removed before commit) — swipe
through every package, no overflow at 360 wide. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
