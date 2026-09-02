import 'package:flutter/foundation.dart';

@immutable
class PlateNumber {
  final List<String?> _values;

  PlateNumber({required List<String?> values})
    : _values = List.unmodifiable(values);

  List<String?> get values => _values;

  bool get isCompleted => !values.any((e) => e == null || e == '');

  bool get isEmpty => !values.any((e) => e != null);

  /// Value equality over [values].
  ///
  /// Without this the class was identity-compared, so anything watching a
  /// [PlateNumber] — notably `context.select` in the canvas — treated every
  /// bloc emission as a change and rebuilt, even when the characters were
  /// identical.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlateNumber && listEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hashAll(values);
}

/// How a plate (and its items) render: [input] shows editable fields, [display]
/// shows bare glyphs on the white face like a real plate photo.
enum PlateMode { input, display }
