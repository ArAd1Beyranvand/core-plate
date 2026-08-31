/// Data-driven vehicle licence plates for Flutter.
///
/// A plate is a `const` [PlateSpec]: canvas geometry, a country panel, a list
/// of slots over alphabets, and optional chrome (rules, labels, decals). The
/// widget layer paints whatever a spec describes, so **adding a plate — for a
/// new country or an existing one — means adding a const, never a widget.**
///
/// What this package deliberately does not do:
///
/// - **It does not know any country.** The plates and alphabets under
///   `src/countries/` are data that happens to ship here for now; core names
///   no country in its own code paths.
/// - **It does not police input.** A [PlateValidator] answers "is this plate
///   valid?" and never bars a keystroke.
/// - **It does not own your keyboard.** [PlateInputSource] lets the host
///   supply characters from its own UI through a [PlateInputController].
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

/// The editable plate, and the read-only pair for displaying one.
export 'src/widgets/plate_canvas.dart';
export 'src/widgets/show_plate.dart';

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

// ---------------------------------------------------------------------------
// State — the bloc a canvas keeps its values in.
// ---------------------------------------------------------------------------

export 'src/bloc/plate_card_bloc.dart';

// ---------------------------------------------------------------------------
// Validation — advisory verdicts on a filled plate.
// ---------------------------------------------------------------------------

export 'src/validators/plate_validator.dart';

// ---------------------------------------------------------------------------
// Countries — data, not code. Leaves for its own package in P8.
// ---------------------------------------------------------------------------

export 'src/countries/iran.dart';
export 'src/countries/germany.dart';
export 'src/countries/german_plate_validator.dart';
