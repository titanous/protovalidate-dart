import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/error.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart' as pb;
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';
import 'builder.dart';
import 'cursor.dart';
import 'descriptor_rules.dart';
import 'evaluator.dart';

/// Options for creating a validator.
class ValidatorOptions {
  /// To validate messages with user-defined predefined rules, pass the extensions
  /// to the validator via the registry.
  final ExtensionRegistry? extensionRegistry;
  
  /// With this option enabled, validation fails on the first rule violation
  /// encountered. By default, all violations are accumulated.
  final bool failFast;
  
  /// With this option enabled, proto2 fields with the `required` label are
  /// validated to be set.
  final bool legacyRequired;
  
  const ValidatorOptions({
    this.extensionRegistry,
    this.failFast = false,
    this.legacyRequired = false,
  });
}

/// A validator that validates protobuf messages based on validation rules.
class Validator {
  final ValidatorOptions _options;
  final FileDescriptorSet? _fileDescriptorSet;
  final DescriptorRules? _descriptorRules;
  final EvaluatorBuilder _builder;
  final Map<String, Evaluator> _evaluatorCache = {};
  
  Validator({
    ValidatorOptions? options,
    FileDescriptorSet? fileDescriptorSet,
  }) : _options = options ?? const ValidatorOptions(),
       _fileDescriptorSet = fileDescriptorSet,
       _descriptorRules = fileDescriptorSet != null 
         ? DescriptorRules(fileDescriptorSet, extensionRegistry: options?.extensionRegistry)
         : null,
       _builder = EvaluatorBuilder(
         descriptorRules: fileDescriptorSet != null 
           ? DescriptorRules(fileDescriptorSet, extensionRegistry: options?.extensionRegistry)
           : null,
       );
  
  /// Validate the given message and return the result.
  ValidationResult validate(GeneratedMessage message) {
    try {
      // Create a cursor for tracking violations
      final cursor = Cursor.create(failFast: _options.failFast);
      
      // Build evaluator for this message type (with caching)
      final messageType = message.info_.qualifiedMessageName;
      final evaluator = _evaluatorCache[messageType] ??= _builder.buildForMessage(message);
      
      // Run validation
      evaluator.evaluate(message, cursor);
      
      // Check for violations
      if (cursor.violated) {
        final validationError = ValidationError(cursor.violations);
        return ValidationResult.invalid(validationError.toProto());
      }
      
      return ValidationResult.valid();
    } catch (e) {
      if (e is CompilationError) {
        return ValidationResult.compilationError(e);
      }
      if (e is RuntimeError) {
        return ValidationResult.runtimeError(e);
      }
      if (e is ValidationError) {
        return ValidationResult.invalid(e.toProto());
      }
      return ValidationResult.runtimeError(
        RuntimeError('Unexpected error: $e'),
      );
    }
  }
}

/// The result of a validation.
class ValidationResult {
  final bool isValid;
  final bool isInvalid;
  final bool isCompilationError;
  final bool isRuntimeError;
  final pb.Violations? violations;
  final ProtovalidateError? error;
  
  const ValidationResult._({
    required this.isValid,
    required this.isInvalid,
    required this.isCompilationError,
    required this.isRuntimeError,
    this.violations,
    this.error,
  });
  
  /// Creates a valid result.
  factory ValidationResult.valid() {
    return const ValidationResult._(
      isValid: true,
      isInvalid: false,
      isCompilationError: false,
      isRuntimeError: false,
    );
  }
  
  /// Creates an invalid result with violations.
  factory ValidationResult.invalid(pb.Violations violations) {
    return ValidationResult._(
      isValid: false,
      isInvalid: true,
      isCompilationError: false,
      isRuntimeError: false,
      violations: violations,
    );
  }
  
  /// Creates a compilation error result.
  factory ValidationResult.compilationError(CompilationError error) {
    return ValidationResult._(
      isValid: false,
      isInvalid: false,
      isCompilationError: true,
      isRuntimeError: false,
      error: error,
    );
  }
  
  /// Creates a runtime error result.
  factory ValidationResult.runtimeError(RuntimeError error) {
    return ValidationResult._(
      isValid: false,
      isInvalid: false,
      isCompilationError: false,
      isRuntimeError: true,
      error: error,
    );
  }
}