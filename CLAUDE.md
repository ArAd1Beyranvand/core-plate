## Working style
- Don't survey the repo before editing. Read only files named in the task.
- No progress narration or "let me check X" — go straight to edits.
- Batch independent reads/commands in one call.
- Finish every task with: analyzer clean + `git commit`. Don't ask first.
- No summaries of what you read. Report only the diff and commit hash.
- `test/` is the engine's pinned behaviour, added in P1 of the refactor roadmap
  (`claude/REFACTOR_ROADMAP.md`). Keep it green: run `flutter test` before every
  commit, and update the tests in the same commit as any behaviour they pin.
- Do not add tests outside `test/` for widget rendering — goldens live in the
  country packages, which own the assets.
