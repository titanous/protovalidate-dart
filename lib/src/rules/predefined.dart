import 'package:protobuf/protobuf.dart';
import 'package:protobuf/src/protobuf/extension_options.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto3.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';

/// Registry of predefined rule extensions and their associated CEL expressions.
/// 
/// Predefined rules are custom validation rules that are defined as extensions
/// on the various *Rules messages (e.g., FloatRules, Int32Rules, etc.).
/// Each extension has an associated CEL expression that defines the validation logic.
/// 
/// This class manages the registration and lookup of these predefined rules.
class PredefinedRulesRegistry {
  /// Map from extension to the predefined rules extracted from its options
  static final Map<Extension, PredefinedRules> _predefinedRulesByExtension = {};
  
  /// Map from extension field number to predefined rules (for quick lookup)
  static final Map<int, PredefinedRules> _predefinedRulesByNumber = {};
  
  /// Extension registry for deserializing options
  static final ExtensionRegistry _registry = ExtensionRegistry()
    ..add(Validate.predefined);
  
  /// Whether the registry has been initialized
  static bool _initialized = false;
  
  /// Initialize the registry with all known predefined rules.
  /// This should be called once at startup.
  static void initialize() {
    if (_initialized) return;
    
    // Register proto2 predefined rules (also used by proto3)
    _registerProto2Extensions();
    
    // Note: Proto editions are not yet supported by protoc-gen-dart
    
    _initialized = true;
  }
  
  /// Get predefined rules for a specific extension field number
  static PredefinedRules? getRulesForExtension(int fieldNumber) {
    if (!_initialized) {
      initialize();
    }
    return _predefinedRulesByNumber[fieldNumber];
  }
  
  /// Get predefined rules for a specific extension
  static PredefinedRules? getRulesForExtensionObject(Extension ext) {
    if (!_initialized) {
      initialize();
    }
    return _predefinedRulesByExtension[ext];
  }
  
  /// Check if an extension field number has predefined rules
  static bool hasPredefinedRules(int fieldNumber) {
    if (!_initialized) {
      initialize();
    }
    return _predefinedRulesByNumber.containsKey(fieldNumber);
  }
  
  /// Extract predefined rules from an extension's options
  static PredefinedRules? _extractPredefinedRules(Extension ext) {
    if (ext.optionsBytes == null || ext.optionsBytes!.isEmpty) {
      return null;
    }
    
    try {
      // Deserialize the FieldOptions
      final options = FieldOptions.fromBuffer(ext.optionsBytes!, _registry);
      
      // Check if the predefined extension is set
      if (!options.hasExtension(Validate.predefined)) {
        return null;
      }
      
      // Get the predefined rules
      return options.getExtension(Validate.predefined) as PredefinedRules;
    } catch (e) {
      // Failed to extract predefined rules
      print('Failed to extract predefined rules from extension: $e');
      return null;
    }
  }
  
  /// Register an extension with its predefined rules
  static void _registerExtension(Extension ext) {
    final rules = _extractPredefinedRules(ext);
    if (rules != null) {
      _predefinedRulesByExtension[ext] = rules;
      _predefinedRulesByNumber[ext.tagNumber] = rules;
    }
  }
  
  /// Register proto2 predefined rules extensions
  static void _registerProto2Extensions() {
    // Register all proto2 predefined rule extensions
    _registerExtension(Predefined_rules_proto2.floatAbsRangeProto2);
    _registerExtension(Predefined_rules_proto2.doubleAbsRangeProto2);
    _registerExtension(Predefined_rules_proto2.int32AbsInProto2);
    _registerExtension(Predefined_rules_proto2.int64AbsInProto2);
    _registerExtension(Predefined_rules_proto2.uint32EvenProto2);
    _registerExtension(Predefined_rules_proto2.uint64EvenProto2);
    _registerExtension(Predefined_rules_proto2.sint32EvenProto2);
    _registerExtension(Predefined_rules_proto2.sint64EvenProto2);
    _registerExtension(Predefined_rules_proto2.fixed32EvenProto2);
    _registerExtension(Predefined_rules_proto2.fixed64EvenProto2);
    _registerExtension(Predefined_rules_proto2.sfixed32EvenProto2);
    _registerExtension(Predefined_rules_proto2.sfixed64EvenProto2);
    _registerExtension(Predefined_rules_proto2.boolFalseProto2);
    _registerExtension(Predefined_rules_proto2.stringValidPathProto2);
    _registerExtension(Predefined_rules_proto2.bytesValidPathProto2);
    _registerExtension(Predefined_rules_proto2.enumNonZeroProto2);
    _registerExtension(Predefined_rules_proto2.repeatedAtLeastFiveProto2);
    _registerExtension(Predefined_rules_proto2.durationTooLongProto2);
    _registerExtension(Predefined_rules_proto2.timestampInRangeProto2);
  }
  
}

