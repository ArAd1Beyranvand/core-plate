/// Data-driven vehicle licence plates for Flutter.
///
/// A plate is a `const` [PlateSpec]: canvas geometry, a country panel, slots
/// over alphabets, and optional chrome. The widget layer paints whatever a spec
/// describes, so adding a plate means adding a const, never a widget.
///
/// Deliberate non-goals:
///
/// - **No country knowledge.** Nothing here names a country and no assets ship
///   with it; plates, alphabets and flags live in each country's own package.
///   A country name in this package, even in a comment, is a bug.
/// - **No input policing.** A [PlateValidator] answers "is this plate valid?"
///   and never bars a keystroke. The one exception is a
///   [PlateRestriction] a spec declares, which is refused everywhere.
/// - **No keyboard ownership.** [PlateInputSource] lets the host feed
///   characters from its own UI through a [PlateController].
/// - **No state-management opinion.** A plate holds its characters in a
///   [PlateController], a [ChangeNotifier] with no dependency beyond Flutter.
///
/// Anything under `src/` this file does not export is an implementation detail
/// — in particular the input state machine, the slot widget and the frame.
library;

// Model — the plate as data. This is the part a consumer writes.
export 'src/model/plate_box.dart';
export 'src/model/plate_spec.dart';

/// Register values a spec refuses in every layer; opt-in per spec.
export 'src/model/plate_restriction.dart';

/// Constructors for the regular parts of a face. A plate is registers, not
/// rectangles, and a register written cell by cell drifts.
export 'src/model/plate_layout.dart';

export 'src/model/plate_alphabet.dart';
export 'src/model/plate_country.dart';
export 'src/model/plate_asset.dart';
export 'src/model/plate_number.dart';
export 'src/model/plate_input_source.dart';

/// `resolveSlotBehavior` is withheld: a consumer reads a [SlotBehavior], it
/// does not derive one.
export 'src/model/slot_behavior.dart' show SlotBehavior;

export 'src/theme/plate_theme.dart';

/// The editable plate and the read-only pair. Both take an optional `country:`
/// overriding [PlateSpec.country] at render time, so a usage-varying panel is a
/// render argument rather than a second spec.
export 'src/widgets/plate_canvas.dart';
export 'src/widgets/plate_view.dart';

/// The bare text row, plus `noCharacterChooser` for [PlateMode.display].
export 'src/widgets/plate_text_row.dart';

// Plate chrome a host may also place on its own.
export 'src/widgets/country_panel.dart';
export 'src/widgets/plate_flag.dart';

// The keypad and the `chosen`-slot character picker live in `plate_keypad`; a
// host that wants either passes `PlateCharacterPicker.show` as
// `PlateCanvas.onChooseCharacter`.

/// The plate's handle: it owns the characters and drives focus and navigation.
export 'src/input/plate_controller.dart';

/// `PlateInputTarget`, the interface the handle drives.
export 'src/input/plate_input_controller.dart';

/// Rebuilds on a *derived* piece of a [PlateController]. Per-slot listening
/// needs none: `PlateController.slot(i)` in a `ValueListenableBuilder` is
/// already as narrow as it gets.
export 'src/widgets/plate_selector.dart';

/// `PlateValidation`, `PlateEntry`, the `PlateValidator` base and
/// `GatedPlateValidator`, plus the `isDigits` primitives country rules share.
export 'src/validators/plate_validator.dart';
