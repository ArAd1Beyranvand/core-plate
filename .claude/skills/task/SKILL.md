---
name: task
description: "Index of the 7-stage core_plate PlateController refactor. Invoke when the user runs /task without a number, or asks which stage to run next. Each stage is its own skill: task-1-add-controller … task-7-merge-controllers."
---

# `/task` — core_plate PlateController refactor

Seven ordered stages from `PLATE_CONTROLLER_PLAN.md`. Run each in a fresh session, in
order; each ends with `flutter analyze` clean and a git commit. Invoke the matching
skill (`task-1-add-controller`, etc.).

| # | skill | what it does | model | breaking |
|---|---|---|---|---|
| 1 | `task-1-add-controller` | add `PlateController` + `PlateSelector`, exported, wired to nothing | **Opus 5, medium, thinking** | no |
| 2 | `task-2-canvas-owns-controller` | canvas holds the controller as writer of record; private two-way bloc bridge; stop capturing `BuildContext` | **Opus 5, high, thinking** | no |
| 3 | `task-3-bindings-read-controller` | four bindings move onto controller listenables; preserve per-slot narrowing | **Sonnet 5, medium, thinking** | no |
| 4 | `task-4-spec-swap-keeps-value` | `PlateCanvas.onSpecChange` + `adoptSpec`; fix `PlateText` bounds bug; doc rewrites; delete `_switchTo` workaround | **Sonnet 5, medium, thinking** | no |
| 5 | `task-5-bloc-becomes-optional` | bloc optional; ship `PlateCardBinding`/`PlateView`/`PlateTextView`; migrate every consumer + all 6 examples off `BlocProvider` | **Opus 5, medium, thinking** | no |
| 6 | `task-6-extract-core-plate-bloc` | new `core_plate_bloc` package; core drops `flutter_bloc`+`bloc`; flip `onSpecChange` default | **Opus 5, medium, thinking** | **YES (0.4.0)** |
| 7 | `task-7-merge-controllers` | fold `PlateInputController` into `PlateController`; `@Deprecated` typedef alias | **Sonnet 5, low, thinking** | **YES (0.5.0, deprecation only)** |

Stage 2 is the risky one and ships alone. Everything breaking is confined to stages 6–7,
after the ecosystem already stopped depending on the bloc.
