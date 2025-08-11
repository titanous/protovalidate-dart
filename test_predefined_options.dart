import 'package:protobuf/protobuf.dart';
import 'package:protobuf/src/protobuf/extension_options.dart';
import 'lib/src/gen/buf/validate/validate.pb.dart';
import 'lib/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart';
import 'lib/src/gen/google/protobuf/descriptor.pb.dart';
import 'lib/src/rules/predefined.dart';

void main() {
  // Initialize the registry
  PredefinedRulesRegistry.initialize();
  
  // Test extracting predefined rules from an extension
  final ext = Predefined_rules_proto2.floatAbsRangeProto2;
  
  print('Extension: floatAbsRangeProto2');
  print('Tag number: ${ext.tagNumber}');
  print('Has options bytes: ${ext.optionsBytes != null}');
  
  if (ext.optionsBytes != null) {
    print('Options bytes length: ${ext.optionsBytes!.length}');
    
    // Try to extract predefined rules
    final rules = PredefinedRulesRegistry.getRulesForExtensionObject(ext);
    if (rules != null) {
      print('Successfully extracted predefined rules!');
      print('Number of CEL rules: ${rules.cel.length}');
      for (final rule in rules.cel) {
        print('  Rule ID: ${rule.id}');
        print('  Expression: ${rule.expression}');
        print('  Message: ${rule.message}');
      }
    } else {
      print('Failed to extract predefined rules');
    }
  }
  
  // Test with a FloatRules message
  final floatRules = FloatRules();
  floatRules.setExtension(Predefined_rules_proto2.floatAbsRangeProto2, 1.5);
  
  print('\nTesting with FloatRules message:');
  print('Message type: ${floatRules.runtimeType}');
  print('Has float extension: ${floatRules.hasExtension(Predefined_rules_proto2.floatAbsRangeProto2)}');
  print('Float extension value: ${floatRules.getExtension(Predefined_rules_proto2.floatAbsRangeProto2)}');
  
  final setExtensions = PredefinedExtensionChecker.getSetPredefinedExtensions(floatRules);
  print('Number of set extensions: ${setExtensions.length}');
  
  final predefinedRules = PredefinedExtensionChecker.getPredefinedRulesForMessage(floatRules);
  print('Number of predefined rules: ${predefinedRules.length}');
  
  for (final rules in predefinedRules) {
    for (final rule in rules.cel) {
      print('  Found rule: ${rule.id}');
    }
  }
}