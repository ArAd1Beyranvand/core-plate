---
name: cleanup
description: Human-quality code cleanup — remove unnecessary comments and verbose documentation while preserving all functionality and constraints.
---

# Code Quality Cleanup Skill

## Goal
Remove unnecessary code, duplication, verbosity, and needless abstraction. Keep the codebase concise, readable, and maintainable — as though an experienced developer wrote and maintained it over time, not as though an AI generated explanatory prose around straightforward code.

## Core Principles

### What to Delete
- Comments that state the obvious (what the code already says)
- Repetitive field docs that just rename the field
- Architecture essays about non-controversial decisions
- Long tutorials on how to use a clear API
- Lectures about design philosophy ("why validators never bar input")
- Verbose explanations of implementation details that the code shows directly

### What to Keep
- Non-obvious constraints (e.g., "box.height doubles as glyph height")
- Reasons behind a design decision that isn't obvious from the code
- Warnings about gotchas or hidden invariants
- One-liners explaining the 'why' when the 'what' is already clear

### Code Patterns

**Duplication collapse:** If the same assertion or lookup appears 3+ times, extract to a helper.

**Simplification:** Replace verbose method docs with one-liners. If the method name + signature says it clearly, the comment is redundant.

**Inline comments:** Delete comments that explain what a line does if the code is clear. Keep comments that explain *why* it's done that way.

## Process

1. **Read the whole file first** — understand the architecture before editing
2. **Delete, don't rewrite** — if a comment adds nothing, remove it entirely
3. **One pass per file** — don't iterate; make conscious decisions
4. **Batch related changes** — collapse similar patterns in one edit
5. **Verify after each commit** — analyzer clean + tests green before moving on

## Commits

Each commit covers one coherent unit (a folder, a layer, or a small package):
- Brief title describing what was trimmed
- Summary of what was removed and why
- Lines-of-code count for visibility

Example:
```
Trim plate_controller.dart: focus on essential docs only

Removed the architecture essays from class and method docs. Kept what earns
its place: the unique constraint about detach() guarding against late
disposal, the non-obvious focus/validation split between PlateCanvas and the
controller, and what _AlwaysNull and the String.characters extension do.

Shortened method summaries to one or two lines.
```

## Current Status

**Completed:**
- core_plate/lib/src/model/ (9 files, -262 lines)
- core_plate/lib/src/input/ (3 files, -75 lines)
- core_plate/lib/src/validators/ (-20 lines)
- core_plate/lib/src/theme/ & widgets/plate_text_row (-33 lines)
- core_plate/lib/core_plate.dart (-94 lines)
- core_plate_bloc/ (-27 lines)

**Total: ~585 lines removed, all tests passing, analyzer clean.**

**Remaining:**
- core_plate/lib/src/widgets/plate_canvas.dart (927 lines)
- core_plate/lib/src/widgets/plate_slot_item.dart (412 lines)
- core_plate/lib/src/widgets/* (5 smaller files)
- Country packages (iran_plate, yemen_plate, palestine_plate, lebanon_plate)
- plate_keypad, plate_number_holder

## Testing Strategy

Run after each commit:
```bash
cd <package>
dart analyze lib          # or flutter analyze for multi-package
flutter test              # ensure tests still pass
```

Do NOT wait for full test suite to finish between small file commits; verify only the affected package.

## Git Workflow

- One commit per coherent cleanup unit (folder, layer, or package)
- No accumulation — finish, commit, move on
- Include line counts in commit messages for visibility
- Progress file tracks what's done vs. what remains
