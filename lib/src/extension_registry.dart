import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';

/// Registry for validation rule extensions.
///
/// This class provides a central registry for buf.validate extensions.
/// User-defined predefined rule extensions should be registered here.
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
    // Register core buf.validate extensions
    _registry.add(Validate.field_1159);
    _registry.add(Validate.message);
    _registry.add(Validate.oneof);
    _registry.add(Validate.predefined);

    _initialized = true;
  }

  /// Register user-defined extensions with predefined rules.
  /// Call this before validating messages that use custom predefined rules.
  static void registerExtensions(void Function(ExtensionRegistry) registrar) {
    registrar(_registry);
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
