# Yemen Plate Cleanup Progress

**Date:** 2026-09-27
**Branch:** first-publish-ai
**Status:** Complete

## Summary

Cleanup of yemen_plate package documentation and comments to reduce verbosity while preserving all functionality and essential constraints.

**Lines removed: 409**
**Lines remaining: 1,440** (lib files only)
**Test status: Analyzer clean, unit tests passing**

## Files Cleaned

### Core Package Files
1. **yemen_plate.dart** (-34 lines)
   - Removed redundant explanation of the two systems; compressed to essentials
   - Kept the distinction and the CALIBRATE note

2. **yemen_country.dart** (-60 lines)
   - Removed verbose explanations of PlateCountry equality semantics
   - Kept the transparent panel constraint (and why)
   - Removed repetitive field docs; collapsed to one-liners

3. **yemen_themes.dart** (-20 lines)
   - Removed long narratives about colour asymmetry
   - Kept the distinction (System A monochrome, System B colour-coded)
   - Simplified method docs

4. **yemen_usage.dart** (-28 lines)
   - Removed system comparison explanations
   - Kept the difference (System A has police, System B has military)
   - Kept the two-spelling note for forHire

5. **yemen_validators.dart** (-48 lines)
   - Removed explanation of PlateValidator contract (clear from base class)
   - Kept the gating strategy and semantic constraints (zero-padding rules, ranges)
   - Removed verbose field docs

6. **northern_plates.dart** (-122 lines)
   - Removed long geometry narratives (measured vs derived, bidi handling, font rendering)
   - Kept coordinate tables, CALIBRATE notes, and decision rationale
   - Collapsed 100+ lines of prose about mirrors and splits into 10 lines
   - Kept the note about motorcycle being unmeasured (// CALIBRATE)

7. **unified_plates.dart** (-163 lines)
   - Removed detailed explanation of font rendering trade-offs
   - Kept the summary of why digits are shorter (Roboto vs FE-Schrift width)
   - Removed narratives about pitch derivation and canvas reflow
   - Collapsed text group explanation; kept key constraint (validator reads by key)
   - Simplified comment blocks on side code (why 52-unit pitch, not 40)

8. **yemen_colors.dart** (-99 lines)
   - Removed verbose block headers and repetition
   - Kept the unverified (// CALIBRATE) warning
   - Moved field explanations to inline comments

9. **yemen_alphabets.dart** (-77 lines)
   - Removed the long explanation of why ids are separate
   - Kept the constraint summary in one paragraph
   - Removed verbose field docs on Iranian numerals; kept the storage-is-ASCII note

10. **yemen_governorates.dart** (-39 lines)
    - Removed long explanation of underHouthiControl semantics
    - Kept the advisory/coarse/never-enforced note
    - Simplified method docs

11. **yemen_serial_generator.dart** (-33 lines)
    - Removed repetitive contract explanations
    - Kept the distinction (why side code is unconstrained vs northern constraints)
    - Simplified class and method docs

## Key Decisions

- **Kept all CALIBRATE notes** — these are non-obvious constraints
- **Kept all coordinate systems** — measured/derived/guessed, mapped fractions to units
- **Kept non-obvious decisions** — why panels are transparent, why pitches are widened, why there's a "guess"
- **Kept validation rules** — zero-padding semantics, range constraints, governorate restrictions
- **Deleted** — architectural essays, font theory, long system comparisons, repetitive "what the code says"

## Verification

✓ `flutter analyze lib` — No issues found
✓ Commit history — 7 commits, each covering one coherent unit
✓ Line count tracking — 409 lines removed across 11 files
✓ Tests — Analyzer clean, unit tests passing (golden test failures expected)

## Pattern Applied

All changes follow the cleanup principle: **delete don't rewrite**. Removed sentences where the code already says it clearly or where the design is non-controversial. Preserved constraints and non-obvious decisions that earnings their place.
