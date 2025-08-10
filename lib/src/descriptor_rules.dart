import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pb.dart';

/// Extracts validation rules from FileDescriptorSet.
class DescriptorRules {
  final FileDescriptorSet descriptorSet;
  final ExtensionRegistry registry;
  
  // Cache for field rules by message and field name
  final Map<String, Map<String, FieldRules>> _fieldRulesCache = {};
  final Map<String, MessageRules> _messageRulesCache = {};
  
  DescriptorRules(this.descriptorSet, {ExtensionRegistry? extensionRegistry}) 
    : registry = extensionRegistry ?? ExtensionRegistry() {
    // Register the validation extensions if not already registered
    Validate.registerAllExtensions(registry);
  }
  
  /// Gets field rules for a specific field in a message.
  FieldRules? getFieldRules(String messageTypeName, String fieldName) {
    // Check cache first
    if (_fieldRulesCache.containsKey(messageTypeName)) {
      return _fieldRulesCache[messageTypeName]![fieldName];
    }
    
    // Parse the message type name to get package and message name
    final parts = messageTypeName.split('.');
    
    // Search through all files in the descriptor set
    for (final file in descriptorSet.file) {
      // Check if this file contains the message we're looking for
      if (!messageTypeName.startsWith(file.package)) continue;
      
      // Look for the message in this file
      final message = _findMessageDescriptor(file, messageTypeName);
      if (message != null) {
        // Cache all field rules for this message
        _cacheMessageFieldRules(messageTypeName, message);
        return _fieldRulesCache[messageTypeName]?[fieldName];
      }
    }
    
    return null;
  }
  
  /// Gets message-level rules for a message type.
  MessageRules? getMessageRules(String messageTypeName) {
    // Check cache first
    if (_messageRulesCache.containsKey(messageTypeName)) {
      return _messageRulesCache[messageTypeName];
    }
    
    // Search through all files in the descriptor set
    for (final file in descriptorSet.file) {
      // Check if this file contains the message we're looking for
      if (!messageTypeName.startsWith(file.package)) continue;
      
      // Look for the message in this file
      final message = _findMessageDescriptor(file, messageTypeName);
      if (message != null && message.hasOptions()) {
        // Extract message rules from options
        try {
          final rules = message.options.getExtension(Validate.message) as MessageRules?;
          if (rules != null) {
            _messageRulesCache[messageTypeName] = rules;
            return rules;
          }
        } catch (e) {
          // Extension not present
        }
      }
    }
    
    return null;
  }
  
  /// Finds a message descriptor by its fully qualified name.
  DescriptorProto? _findMessageDescriptor(FileDescriptorProto file, String fullName) {
    // Remove the package prefix to get the relative name
    final packagePrefix = file.package.isNotEmpty ? '${file.package}.' : '';
    if (!fullName.startsWith(packagePrefix)) return null;
    
    final relativeName = fullName.substring(packagePrefix.length);
    final nameParts = relativeName.split('.');
    
    // Start with top-level messages
    List<DescriptorProto> messages = file.messageType;
    DescriptorProto? current;
    
    for (int i = 0; i < nameParts.length; i++) {
      final part = nameParts[i];
      current = messages.firstWhere(
        (m) => m.name == part,
        orElse: () => DescriptorProto(),
      );
      
      if (!current.hasName()) return null;
      
      // If this is not the last part, look in nested types
      if (i < nameParts.length - 1) {
        messages = current.nestedType;
      }
    }
    
    return current;
  }
  
  /// Caches all field rules for a message.
  void _cacheMessageFieldRules(String messageTypeName, DescriptorProto message) {
    final fieldRules = <String, FieldRules>{};
    
    for (final field in message.field) {
      if (field.hasOptions()) {
        try {
          // Try to get field rules from the extension
          final rules = field.options.getExtension(Validate.field_1159) as FieldRules?;
          if (rules != null) {
            fieldRules[field.name] = rules;
          }
        } catch (e) {
          // Extension not present, continue
        }
      }
    }
    
    _fieldRulesCache[messageTypeName] = fieldRules;
  }
  
  /// Gets the fully qualified type name for a message.
  String getFullTypeName(GeneratedMessage message) {
    // Get the type name from the message's BuilderInfo
    final info = message.info_;
    final qualifiedName = info.qualifiedMessageName;
    
    // The qualified name from BuilderInfo includes the package
    return qualifiedName;
  }
  
  /// Gets enum descriptor for a given enum type name.
  EnumDescriptorProto? getEnumDescriptor(String enumTypeName) {
    // Search through all files in the descriptor set
    for (final file in descriptorSet.file) {
      // Check top-level enums
      for (final enumDesc in file.enumType) {
        final fullName = file.package.isNotEmpty 
            ? '${file.package}.${enumDesc.name}' 
            : enumDesc.name;
        if (fullName == enumTypeName) {
          return enumDesc;
        }
      }
      
      // Check nested enums in messages
      for (final message in file.messageType) {
        final enumDesc = _findNestedEnum(message, enumTypeName, file.package);
        if (enumDesc != null) {
          return enumDesc;
        }
      }
    }
    return null;
  }
  
  /// Recursively searches for nested enums.
  EnumDescriptorProto? _findNestedEnum(
      DescriptorProto message, String enumTypeName, String package) {
    final messagePrefix = package.isNotEmpty 
        ? '${package}.${message.name}' 
        : message.name;
    
    // Check enums in this message
    for (final enumDesc in message.enumType) {
      final fullName = '${messagePrefix}.${enumDesc.name}';
      if (fullName == enumTypeName) {
        return enumDesc;
      }
    }
    
    // Check nested messages
    for (final nestedMessage in message.nestedType) {
      final enumDesc = _findNestedEnum(
        nestedMessage, 
        enumTypeName, 
        messagePrefix
      );
      if (enumDesc != null) {
        return enumDesc;
      }
    }
    
    return null;
  }
  
  /// Gets the enum type name for a field.
  String? getFieldEnumTypeName(String messageTypeName, String fieldName) {
    // Search through all files in the descriptor set
    for (final file in descriptorSet.file) {
      // Check if this file contains the message we're looking for
      if (!messageTypeName.startsWith(file.package)) continue;
      
      // Look for the message in this file
      final message = _findMessageDescriptor(file, messageTypeName);
      if (message != null) {
        // Find the field
        for (final field in message.field) {
          if (field.name == fieldName) {
            // Check if this is an enum field
            if (field.type == FieldDescriptorProto_Type.TYPE_ENUM) {
              return field.typeName;
            }
          }
        }
      }
    }
    return null;
  }
  
  /// Checks if a field should be validated based on its rules.
  bool shouldValidateField(FieldRules? rules, dynamic value, FieldInfo field) {
    if (rules == null) return false;
    
    // Check ignore conditions
    if (rules.hasIgnore()) {
      switch (rules.ignore) {
        case Ignore.IGNORE_ALWAYS:
          return false;
        case Ignore.IGNORE_UNSPECIFIED:
          // Default behavior - ignore if unpopulated for fields that track presence
          if (value == null || _isDefaultValue(value, field)) {
            return false;
          }
          break;
        case Ignore.IGNORE_IF_ZERO_VALUE:
          if (_isDefaultValue(value, field)) {
            return false;
          }
          break;
        default:
          break;
      }
    }
    
    return true;
  }
  
  bool _isDefaultValue(dynamic value, FieldInfo field) {
    if (value == null) return true;
    
    // Check for default values based on field type
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    
    return false;
  }
}