/// Helper class to check for predefined extensions on rule types
class PredefinedExtensionChecker {
  /// Get all predefined extensions set on a rules message
  static List<Extension> getSetPredefinedExtensions(GeneratedMessage rulesMessage) {
    final setExtensions = <Extension>[];
    
    // Map rule types to their relevant extensions
    final extensionsByType = <Type, List<Extension>>{
      FloatRules: [Predefined_rules_proto2.floatAbsRangeProto2],
      DoubleRules: [Predefined_rules_proto2.doubleAbsRangeProto2],
      Int32Rules: [Predefined_rules_proto2.int32AbsInProto2],
      Int64Rules: [Predefined_rules_proto2.int64AbsInProto2],
      UInt32Rules: [Predefined_rules_proto2.uint32EvenProto2],
      UInt64Rules: [Predefined_rules_proto2.uint64EvenProto2],
      SInt32Rules: [Predefined_rules_proto2.sint32EvenProto2],
      SInt64Rules: [Predefined_rules_proto2.sint64EvenProto2],
      Fixed32Rules: [Predefined_rules_proto2.fixed32EvenProto2],
      Fixed64Rules: [Predefined_rules_proto2.fixed64EvenProto2],
      SFixed32Rules: [Predefined_rules_proto2.sfixed32EvenProto2],
      SFixed64Rules: [Predefined_rules_proto2.sfixed64EvenProto2],
      BoolRules: [Predefined_rules_proto2.boolFalseProto2],
      StringRules: [Predefined_rules_proto2.stringValidPathProto2],
      BytesRules: [Predefined_rules_proto2.bytesValidPathProto2],
      EnumRules: [Predefined_rules_proto2.enumNonZeroProto2],
      RepeatedRules: [Predefined_rules_proto2.repeatedAtLeastFiveProto2],
      DurationRules: [Predefined_rules_proto2.durationTooLongProto2],
      TimestampRules: [Predefined_rules_proto2.timestampInRangeProto2],
    };
    
    // Get extensions for this specific message type
    final relevantExtensions = extensionsByType[rulesMessage.runtimeType];
    
    if (relevantExtensions == null) {
      // Fallback: check all extensions
      final allExtensions = [
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
        Predefined_rules_proto2.boolFalseProto2,
        Predefined_rules_proto2.stringValidPathProto2,
        Predefined_rules_proto2.bytesValidPathProto2,
        Predefined_rules_proto2.enumNonZeroProto2,
        Predefined_rules_proto2.repeatedAtLeastFiveProto2,
        Predefined_rules_proto2.durationTooLongProto2,
        Predefined_rules_proto2.timestampInRangeProto2,
      ];
      
      for (final ext in allExtensions) {
        try {
          if (rulesMessage.hasExtension(ext)) {
            setExtensions.add(ext);
          }
        } catch (e) {
          // Extension not applicable to this message type
        }
      }
    } else {
      // Check which extensions are set
      for (final ext in relevantExtensions) {
        try {
          if (rulesMessage.hasExtension(ext)) {
            setExtensions.add(ext);
          }
        } catch (e) {
          // Extension not applicable to this message type
        }
      }
    }
    
    return setExtensions;
  }
  
  /// Get predefined rules for extensions set on a rules message
  static List<PredefinedRules> getPredefinedRulesForMessage(GeneratedMessage rulesMessage) {
    final rules = <PredefinedRules>[];
    final extensions = getSetPredefinedExtensions(rulesMessage);
    
    for (final ext in extensions) {
      final predefinedRules = PredefinedRulesRegistry.getRulesForExtensionObject(ext);
      if (predefinedRules != null) {
        rules.add(predefinedRules);
      }
    }
    
    return rules;
  }
}