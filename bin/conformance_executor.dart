import 'dart:io';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/protovalidate.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/harness/harness.pb.dart';
import 'package:protovalidate/src/conformance_registry_marker.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/predefined_rules_proto2.pb.dart' as predefined_proto2;

void main() async {
  // Read the request from stdin
  final input = <int>[];
  await for (final chunk in stdin) {
    input.addAll(chunk);
  }
  
  // Create extension registry and register validation extensions
  final extensionRegistry = ExtensionRegistry();
  Validate.registerAllExtensions(extensionRegistry);
  
  // Register predefined rule extensions so they can be parsed from constraint messages
  predefined_proto2.Predefined_rules_proto2.registerAllExtensions(extensionRegistry);
  
  final request = TestConformanceRequest()..mergeFromBuffer(input, extensionRegistry);
  final response = TestConformanceResponse();
  
  // Create validator with FileDescriptorSet if provided
  final validator = Validator(
    fileDescriptorSet: request.hasFdset() ? request.fdset : null,
    options: ValidatorOptions(
      extensionRegistry: extensionRegistry,
    ),
  );
  
  // Create a type registry for unpacking Any messages
  final typeRegistry = createConformanceRegistry();
  
  // Process each test case
  for (final entry in request.cases.entries) {
    final caseName = entry.key;
    final anyMessage = entry.value;
    
    try {
      // Deserialize the message from Any using the registry
      final message = unpackAnyWithRegistry(anyMessage, typeRegistry);
      if (message == null) {
        final testResult = TestResult()
          ..unexpectedError = 'Unable to unpack Any with type_url "${anyMessage.typeUrl}"';
        response.results[caseName] = testResult;
        continue;
      }
      
      // Validate the message
      final result = validator.validate(message);
      
      // Store the result
      final testResult = TestResult();
      
      if (result.isValid) {
        testResult.success = true;
      } else if (result.isInvalid) {
        if (result.violations != null) {
          testResult.validationError = result.violations!;
        } else {
          // This shouldn't happen, but handle it
          testResult.unexpectedError = 'Invalid result without violations';
        }
      } else if (result.isCompilationError) {
        testResult.compilationError = result.error.toString();
      } else if (result.isRuntimeError) {
        testResult.runtimeError = result.error.toString();
      } else {
        testResult.unexpectedError = 'Unknown error occurred';
      }
      
      response.results[caseName] = testResult;
    } catch (e) {
      // Handle any unexpected errors
      final testResult = TestResult()
        ..unexpectedError = 'Error: $e';
      response.results[caseName] = testResult;
    }
  }
  
  // Write the response to stdout
  try {
    final output = response.writeToBuffer();
    stdout.add(output);
    await stdout.flush();
    await stdout.close();
  } catch (e, stack) {
    stderr.writeln('[FATAL] Failed to write response: $e');
    stderr.writeln('Stack: $stack');
    exit(1);
  }
}