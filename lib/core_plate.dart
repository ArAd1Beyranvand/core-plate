/// Data-driven vehicle licence plates for Flutter.
///
/// A plate is a `const` [PlateSpec]: canvas geometry, a country panel, a list
/// of slots over alphabets, and optional chrome (rules, labels, decals). The
/// widget layer paints whatever a spec describes, so **adding a plate — for a
/// new country or an existing one — means adding a const, never a widget.**
///
/// What this package deliberately does not do:
///
/// - **It does not know any country.** Not one file here names a country, and
///   it ships no assets. Plates, alphabets and flags are data, and each
///   country's live in that country's own package. `grep` over `lib/` is the
///   standing proof, so keep it that way: a country name in this package, even
///   in a comment, is the bug.
/// - **It does not police input.** A [PlateValidator] answers "is this plate
///   valid?" and never bars a keystroke.
/// - **It does not own your keyboard.** [PlateInputSource] lets the host
///   supply characters from its own UI through a [PlateInputController].
/// - **It does not choose your state management.** A plate holds its own
///   characters in a [PlateController] — a [ChangeNotifier], and no dependency
///   beyond Flutter. If your code around the plate is bloc-shaped, the
///   `core_plate_bloc` package provides a bloc mirrored onto that controller;
///   this package neither knows nor asks.
///
/// Everything reachable from this file is API this package supports. Anything
/// under `src/` that this file does not export is an implementation detail:
/// it can change or disappear without a major version. In particular the
/// input state machine, the slot widget and the plate frame are core's
/// business, not a consumer's.
library;

// ---------------------------------------------------------------------------
// Model — the plate as data. This is the part a consumer writes.
// ---------------------------------------------------------------------------

/// Geometry primitive shared by every positioned element on the plate face.
export 'src/model/plate_box.dart';

/// The spec itself and everything that composes into one, plus the
/// `assert`-only consistency check for spec authors.
export 'src/model/plate_spec.dart';

/// The character set behind a slot, and how the user supplies a character
/// from it.
export 'src/model/plate_alphabet.dart';

/// The country block on the plate face, and the flag/badge images it paints.
export 'src/model/plate_country.dart';
export 'src/model/plate_asset.dart';

/// The entered value and whether the plate is being displayed or edited.
export 'src/model/plate_number.dart';

/// Where characters come from: the system IME, a hardware keyboard, this
/// package's keypad, or the host's own UI.
export 'src/model/plate_input_source.dart';

/// What a slot does about input, resolved from mode + alphabet + source.
///
/// `show:` — `resolveSlotBehavior` performs that resolution and is core's
/// business: a consumer reads a [SlotBehavior], it does not derive one.
export 'src/model/slot_behavior.dart' show SlotBehavior;

// ---------------------------------------------------------------------------
// Theme — colours and ratios, inherited or passed explicitly.
// ---------------------------------------------------------------------------

export 'src/theme/plate_theme.dart';

// ---------------------------------------------------------------------------
// Widgets — the plate on screen.
// ---------------------------------------------------------------------------

/// The editable plate, and the read-only pair for displaying one from a
/// [PlateController].
export 'src/widgets/plate_canvas.dart';
export 'src/widgets/plate_view.dart';

/// Pieces of plate chrome a host may also place on its own.
export 'src/widgets/country_panel.dart';
export 'src/widgets/plate_flag.dart';

// The on-screen keypad and the `chosen`-slot character picker moved to the
// `plate_keypad` package in P7. A host that wants either now depends on
// `plate_keypad` and passes `PlateCharacterPicker.show` as
// [PlateCanvas.onChooseCharacter].

// ---------------------------------------------------------------------------
// Input — driving character entry from outside the plate.
// ---------------------------------------------------------------------------

/// The host-facing handle, and the interface it drives. `PlateInputMachine`
/// — the implementation a [PlateCanvas] attaches on the host's behalf — is
/// deliberately absent: a consumer never constructs one.
export 'src/input/plate_input_controller.dart';

/// The value-owning handle: the primary API for a host that wants to read or
/// write the plate's characters, not just drive focus. It extends
/// [PlateInputController], so a canvas takes either — and
/// [PlateInputController] remains exactly as it was for focus-only hosts.
export 'src/input/plate_controller.dart';

/// Rebuilds on a *derived* piece of a [PlateController] only when that piece
/// changes. Per-slot listening needs no such thing: `PlateController.slot(i)`
/// with a `ValueListenableBuilder` is already as narrow as it gets.
export 'src/widgets/plate_selector.dart';

// State — a canvas keeps its values in a [PlateController], exported above with
// the rest of the input surface. The bloc that used to live here — along with
// `PlateCardBinding`, `ShowPlate` and `PlateText` — left for the
// `core_plate_bloc` package in 0.4.0, and with it this package's `flutter_bloc`
// and `bloc` dependencies; see CHANGELOG.md for the one-line migration.

// ---------------------------------------------------------------------------
// Validation — advisory verdicts on a filled plate.
// ---------------------------------------------------------------------------

export 'src/validators/plate_validator.dart';

// The country constants, alphabets, specs, flags and country-specific
// validators this file used to re-export left for one package each in P8; see
// CHANGELOG.md for the import a consumer switches to. They are deliberately
// not named here — see the note above. A host depends on the countries it
// actually draws, and on none of them to compile.
