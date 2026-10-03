---
name: mv8-verify
description: MV8 — goldens for the new mobile body, a profile pass over deck + numeral + carousel, accessibility and text-scale checks.
model: Sonnet 5.5, medium reasoning
---

# MV8 — Verification

## In — `test/mobile/**`
- Goldens at 390×844 and 360×740: mobile body at deck index 0, at the last index, and with the numeral
  mid-charge (pump the dwell to 50 %). Use the fake clock; disable the auto-advance timer in tests via
  the deck controller, not by editing production timing.
- Widget tests: tap right/left halves, segment jump, wrap-around rewind ends on `01`, chip → first card
  of its group, long-press pauses.
- `RollingNumeral`: given `value` 9 → 1, final painted digit is `1`; reduced-motion path builds no roll
  controller.

## Checks (report, do not fix unless one-line)
- `flutter run --profile -d linux` at a 390-wide window, 30 s idle on the deck: no `JANK` lines;
  DevTools shows paint-only frames for the numeral and progress bar.
- Text scale 1.3: no overflow in header, strip, deck footer.
- Semantics: deck exposes "Feature N of M, <title>"; tap zones have labels "Next"/"Previous".

## Verify
`flutter test test/mobile`, `flutter analyze`. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
