import 'package:protobuf/protobuf.dart';
import 'error.dart';
import 'field_path.dart';

/// Cursor maintains a field path and tracks violations during validation.
class Cursor {
  final bool failFast;
  final List<Violation> _violations;
  final FieldPath _path;
  
  Cursor({
    required this.failFast,
    List<Violation>? violations,
    FieldPath? path,
  }) : _violations = violations ?? [],
       _path = path ?? FieldPath();
  
  /// Creates a new cursor for validation.
  static Cursor create({bool failFast = false}) {
    return Cursor(failFast: failFast);
  }
  
  /// Returns true if any violations have been recorded.
  bool get violated => _violations.isNotEmpty;
  
  /// Returns the list of violations.
  List<Violation> get violations => List.unmodifiable(_violations);
  
  /// Records a validation violation.
  void violate({
    required String message,
    required String constraintId,
    String? rulePath,
    bool forKey = false,
  }) {
    _violations.add(Violation(
      fieldPath: _path.toFieldPathString(),
      constraintId: constraintId,
      message: message,
      rulePath: rulePath,
      forKey: forKey,
    ));
    
    if (failFast) {
      throwIfViolated();
    }
  }
  
  /// Throws a ValidationError if there are any violations.
  void throwIfViolated() {
    if (violated) {
      throw ValidationError(_violations);
    }
  }
  
  /// Returns the current field path.
  FieldPath getPath() => _path.clone();
  
  /// Creates a new cursor with an additional field in the path.
  Cursor field(FieldInfo field) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      path: _path.field(field),
    );
  }
  
  /// Creates a new cursor with a list index in the path.
  Cursor listIndex(int index) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      path: _path.listIndex(index),
    );
  }
  
  /// Creates a new cursor with a map key in the path.
  Cursor mapKey(dynamic key) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      path: _path.mapKey(key),
    );
  }
}