import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';

export 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' 
    show Violations, Violation;

/// Base class for all protovalidate errors.
abstract class ProtovalidateError implements Exception {
  final String message;
  
  const ProtovalidateError(this.message);
  
  @override
  String toString() => message;
}

/// An error that occurs during compilation of validation rules.
class CompilationError extends ProtovalidateError {
  const CompilationError(super.message);
  
  @override
  String toString() => 'CompilationError: $message';
}

/// An error that occurs during runtime evaluation of validation rules.
class RuntimeError extends ProtovalidateError {
  const RuntimeError(super.message);
  
  @override
  String toString() => 'RuntimeError: $message';
}

/// An error that occurs during validation.
class ValidationError extends ProtovalidateError {
  final Violations violations;
  
  const ValidationError(this.violations) 
      : super('Validation failed');
  
  @override
  String toString() {
    final buffer = StringBuffer('ValidationError: ');
    buffer.writeln('${violations.violations.length} violation(s)');
    for (final violation in violations.violations) {
      final fieldPath = violation.hasField_5() 
          ? violation.field_5.elements.join('.') 
          : 'unknown';
      buffer.writeln('  - [$fieldPath]: ${violation.message}');
    }
    return buffer.toString();
  }
}

/// Represents a single validation violation.
class Violation {
  /// The path to the field that caused the violation.
  final String fieldPath;
  
  /// The constraint ID that was violated.
  final String constraintId;
  
  /// A human-readable message describing the violation.
  final String message;
  
  const Violation({
    required this.fieldPath,
    required this.constraintId,
    required this.message,
  });
}