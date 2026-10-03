---
name: mv2-shell
description: MV2 — new mobile header (PLATE GALLERY · 01 / SHOWCASE) and restyled bottom tab bar with active accent bar.
model: Sonnet 5.5, medium reasoning
---

# MV2 — Header + tab bar

Read `MOBILE_SPEC.md`, `mobile/mobile_tokens.dart`, and the current mobile header + tab bar files listed
in the spec inventory. Nothing else.

## In
- `mobile/mobile_header.dart` — leading accent dash + `PLATE GALLERY`; trailing `NN / TABNAME` derived
  from the active tab index (data, not literals). Put the `DESKTOP VIEW` affordance where MOBILE_SPEC
  says; if it says `ASK USER`, keep the current link in the trailing slot and leave a `TODO(MV2)`.
- `mobile/mobile_tab_bar.dart` — three equal cells, vertical hairline dividers, active cell: 16×2 accent
  bar above the label, animated with `AnimatedAlign`/`AnimatedSlide` (constant tree shape).
  Same tab callbacks as the old bar — behaviour unchanged.

## Out
Mobile body composition (MV7). Do not swap the old header/tab bar in yet unless it is a one-line
replacement at a single call site; otherwise leave the new widgets unused.

## Verify
`flutter analyze`. Run on a 390-wide window: header and tab bar match the design. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
