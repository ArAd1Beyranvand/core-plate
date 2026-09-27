# Code Quality Cleanup Progress

## Completed (core_plate only)
- **lib/src/model/** — All 9 files. Removed unnecessary prose, kept non-obvious constraints. Folded duplicated bounds checks, simplified group lookups. (-262 lines)
- **lib/src/input/** — All 3 files. Removed architecture essays, kept what earns its place. (-75 lines)
- **lib/src/validators/** — Trimmed to essentials. (-20 lines)
- **lib/src/widgets/** — Trimmed theme and text row. (-33 lines)
- **core_plate/lib/core_plate.dart** — Library file trimmed. (-94 lines)

**core_plate subtotal: ~484 lines removed, 197 tests green.**

## Remaining in core_plate (high-effort, high-value)
- **lib/src/widgets/plate_canvas.dart** (927 lines) — The largest file. Needs careful reading of long methods. Architecture is clean but docs are verbose.
- **lib/src/widgets/plate_slot_item.dart** (412 lines) — Second largest. Complex state management, needs care.
- **lib/src/widgets/** — 5 more smaller widget files.

## Other packages (not yet touched)
- **core_plate_bloc/** (360 lines) — Small, likely quick wins.
- **iran_plate** (994 lines), **yemen_plate** (2223), **palestine_plate** (1750), **lebanon_plate** (1205) — Country packages with plate specs and validators. Likely full of auto-generated-feeling docs.
- **plate_keypad/** (726 lines)
- **plate_number_holder/** — largest (16,380 lines). Gallery app, needs separate pass.
- **germany_plate**, **iranshahr_plate** — Already on feature branches or other branches.

## Strategy for remaining work
1. Finish core_plate's large widget files (plate_canvas, plate_slot_item) — these are foundational, worth doing well.
2. Quick pass on core_plate_bloc — small package, likely straightforward.
3. Systematic pass on the country packages (iran_plate, yemen_plate, etc.) — look for repetitive doc patterns and trim them.
4. plate_number_holder is a gallery app and likely contains boilerplate examples — needs separate attention.
