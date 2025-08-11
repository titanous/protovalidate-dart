import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';

/// Predefined rules discovery and CEL compilation for validation rules.
/// 
/// Predefined rules are custom validation rules defined as extensions on
/// various *Rules messages. This implementation dynamically discovers 
/// predefined rules and compiles them as CEL expressions, following the ES/Go pattern.
/// 
/// The CEL expressions are stored in the extension field descriptor options
/// under the `buf.validate.predefined` extension, not as extension values.
class PredefinedRulesManager {
  /// Extension registry for parsing field options
  static final _optionsRegistry = ExtensionRegistry()
    ..add(Validate.predefined);
  
  /// Get all predefined CEL rules set on a rules message
  static List<Rule> getPredefinedCelRules(GeneratedMessage rulesMessage) {
    final celRules = <Rule>[];
    
    // Iterate through all known predefined extensions to find ones set on this message
    // This replaces the hardcoded type mapping with dynamic discovery
    for (final extension in _getAllKnownExtensions()) {
      // Check if this extension is set on the rules message
      // hasExtension() now properly validates both extension applicability and field presence
      if (rulesMessage.hasExtension(extension)) {
        // Extract predefined CEL rules from the extension's field descriptor options
        final predefinedRules = _extractPredefinedRulesFromExtension(extension);
        if (predefinedRules != null) {
          // Only add CEL rules from this specific extension
          celRules.addAll(predefinedRules.cel);
        }
      }
    }
    
    return celRules;
  }
  
  /// Extract predefined rules from an extension's field descriptor options
  static PredefinedRules? _extractPredefinedRulesFromExtension(Extension extension) {
    // Get the options bytes from the extension definition
    final optionsBytes = extension.optionsBytes;
    if (optionsBytes == null || optionsBytes.isEmpty) {
      return null;
    }
    
    try {
      // Parse the options bytes as FieldOptions
      final fieldOptions = FieldOptions.fromBuffer(optionsBytes, _optionsRegistry);
      
      // Extract the predefined rules from the buf.validate.predefined extension
      if (fieldOptions.hasExtension(Validate.predefined)) {
        return fieldOptions.getExtension(Validate.predefined) as PredefinedRules;
      }
    } catch (e) {
      // Failed to parse options or extract predefined rules
      // This could happen if the options format is not what we expect
    }
    
    return null;
  }
  
  /// Get all known predefined rule extensions
  /// This is the consolidated list of all predefined extensions, not tied to specific types
  static List<Extension> _getAllKnownExtensions() {
    return [
      // Numeric rule extensions
      Predefined_rules_proto2.floatAbsRangeProto2,
      Predefined_rules_proto2.doubleAbsRangeProto2,
      Predefined_rules_proto2.int32AbsInProto2,
      Predefined_rules_proto2.int64AbsInProto2,
      Predefined_rules_proto2.uint32EvenProto2,
      Predefined_rules_proto2.uint64EvenProto2,
      Predefined_rules_proto2.sint32EvenProto2,
      Predefined_rules_proto2.sint64EvenProto2,
      Predefined_rules_proto2.fixed32EvenProto2,
      Predefined_rules_proto2.fixed64EvenProto2,
      Predefined_rules_proto2.sfixed32EvenProto2,
      Predefined_rules_proto2.sfixed64EvenProto2,
      
      // Other rule extensions
      Predefined_rules_proto2.boolFalseProto2,
      Predefined_rules_proto2.stringValidPathProto2,
      Predefined_rules_proto2.bytesValidPathProto2,
      Predefined_rules_proto2.enumNonZeroProto2,
      Predefined_rules_proto2.repeatedAtLeastFiveProto2,
      Predefined_rules_proto2.durationTooLongProto2,
      Predefined_rules_proto2.timestampInRangeProto2,
    ];
  }
}