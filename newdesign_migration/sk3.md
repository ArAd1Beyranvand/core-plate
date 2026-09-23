# sk3 — ThemeData and global typography on Nocturne

**Model: Sonnet 5 · medium thinking on.**

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/theme/README.md`, then `lib/app/app.dart` and
`lib/screens/gallery/theme/gallery_theme.dart`.

## Do this

1. Create **`lib/theme/nocturne_theme.dart`** exposing `ThemeData nocturneTheme()`:
   - `brightness: Brightness.dark`, `scaffoldBackgroundColor: N.bg`,
     `canvasColor: N.bg`, `colorScheme` seeded from `N.accent` with `surface: N.surface`,
     `onSurface: N.text`, `outline: N.divider`.
   - `fontFamily: NType.archivo`, plus `fontFamilyFallback: [NType.arabic]` so
     Persian/Arabic strings resolve without every call site asking.
   - A full `TextTheme` mapped from `NType`: `displayLarge→h1`, `headlineMedium→h2`,
     `headlineSmall→h3`, `titleLarge→h4`, `titleMedium→h5`, `labelLarge→h6`,
     `bodyMedium→body`.
   - `dividerTheme` using `N.divider`, thickness 1, space 0.
   - `splashFactory: NoSplash.splashFactory` and transparent highlight — the design
     has no Material ripple anywhere; hover is a colour change and nothing else.
   - `visualDensity: VisualDensity.compact`.
   - Scrollbars hidden by default (`scrollbarTheme` with `thumbVisibility: false`,
     thickness 0) — the design sets `scrollbar-width: none` on `.pg-scroll`.

2. Wire it in `lib/app/app.dart`: `theme:` and `darkTheme:` both `nocturneTheme()`,
   `themeMode: ThemeMode.dark`. Leave the router untouched.

3. **Leave `gallery_theme.dart` and `tokens.dart` in place, unreferenced from
   `app.dart`.** Screens still import them and still compile — sk15 removes them
   once nothing points at them. Do not start deleting here; a half-deleted theme in
   the middle of the run is what makes a migration unrecoverable.

4. Add a scroll-behaviour override so web shows no scrollbars and supports drag
   scrolling with mouse: a `ScrollBehavior` subclass in the same file, set on
   `MaterialApp.scrollBehavior`.

## Verify before the gate

Run the app (`flutter run -d chrome`). Expect: every page now sits on near-black
`#050608` with white-ish text, and every screen looks *wrong but readable* —
old layouts in new colours. That is the correct intermediate state. Nothing should
be unreadable; if any text is dark-on-dark, note which screen in the report so the
relevant later prompt handles it.

## Do not

- Do not restructure any screen. No layout changes in this prompt.
- Do not delete anything.
- Do not touch `lib/poster/poster_tokens.dart` — sk10 owns it.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.
Commit: `newdesign: sk3 theme wiring`.
