---
name: p0.75-package-template
description: "Refactor phase P0.75 of the plate_number split — remove the android/linux/windows/web app-runner scaffolding this Dart package was never supposed to carry, and correct .metadata's project_type from app to package. Use when the user asks to run P0.75 or fix the package template."
---

# P0.75 — Package template correction

> **Status: landed** — commit `803c795`, "P0.75: Remove platform scaffolding, correct package
> template". `.metadata` reads `project_type: package`; `android/`, `linux/`, `windows/` and
> `web/` are gone from the repo root. One leftover: `.metadata`'s `migration.platforms` still
> lists an `android` entry. That is history, not configuration (step 3 says to leave it), so it
> is not a defect — noted so nobody re-opens the phase over it.
>
> Kept as the record of what the phase did. Do not re-run it.

Follow `CLAUDE.md` working style. Depends on nothing, blocks nothing downstream — safe to run
any time, independently of P0.5 and independently of every numbered phase. This project does
not use automated tests — do not run `flutter test`. Finish with `flutter analyze` clean,
`flutter pub get` succeeding, committed; report diffstat and commit hash only.

## What was found

`.metadata` at the repo root:

```yaml
project_type: app
```

Not `package`. And the repo root carries a full platform-runner set that only a real app or a
plugin with native code needs:

| directory | contents | needed by a pure-Dart-and-widgets package? |
|---|---|---|
| `android/` | `build.gradle.kts`, `gradlew`, `gradlew.bat`, `settings.gradle.kts`, a `plate_number_android.iml`, `app/`, `gradle/` | No |
| `linux/` | `CMakeLists.txt`, a C++ `runner/`, `flutter/` | No |
| `windows/` | same shape as `linux/` | No |
| `web/` | `index.html`, `manifest.json`, `favicon.png`, `icons/` | No |

`plate_number` has zero platform channels and zero native code — every file in `lib/` is Dart
and Flutter widgets. A package scaffolded correctly (`flutter create --template=package
plate_number`) never has any of these five directories; they exist only because this repo
started life as `flutter create` (the **app** template — confirmed by `project_type: app` and
by `.metadata`'s `unmanaged_files: ['lib/main.dart', 'ios/Runner.xcodeproj/project.pbxproj']`,
both referencing files that no longer exist, meaning there was once a root `lib/main.dart` and
an `ios/` folder too, both since removed by hand without anyone correcting the underlying
template metadata) and nobody has removed the leftover scaffolding since.

`.gitignore` excludes `android/`, `ios/`, `web/` and `macos/` at the repo root, but **not**
`linux/` or `windows/` — those two only ignore their own `build/` subdirectories
(`linux/build/`, `windows/build/`), meaning the `CMakeLists.txt` and C++ `runner/` sources
under `linux/` and `windows/` are almost certainly tracked in git today. `android/` and `web/`
being gitignored does not guarantee they are untracked — a file committed before a `.gitignore`
rule was added stays tracked until explicitly removed from the index. Check both.

## Do

1. Confirm what git actually has tracked before deleting anything:

```bash
cd plate-core
git ls-files | grep -E '^(android|ios|linux|windows|web|macos)/' | head -50
```

2. For each of `android/`, `linux/`, `windows/`, `web/` (and `ios/`/`macos/` if step 1 shows
   them tracked despite the ignore rule): remove the directory from disk and, if tracked,
   `git rm -r --cached <dir>` so the removal is staged as a deletion rather than leaving git
   confused about a directory that vanished outside its tracking.

3. `.metadata`: change `project_type: app` to `project_type: package`. Remove the
   `unmanaged_files` entries under `migration:` that reference files which no longer exist
   (`lib/main.dart`, `ios/Runner.xcodeproj/project.pbxproj`) — they document a migration state
   that is stale. Leave the `migration.platforms` list alone; it is history, not configuration,
   and rewriting it doesn't serve anyone.

4. `.gitignore`: once `android/`, `web/`, `macos/`, `ios/` no longer exist on disk, their
   ignore rules are inert but harmless — leave them (a package occasionally gets an example app
   regenerated into these folders during development, and the rules are cheap insurance against
   re-committing it by accident). Add `linux/` and `windows/` to `.gitignore` alongside them, so
   a future `flutter create` inside this repo (by a contributor debugging on Linux or Windows,
   say) doesn't silently re-track platform scaffolding.

5. `plate_number.iml` (an IntelliJ/Android Studio project file) is already gitignored via
   `*.iml` — confirm it's not tracked from before that rule existed, same check as step 1.

## Do not

- `example/` no longer exists — it was deleted along with the repo rename to `plate-core`
  (commit `8e52fd9`, "Rename package repo to plate-core; drop example/ (superseded by
  plate_number_holder)"). Earlier drafts of this plan told you to leave it alone and let P12
  delete it; there is nothing left to leave alone. If you find an `example/` directory, someone
  restored it and that is worth reporting.
- Do not touch `plate_number_holder`'s own platform folders — it is an app, this finding does
  not apply to it.
- Do not run `flutter create --template=package .` to "properly" rescaffold. That rewrites
  files this plan needs to stay as they are (`pubspec.yaml`, `analysis_options.yaml`,
  `lib/plate_number.dart`) and risks clobbering uncommitted work. Removing the five directories
  and fixing `.metadata` by hand is the whole fix.

## Verify

```bash
cd plate-core
flutter pub get
flutter analyze
```

Do not run `flutter test` — this project does not use automated tests. If `flutter pub get` or
`flutter analyze` complain about a missing platform, something in `pubspec.yaml` unexpectedly
depended on one of the removed directories, which would itself be worth reporting rather than
working around.

```bash
du -sh .   # repo size drop is the visible win
git status # confirm five directories show as deleted, nothing shows as untracked-and-orphaned
```

Expected: `android/`, `linux/`, `windows/`, `web/` gone, `.metadata` says `package`, and a
fresh `git clone` of this repo is meaningfully smaller.
