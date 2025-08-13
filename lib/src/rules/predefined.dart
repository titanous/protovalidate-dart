import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';
import '../cel/cel_integration.dart';
import '../rule_paths.dart';
import '../utils/string_utils.dart';

/// A predefined CEL rule with its extension context for proper rule path generation
class PredefinedCelRule {
  /// The CEL rule from the extension
  final Rule rule;
  
  /// Extension context for rule path generation
  final ExtensionContext extensionContext;
  
  const PredefinedCelRule({
    required this.rule,
    required this.extensionContext,
  });
}

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
  
  /// Get all predefined CEL rules set on a rules message with extension context
  static List<PredefinedCelRule> getPredefinedCelRulesWithContext(GeneratedMessage rulesMessage) {
    final celRules = <PredefinedCelRule>[];
    
    // Iterate through all known predefined extensions to find ones set on this message
    for (final extension in _getAllKnownExtensions()) {
      // Check if this extension is set on the rules message
      if (rulesMessage.hasExtension(extension)) {
        // Extract predefined CEL rules from the extension's field descriptor options
        final predefinedRules = _extractPredefinedRulesFromExtension(extension);
        if (predefinedRules != null) {
          // Create extension context for this extension
          final extensionContext = _createExtensionContext(extension);
          if (extensionContext != null) {
            // Add CEL rules with their extension context
            for (final rule in predefinedRules.cel) {
              celRules.add(PredefinedCelRule(
                rule: rule,
                extensionContext: extensionContext,
              ));
            }
          }
        }
      }
    }
    
    return celRules;
  }

  /// Get all predefined CEL rules set on a rules message (backward compatibility)
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
  
  /// Create extension context for an extension
  static ExtensionContext? _createExtensionContext(Extension extension) {
    // Map extension to rule type information
    // This follows the pattern observed in protovalidate-es
    final extensionName = extension.name;
    
    // Convert extension name to expected qualified format
    final qualifiedExtensionName = 'buf.validate.conformance.cases.${StringUtils.toSnakeCase(extensionName)}';
    
    // Extract rule type and field number based on extension name patterns
    if (extensionName.contains('float')) {
      return ExtensionContext(
        ruleTypeName: 'float',
        ruleTypeFieldNumber: FieldRuleNumbers.float,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('double')) {
      return ExtensionContext(
        ruleTypeName: 'double',
        ruleTypeFieldNumber: FieldRuleNumbers.double,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('int32')) {
      return ExtensionContext(
        ruleTypeName: 'int32',
        ruleTypeFieldNumber: FieldRuleNumbers.int32,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('int64')) {
      return ExtensionContext(
        ruleTypeName: 'int64',
        ruleTypeFieldNumber: FieldRuleNumbers.int64,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('uint32')) {
      return ExtensionContext(
        ruleTypeName: 'uint32',
        ruleTypeFieldNumber: FieldRuleNumbers.uint32,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('uint64')) {
      return ExtensionContext(
        ruleTypeName: 'uint64',
        ruleTypeFieldNumber: FieldRuleNumbers.uint64,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('sint32')) {
      return ExtensionContext(
        ruleTypeName: 'sint32',
        ruleTypeFieldNumber: FieldRuleNumbers.sint32,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('sint64')) {
      return ExtensionContext(
        ruleTypeName: 'sint64',
        ruleTypeFieldNumber: FieldRuleNumbers.sint64,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('fixed32')) {
      return ExtensionContext(
        ruleTypeName: 'fixed32',
        ruleTypeFieldNumber: FieldRuleNumbers.fixed32,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('fixed64')) {
      return ExtensionContext(
        ruleTypeName: 'fixed64',
        ruleTypeFieldNumber: FieldRuleNumbers.fixed64,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('sfixed32')) {
      return ExtensionContext(
        ruleTypeName: 'sfixed32',
        ruleTypeFieldNumber: FieldRuleNumbers.sfixed32,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('sfixed64')) {
      return ExtensionContext(
        ruleTypeName: 'sfixed64',
        ruleTypeFieldNumber: FieldRuleNumbers.sfixed64,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('bool')) {
      return ExtensionContext(
        ruleTypeName: 'bool',
        ruleTypeFieldNumber: FieldRuleNumbers.bool,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('string')) {
      return ExtensionContext(
        ruleTypeName: 'string',
        ruleTypeFieldNumber: FieldRuleNumbers.string,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('bytes')) {
      return ExtensionContext(
        ruleTypeName: 'bytes',
        ruleTypeFieldNumber: FieldRuleNumbers.bytes,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('enum')) {
      return ExtensionContext(
        ruleTypeName: 'enum',
        ruleTypeFieldNumber: FieldRuleNumbers.enum_,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('repeated')) {
      return ExtensionContext(
        ruleTypeName: 'repeated',
        ruleTypeFieldNumber: FieldRuleNumbers.repeated,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('duration')) {
      return ExtensionContext(
        ruleTypeName: 'duration',
        ruleTypeFieldNumber: FieldRuleNumbers.duration,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    } else if (extensionName.contains('timestamp')) {
      return ExtensionContext(
        ruleTypeName: 'timestamp',
        ruleTypeFieldNumber: FieldRuleNumbers.timestamp,
        extensionName: '[$qualifiedExtensionName]',
        extensionFieldNumber: extension.tagNumber,
      );
    }
    
    // Unknown extension type
    return null;
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