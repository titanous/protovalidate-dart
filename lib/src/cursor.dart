import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;
import 'error.dart';
import 'field_path.dart';

/// Cursor maintains a field path and tracks violations during validation.
/// This implementation matches the reference Go/TypeScript implementations.
class Cursor {
  final bool failFast;
  final List<Violation> _violations;
  final FieldPath _fieldPath;
  
  Cursor({
    required this.failFast,
    List<Violation>? violations,
    FieldPath? fieldPath,
  }) : _violations = violations ?? [],
       _fieldPath = fieldPath ?? FieldPath();
  
  /// Creates a new cursor for validation.
  static Cursor create({bool failFast = false}) {
    return Cursor(failFast: failFast);
  }
  
  /// Returns true if any violations have been recorded.
  bool get violated => _violations.isNotEmpty;
  
  /// Returns the list of violations.
  List<Violation> get violations => List.unmodifiable(_violations);
  
  /// Records a validation violation with proper rule path construction.
  void violate({
    required String message,
    required String constraintId,
    RulePath? rulePath,
    bool forKey = false,
  }) {
    _violations.add(Violation(
      fieldPath: _fieldPath.toFieldPathString(),
      fieldPathElements: _fieldPath.toProtoElements(),
      constraintId: constraintId,
      message: message,
      rulePath: '', // Will be computed from rulePath if provided
      rulePathElements: rulePath?.toProtoElements() ?? [],
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
  FieldPath getPath() => _fieldPath.clone();
  
  /// Creates a new cursor with an additional field in the path.
  Cursor field(FieldInfo field) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      fieldPath: _fieldPath.field(field),
    );
  }
  
  /// Creates a new cursor with a list index in the path.
  Cursor listIndex(int index) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      fieldPath: _fieldPath.listIndex(index),
    );
  }
  
  /// Creates a new cursor with a map key in the path.
  Cursor mapKey(dynamic key) {
    return Cursor(
      failFast: failFast,
      violations: _violations,
      fieldPath: _fieldPath.mapKey(key),
    );
  }
}