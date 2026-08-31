## Unreleased

- **Breaking: validation no longer prevents input.** `PlateKeypad.unavailableKeys`
  and `GermanPlateValidator.barredNextDigits` / `barredNextLetters` are
  **removed**, not deprecated. They existed to grey out and swallow the keys
  that would complete a forbidden value; a plate library has no business
  refusing a keystroke, and a plate may now hold an invalid value. `_keyEnabled`
  still disables a key outside the active alphabet — that is a fact about the
  alphabet, not a validation rule.
- New `PlateValidator` / `PlateValidation` / `PlateEntry` in
  `validators/plate_validator.dart`: a validator answers one question — is this
  plate valid? — and returns a verdict. There is deliberately no "which keys are
  barred" method.
- `PlateCanvas` gains `validator` and `autoValidate` (default `false`). With
  `autoValidate: true` the canvas paints the invalid state itself, in the new
  `PlateTheme.alertColor`. With it `false` the validator is never called by the
  canvas; read `PlateInputController.validation` and pick your own timing.
- `PlateInputController.validation` exposes the verdict on demand and notifies
  listeners when the verdict changes, not on every keystroke.
- `GermanPlateValidator` is now `const`-constructible and implements
  `PlateValidator`. `GermanPlateValidationResult` is a `typedef` for
  `PlateValidation`, kept for one release. `validateValues(spec, values)` is
  replaced by the `validate(PlateEntry)` override; the spec-free static is
  renamed `validateFields`.
- Removed `docs/forbidden.json`. It duplicated `_forbiddenLetterPairs` /
  `_forbiddenNumbers` by hand and nothing read it; the Dart consts always were
  the source of truth.
- Rewrote `README.md` against the current `PlateSpec`/`PlateCanvas` API.

## 0.1.0

- **Breaking:** Removed `CarPlateNumber` and `BicyclePlateNumber`. Use
  `PlateCanvas(spec: PlateSpecs.irCar)` and
  `PlateCanvas(spec: PlateSpecs.irBicycle)` instead.
- `PlateCanvas` is now exported from the package root (`plate_number.dart`)
  instead of requiring a deep import.
- **Breaking:** Removed `PlateCanvas.showRemoveButton` and `onRemove`. Hosts
  should render their own remove control alongside `PlateCanvas`.
