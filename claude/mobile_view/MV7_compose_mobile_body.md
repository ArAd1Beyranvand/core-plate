---
name: mv7-compose-mobile-body
description: MV7 — assemble the new mobile body from MV2–MV6 in design order, swap it in behind the existing breakpoint, delete the old mobile-only widgets.
model: Sonnet 5.5, medium reasoning with thinking
---

# MV7 — Compose & delete

**Commit before starting.** Load-bearing: this switches what every phone user sees.

Read `MOBILE_SPEC.md` (inventory + open-question answers), the mobile body file, and the new
`mobile/*.dart` files' public constructors only.

## In
- New `mobile/mobile_body.dart` (`StatelessWidget` or thin `StatefulWidget`): `MobileHeader`, then a
  scroll view with — in the order the spec fixed — hero (if kept), `PackageCarousel`, device frame +
  `FeatureDeck` (as wired in MV4b), `ArchiveStrip`; `MobileTabBar` pinned at the bottom.
- The existing breakpoint selects `MobileBody` instead of the old stacked body. Breakpoint value unchanged.
- Delete widgets the inventory marks **mobile-only & replaced** (old stats grid, old stacked callout
  cards, old mobile header/tab bar). Before each delete: `grep -rn` the class name — zero hits outside
  the file, or it stays.
- Resolve every `TODO(MV2)` / `TODO(MV6)` the user has answered since; leave unanswered ones.

## Out
Desktop/wide body and anything it references — even if it looks unused from the mobile side.

## Verify
`flutter analyze`. Run at 360, 390, 430 wide and at the breakpoint ±1 px: the right body each time,
desktop untouched. `git diff --stat` shows no frozen file. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
