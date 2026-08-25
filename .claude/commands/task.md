---
description: Run one numbered poster-migration task (P1–P9) end to end
argument-hint: <1-9>
---

Run migration task **P$ARGUMENTS**.

If `$ARGUMENTS` is empty, not a number, or outside 1–9: read
`docs/migration/PROGRESS.md`, tell me which task is next, and stop.

## Steps

1. Read `docs/migration/PROGRESS.md`. If task P$ARGUMENTS is already marked done,
   say so and ask before redoing it. If any earlier task is not done, name it and
   ask before continuing out of order.
2. Read `docs/migration/P$ARGUMENTS.md` in full. Everything under its "## The task"
   heading is the instruction — follow it literally, including its verification step.
   The "Quality" line is informational; do not act on it.
3. Read `DESIGN_SPEC.md` at the repo root, plus only the source files the task names.
   Do not survey the rest of the repo.
4. Do the work.
5. Verify exactly as the task's own verification step demands. `flutter analyze`
   must be clean before you commit.
6. `git commit` with message `poster: P$ARGUMENTS — <task title>`. Do not ask first.
7. Tick P$ARGUMENTS in `docs/migration/PROGRESS.md`, recording the commit hash and
   any deviation or open issue, and include that file in the commit.

## Frozen — never edit, in any task

```
lib/**
example/lib/device_preview/**
example/lib/showcase/plate_typist.dart
example/lib/showcase/virtual_keypad.dart
example/lib/showcase/device_cycle.dart
example/lib/widgets/plate_display.dart
example/lib/poster/plate_backdrop.dart
```

The device and everything on its screen is out of scope. The design file draws its
own devices, plates and keyboards — that is reference art, not a specification. If
the task appears to require touching a frozen file, **stop and report it** instead
of doing it.

## Reporting

Report only the diff summary, the commit hash, and anything the verification step
found wrong. No narration, no recap of what you read.
