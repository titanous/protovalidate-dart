/// Protocol Buffer validation for Dart.
/// 
/// Provides runtime validation of protobuf messages based on rules defined
/// in proto files using the buf.validate extensions.
library protovalidate;

export 'src/validator.dart' show Validator, ValidatorOptions, ValidationResult;
export 'src/error.dart' show 
    ProtovalidateError, 
    CompilationError, 
    RuntimeError, 
    ValidationError,
    Violation,
    Violations;