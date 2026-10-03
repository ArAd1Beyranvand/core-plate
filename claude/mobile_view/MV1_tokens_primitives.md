---
name: mv1-tokens-primitives
description: MV1 — mobile design tokens and the three tiny primitives every later skill uses (mono label, section header, hairline).
model: Sonnet 5.5, low reasoning
---

# MV1 — Tokens & primitives

Read `claude/mobile_view/MOBILE_SPEC.md` (tokens table) and nothing else except the existing
`PosterTokens` file, to reuse colours that already exist.

## In
- `mobile/mobile_tokens.dart` — `abstract final class MobileTokens` with `static const` colours, text
  styles, radii, gaps. Reuse `PosterTokens` values where equal; never duplicate a colour under a new name.
  Fallbacks if the spec lacks one: accent ≈ `#7C5CFF`, card ground ≈ `#0E0F16`, hairline ≈ white @ 8 %.
- `mobile/mono_label.dart` — `MonoLabel(text, {color, tone})`: uppercase, mono, wide tracking
  (`PLATE GALLERY`, `SWIPE →`, `TAP TO ADVANCE`).
- `mobile/section_header.dart` — `SectionHeader(leading:, trailing:)`: label left, accent label right.

## Out
Everything else. No call sites yet — these are unused until MV2+, which is fine.

## Verify
`flutter analyze` clean. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
