## 0.1.0

- **Breaking:** Removed `CarPlateNumber` and `BicyclePlateNumber`. Use
  `PlateCanvas(spec: PlateSpecs.irCar)` and
  `PlateCanvas(spec: PlateSpecs.irBicycle)` instead.
- `PlateCanvas` is now exported from the package root (`plate_number.dart`)
  instead of requiring a deep import.
- **Breaking:** Removed `PlateCanvas.showRemoveButton` and `onRemove`. Hosts
  should render their own remove control alongside `PlateCanvas`.
