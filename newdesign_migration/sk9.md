# sk9 — Device frames: keep the structure, retune size and colour

**Model: Opus 5 · high thinking on.** This is the prompt most likely to go wrong.
The frames are ours and they stay; only their measurements and palette move. A
session that decides to "rewrite the device frame to match the design" has failed.

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/device_preview/device_presets.dart`, `device_config.dart`,
`device_frame.dart`, `device_painters.dart`, `device_painters.hardware.dart`,
`laptop_deck.dart`, `laptop_deck.parts.dart`, and `lib/showcase/device_stage.dart`.

Then read the `devicePresets()` JavaScript function in
`design_ref/Plate Gallery.dc.html` (offsets in `MAP.md`). It is annotated with a
comment pointing back at our own `device_presets.dart` — the designer derived the
design's numbers from ours, so the two are meant to line up.

## The rule for this prompt

**Structure ours. Numbers and colours theirs. Screen ON.**

- Keep `DeviceFrame`, the laptop deck, the notch painter, the hardware painter,
  the dissolve transitions — every widget and painter stays.
- Keep the screen **live**: the device renders the real app content with the
  auto-completing plate typist running (`lib/showcase/plate_typist.dart`,
  `plate_mirror.dart`, `demo_config.dart`). The design shows a dark, essentially
  dead screen on the laptop and one static plate on the mobile. **Ignore that.**
  Our devices keep showing plates typing themselves.
- Move `bodySize`, `bodyRadius`, `screenRadius`, `bezel`, `notch` and the stage
  `scale` for each of the three presets onto the design's values:
  - `mobile` — 390×844, body radius 54, screen radius 42, bezel 12,
    notch 126×32 r16, deck 0, stage scale 0.44
  - read `tablet` and `desktop/laptop` off the same JS array; do not guess them.
- Adopt the design's 3D tilt on the laptop/desktop mockup: the screen tilts back,
  the base tilts flat with perspective, and two rows of keycaps are visible on the
  deck. The design's own changelog describes exactly this. Mobile and tablet get
  **no** tilt.
- Retune every frame colour to Nocturne: body/chassis off the `n700`–`n900` ramp,
  the hairline off `divider`, the screen-off fill toward `#0D1017`. No blue.
  Currently these come from `lib/poster/poster_tokens.dart` — take the values from
  `lib/theme/nocturne.dart` instead and leave `poster_tokens.dart` alone (sk10).
- The device shadow is the one place `NShadow.lg` is right.

## Guard rails

- The screen content is laid out by `LayoutBuilder` (sk5), so a 390-wide simulated
  phone must render the *mobile* shell — bottom bar, mobile header — inside the
  frame while the surrounding page is desktop. Verify this visually; if it renders
  the desktop rail inside the phone, the sk5 `LayoutBuilder` is being bypassed and
  that is the bug to fix.
- Changing `bodySize` changes the aspect the content is scaled into. Check that no
  simulated screen overflows or letterboxes. If the plate typist's plate is clipped
  at the new mobile size, adjust the *stage scale*, not the plate.
- The three-device auto-cycle (5.2s in the design; check what ours uses and keep
  ours unless it differs wildly) must still run, and must still be interruptible by
  the sk6 segmented control.

## Do not

- Do not rewrite or replace `device_frame.dart`.
- Do not turn the screen off or substitute a static image.
- Do not copy any plate rendering from the design.
- Do not touch the backdrop or the sweep light — sk10.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.

Manual: cycle all three devices at 1440×900. Each frame matches the design's
proportions, the laptop is tilted with visible keycaps, every screen shows plates
typing, nothing is clipped, and the whole stage is grey/indigo with no blue.

Report the before/after table of preset numbers.

Commit: `newdesign: sk9 device frames retuned`.
