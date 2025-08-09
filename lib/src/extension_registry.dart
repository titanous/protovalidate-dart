import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';

/// Registry for validation rule extensions.
class ValidationExtensionRegistry {
  static final ExtensionRegistry _registry = ExtensionRegistry();
  
  static bool _initialized = false;
  
  /// Gets the extension registry with validation extensions registered.
  static ExtensionRegistry get registry {
    if (!_initialized) {
      _initialize();
    }
    return _registry;
  }
  
  static void _initialize() {
    // Register field validation extension
    _registry.add(Validate.field_1159);
    
    // Register message validation extension  
    _registry.add(Validate.message);
    
    // Register oneof validation extension
    _registry.add(Validate.oneof);
    
    // Register predefined validation extension
    _registry.add(Validate.predefined);
    
    _initialized = true;
  }
  
  /// Gets field rules from a field descriptor if present.
  static FieldRules? getFieldRules(FieldInfo field) {
    // For now, we'll need to implement this differently since Dart's protobuf
    // library doesn't expose field descriptors with extensions directly.
    // This will be revisited when we integrate with the actual validation flow.
    return null;
  }
  
  /// Gets message rules from a message descriptor if present.
  static MessageRules? getMessageRules(GeneratedMessage message) {
    // Similar to getFieldRules, this needs integration with descriptor access
    return null;
  }
}