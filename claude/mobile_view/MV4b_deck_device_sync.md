---
name: mv4b-deck-device-sync
description: MV4b — bind the feature deck to the device frame and the Mobile/Tablet/Desktop chips so card group and device always agree.
model: Opus 5.5, high reasoning with thinking
---

# MV4b — Deck ↔ device sync

**Commit before starting.** This touches the mobile body and the device-cycle consumer.

Read `MOBILE_SPEC.md` (device-cycle section), `mobile/feature_deck.dart`, and the mobile body file.
`device_cycle.dart`, `device_frame.dart`, `plate_typist.dart` are **frozen** — consume their public
surface only.

## Contract
- **The deck is the clock on mobile.** When the deck's current group changes device, the frame hops to
  that device. Section header trailing label = `<DEVICE> PREVIEW`.
- Chips (Mobile / Tablet / Desktop, position per spec) → `deck.jumpTo(firstIndexOf(group))`.
- If the device cycle runs its own timer, the mobile body must stop driving it by time and drive it by
  deck index instead. If the frozen cycle offers no external hook → **stop and report** (that is the
  MV4b-i split: add the hook in the holder's own wrapper, not in the frozen file).
- A device hop takes longer than nothing: while the frame is morphing, the deck's 4 s dwell for the
  first card of the new group starts **after** the hop completes (listen for settle), so the card is
  never shown against the wrong device.

## Thinking notes
- P12C: the page subtree under the frame must not remount on hop. Do not wrap the frame in anything
  whose type changes with deck state.
- Rapid taps across a group boundary: coalesce — only the latest target device is requested.

## Out
Desktop body. Typist scripts. Any frozen file.

## Verify
`flutter analyze`. Run mobile: let it auto-advance across all three groups; tap backwards across a
boundary; tap a chip mid-hop. Frame and label always agree. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
