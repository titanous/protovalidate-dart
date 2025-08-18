import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
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
  static final _optionsRegistry = ExtensionRegistry()..add(Validate.predefined);

  /// Get all predefined CEL rules set on a rules message with extension context
  static List<PredefinedCelRule> getPredefinedCelRulesWithContext(
      GeneratedMessage rulesMessage,
      [ExtensionRegistry? registry]) {
    final celRules = <PredefinedCelRule>[];

    // Get extensions for this message type from the registry
    final extensions = _getExtensionsForMessage(rulesMessage, registry);

    // Iterate through all extensions to find ones with predefined rules
    for (final extension in extensions) {
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

  /// Create extension context for an extension
  static ExtensionContext? _createExtensionContext(Extension extension) {
    // Build the qualified extension name
    // Use the typeName if available (from updated protoc plugin),
    // otherwise fallback to just the extension name
    // Convert to snake_case to match expected format
    var qualifiedExtensionName = extension.typeName != null
        ? _convertToSnakeCase(extension.typeName!)
        : StringUtils.toSnakeCase(extension.name);

    // Remove brackets if they're already present in typeName
    if (qualifiedExtensionName.startsWith('[') &&
        qualifiedExtensionName.endsWith(']')) {
      qualifiedExtensionName = qualifiedExtensionName.substring(
          1, qualifiedExtensionName.length - 1);
    }

    // Map extension to rule type information based on extendee
    // The extendee tells us which Rules message this extension applies to
    final extendee = extension.extendee;

    // Create a mapping from Rules message names to field information
    final ruleTypeInfo = _getRuleTypeInfo(extendee);
    if (ruleTypeInfo == null) {
      return null;
    }

    return ExtensionContext(
      ruleTypeName: ruleTypeInfo.ruleTypeName,
      ruleTypeFieldNumber: ruleTypeInfo.fieldNumber,
      extensionName: '[${qualifiedExtensionName}]',
      extensionFieldNumber: extension.tagNumber,
    );
  }

  /// Get rule type information from the extendee message name
  static ({String ruleTypeName, int fieldNumber})? _getRuleTypeInfo(
      String extendee) {
    // Map from Rules message names to their corresponding field info
    const ruleTypeMapping = {
      'buf.validate.FloatRules': ('float', FieldRuleNumbers.float),
      'buf.validate.DoubleRules': ('double', FieldRuleNumbers.double),
      'buf.validate.Int32Rules': ('int32', FieldRuleNumbers.int32),
      'buf.validate.Int64Rules': ('int64', FieldRuleNumbers.int64),
      'buf.validate.UInt32Rules': ('uint32', FieldRuleNumbers.uint32),
      'buf.validate.UInt64Rules': ('uint64', FieldRuleNumbers.uint64),
      'buf.validate.SInt32Rules': ('sint32', FieldRuleNumbers.sint32),
      'buf.validate.SInt64Rules': ('sint64', FieldRuleNumbers.sint64),
      'buf.validate.Fixed32Rules': ('fixed32', FieldRuleNumbers.fixed32),
      'buf.validate.Fixed64Rules': ('fixed64', FieldRuleNumbers.fixed64),
      'buf.validate.SFixed32Rules': ('sfixed32', FieldRuleNumbers.sfixed32),
      'buf.validate.SFixed64Rules': ('sfixed64', FieldRuleNumbers.sfixed64),
      'buf.validate.BoolRules': ('bool', FieldRuleNumbers.bool),
      'buf.validate.StringRules': ('string', FieldRuleNumbers.string),
      'buf.validate.BytesRules': ('bytes', FieldRuleNumbers.bytes),
      'buf.validate.EnumRules': ('enum', FieldRuleNumbers.enum_),
      'buf.validate.MessageRules': ('message', FieldRuleNumbers.message),
      'buf.validate.RepeatedRules': ('repeated', FieldRuleNumbers.repeated),
      'buf.validate.MapRules': ('map', FieldRuleNumbers.map),
      'buf.validate.AnyRules': ('any', FieldRuleNumbers.any),
      'buf.validate.DurationRules': ('duration', FieldRuleNumbers.duration),
      'buf.validate.TimestampRules': ('timestamp', FieldRuleNumbers.timestamp),
    };

    final typeInfo = ruleTypeMapping[extendee];
    if (typeInfo != null) {
      return (ruleTypeName: typeInfo.$1, fieldNumber: typeInfo.$2);
    }

    return null;
  }

  /// Extract predefined rules from an extension's field descriptor options
  static PredefinedRules? _extractPredefinedRulesFromExtension(
      Extension extension) {
    // Get the options bytes from the extension definition
    final optionsBytes = extension.optionsBytes;
    if (optionsBytes == null || optionsBytes.isEmpty) {
      return null;
    }

    try {
      // Parse the options bytes as FieldOptions
      final fieldOptions =
          FieldOptions.fromBuffer(optionsBytes, _optionsRegistry);

      // Extract the predefined rules from the buf.validate.predefined extension
      if (fieldOptions.hasExtension(Validate.predefined)) {
        return fieldOptions.getExtension(Validate.predefined)
            as PredefinedRules;
      }
    } catch (e) {
      // Failed to parse options or extract predefined rules
      // This could happen if the options format is not what we expect
    }

    return null;
  }

  /// Get extensions that apply to a message from the registry
  static List<Extension> _getExtensionsForMessage(GeneratedMessage message,
      [ExtensionRegistry? registry]) {
    // If no registry provided, return empty list
    if (registry == null) {
      return [];
    }

    // Get the message's qualified name
    final messageName = message.info_.qualifiedMessageName;

    // Get all extensions for this message type from the registry
    final extensionsForMessage = registry.getExtensionsForMessage(messageName);

    // Filter for extensions that have predefined rules in their options
    final predefinedExtensions = <Extension>[];
    for (final ext in extensionsForMessage) {
      final predefinedRules = _extractPredefinedRulesFromExtension(ext);
      if (predefinedRules != null && predefinedRules.cel.isNotEmpty) {
        predefinedExtensions.add(ext);
      }
    }

    return predefinedExtensions;
  }

  /// Convert a qualified extension name to snake_case format
  /// e.g., "buf.validate.conformance.cases.sint32EvenProto2" -> "buf.validate.conformance.cases.sint32_even_proto2"
  static String _convertToSnakeCase(String typeName) {
    final parts = typeName.split('.');
    final lastPart = parts.last;
    final convertedLastPart = StringUtils.toSnakeCase(lastPart);
    parts[parts.length - 1] = convertedLastPart;
    return parts.join('.');
  }
}
