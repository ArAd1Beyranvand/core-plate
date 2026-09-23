# newdesign_migration — Nocturne migration for `plate_number_holder`

Sixteen Claude Code prompts that take the app from the current blue theme to the
**Plate Gallery / Nocturne** design shipped in `newdesign.zip`.

## Ground rules (apply to every prompt)

- **One fresh Claude Code session per file.** Run `/clear` between them. Never run
  two in one session — they are sized to fit a clean context.
- Run them **in order**. Each assumes the previous one landed and is committed.
- Every prompt ends with the same gate:
  ```
  flutter analyze        # must be clean, zero issues
  flutter test           # must pass
  flutter build web      # must succeed
  ```
  If the gate fails, fix it inside the same session. Do not proceed to the next sk.
- Commit after each prompt: `git commit -m "newdesign: <sk name>"`. That is the
  rollback unit.

## What is being kept vs replaced

| Kept | Replaced |
| --- | --- |
| Our own plate widgets from the country packages (the design's plates are wrong — never copy them) | Every colour, font size, spacing and page structure |
| The laptop / tablet / mobile device frames in `lib/device_preview/` — the *structure* | Their frame sizes, radii, bezels, notch and colours |
| The device screen **on**, running the live auto-completing plate typist | The design's dead/off screen |
| Registry-computed stat numbers | The design's hardcoded 5/7/51/2 |
| Route structure (`/showcase`, `/discover`, `/about`) | The whole visual shell around it |
| The bundled fonts (Archivo, MartianMono, Newsreader, Vazirmatn — already in `pubspec.yaml`) | — |

The old blue theme is **deleted outright** in sk15. Nothing is kept behind a flag.

## The prompts

| # | File | What it does |
| --- | --- | --- |
| 1 | `sk1.md` | Unpack design ref, baseline, branch |
| 2 | `sk2.md` | Nocturne token layer |
| 3 | `sk3.md` | ThemeData + typography wiring |
| 4 | `sk4.md` | Desktop right side-nav rail |
| 5 | `sk5.md` | Mobile bottom bar + breakpoint |
| 6 | `sk6.md` | Showcase hero block |
| 7 | `sk7.md` | Showcase stat band (live registry) |
| 8 | `sk8.md` | Showcase floating callout cards |
| 9 | `sk9.md` | Device frames retuned to Nocturne |
| 10 | `sk10.md` | Showcase backdrop + sweep light |
| 11 | `sk11.md` | Discover index |
| 12 | `sk12.md` | Country "All plates" screen |
| 13 | `sk13.md` | Plate detail + right aside rail |
| 14 | `sk14.md` | About page |
| 15 | `sk15.md` | Delete old theme + dead code |
| 16 | `sk16.md` | Final audit + visual diff |

## Round 2 (sk17–sk24) — run order

sk1–sk14 are done. sk16 is superseded by sk24. New rule for every remaining
prompt: **no `flutter test`, no `flutter build`, no `flutter run` — `flutter
analyze` only; the session stops and asks Arad to build.**

Run in this order: **sk17 → sk18 → sk19 → sk20 → sk21 → sk22 → sk23 → sk23.5 →
sk23.75 → sk15 → sk24**.

| # | File | What it does |
| --- | --- | --- |
| 17 | `sk17.md` | Country + plate pages pushed inside the shell (rail / mobile header / bottom bar stay) |
| 18 | `sk18.md` | Country screen, desktop (tinted hero card, stats, flat grid) |
| 19 | `sk19.md` | Country screen, mobile (+ OTHER COUNTRIES list) |
| 20 | `sk20.md` | Plate detail, desktop (two columns + aside rail) |
| 21 | `sk21.md` | Plate detail, mobile (card-style input modes, pinned Submit) |
| 22 | `sk22.md` | Orb jump fix on device screens (re-apply P12C GlobalKey fix) |
| 23 | `sk23.md` | Stat band sized from width + height, inline on mobile |
| 23.5 | `sk23.5.md` | Callout tile animation back; 3 sets × 3 cards, one set per device |
| 23.75 | `sk23.75.md` | Sharp-and-short rewrite of all UI copy (COPY.md approved first) |
| 15 | `sk15.md` | Delete old theme + dead code (gate updated to the no-build rule) |
| 24 | `sk24.md` | Final audit — replaces sk16 |

Target/current screenshots live in `pictures/target/` and `pictures/current/`.

## Design tokens (authoritative — from `Plate Gallery.dc.html`)

```
bg          #050608     surface     #141926     text        #EAF0FB
divider     rgba(255,255,255,.10)
neutral 100 #EAF0FB  200 #D6E1F1  300 #C4D0E2  400 #A5B4C7  500 #8592A3
        600 #6A7484  700 #39414F  800 #232C42  900 #0E1219
accent      #7C5CFF   accent-300 #B9A7FF   accent-700 #4A3A93
accent-800  #2E2560   accent-900 #1A1540

radius      sm 4   md 8   lg 14
space       1:2.8  2:5.6  3:8.4  4:11.2  6:16.8  8:22.4
shadow-sm   1px hairline rgba(255,255,255,.08)
shadow-md   1px hairline rgba(255,255,255,.10) + 0 10 26 rgba(0,0,0,.70)
shadow-lg   1px hairline rgba(255,255,255,.14) + 0 26 60 rgba(0,0,0,.80)

heading     Archivo w800     body   Archivo
mono        MartianMono      serif  Newsreader      arabic Vazirmatn
h1 42 / h2 32 / h3 25 / h4 20 / h5 16 / h6 13 (uppercase, +0.08em)
body 15px / 1.55
breakpoints 1180 (hero stacks) · 1040 (detail stacks) · 900 (shell) · 760 (stat band 2-col)
```
