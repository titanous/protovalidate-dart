import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;

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

/// Represents a single validation violation during validation.
class Violation {
  /// The path to the field that caused the violation.
  final String fieldPath;
  
  /// The field path elements for the protobuf representation.
  final List<pb.FieldPathElement>? fieldPathElements;
  
  /// The constraint ID that was violated.
  final String constraintId;
  
  /// A human-readable message describing the violation.
  final String message;
  
  /// Optional rule path for debugging.
  final String? rulePath;
  
  /// The rule path elements for the protobuf representation.
  final List<pb.FieldPathElement>? rulePathElements;
  
  /// Whether this violation is for a map key.
  final bool forKey;
  
  const Violation({
    required this.fieldPath,
    this.fieldPathElements,
    required this.constraintId,
    required this.message,
    this.rulePath,
    this.rulePathElements,
    this.forKey = false,
  });
  
  /// Converts this violation to a protobuf Violation.
  pb.Violation toProto() {
    final violation = pb.Violation()
      ..ruleId = constraintId
      ..message = message;
    
    // Use provided field path elements if available
    if (fieldPathElements != null && fieldPathElements!.isNotEmpty) {
      violation.field_5 = pb.FieldPath()..elements.addAll(fieldPathElements!);
    } else if (fieldPath.isNotEmpty) {
      // Fallback to parsing field path string
      final pathElements = <pb.FieldPathElement>[];
      final parts = fieldPath.split(RegExp(r'[.\[\]]'));
      
      for (final part in parts) {
        if (part.isEmpty) continue;
        
        // Check if it's an index
        final index = int.tryParse(part);
        if (index != null) {
          pathElements.add(pb.FieldPathElement()..fieldName = '[$index]');
        } else {
          pathElements.add(pb.FieldPathElement()..fieldName = part);
        }
      }
      
      violation.field_5 = pb.FieldPath()..elements.addAll(pathElements);
    }
    
    // Add rule path if provided
    if (rulePathElements != null && rulePathElements!.isNotEmpty) {
      violation.rule = pb.FieldPath()..elements.addAll(rulePathElements!);
    }
    
    if (forKey) {
      violation.forKey = true;
    }
    
    return violation;
  }
}

/// An error that occurs during validation.
class ValidationError extends ProtovalidateError {
  final List<Violation> violations;
  
  ValidationError(this.violations) 
      : super('Validation failed');
  
  /// Converts violations to protobuf format.
  pb.Violations toProto() {
    final result = pb.Violations();
    for (final violation in violations) {
      result.violations.add(violation.toProto());
    }
    return result;
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('ValidationError: ');
    buffer.writeln('${violations.length} violation(s)');
    for (final violation in violations) {
      buffer.writeln('  - [${violation.fieldPath}]: ${violation.message}');
    }
    return buffer.toString();
  }
}