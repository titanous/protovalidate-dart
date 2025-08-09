import 'dart:io';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/protovalidate.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/harness/harness.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/any.pb.dart' as $1;

// Import all test case messages
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/bool.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/bytes.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/numbers.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/strings.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/enums.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/repeated.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/maps.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/messages.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/oneofs.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/wkt_any.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/wkt_duration.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/wkt_timestamp.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/wkt_wrappers.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/wkt_nested.pb.dart';
import 'package:protovalidate/src/gen/buf/validate/conformance/cases/kitchen_sink.pb.dart';

void main() async {
  // Read the request from stdin
  final input = <int>[];
  await for (final chunk in stdin) {
    input.addAll(chunk);
  }
  
  final request = TestConformanceRequest()..mergeFromBuffer(input);
  final response = TestConformanceResponse();
  
  // Create validator
  final validator = Validator();
  
  // Process each test case
  for (final entry in request.cases.entries) {
    final caseName = entry.key;
    final anyMessage = entry.value;
    
    try {
      // Deserialize the message from Any
      final message = _deserializeAny(anyMessage);
      
      // Validate the message
      final result = validator.validate(message);
      
      // Store the result
      final testResult = TestResult();
      
      if (result.isValid) {
        testResult.success = true;
      } else if (result.isInvalid) {
        if (result.violations != null) {
          testResult.validationError = result.violations!;
        }
      } else if (result.isCompilationError) {
        testResult.compilationError = result.error.toString();
      } else if (result.isRuntimeError) {
        testResult.runtimeError = result.error.toString();
      } else {
        testResult.unexpectedError = 'Unknown error occurred';
      }
      
      response.results[caseName] = testResult;
    } catch (e, stackTrace) {
      // Handle any unexpected errors
      final testResult = TestResult()
        ..unexpectedError = 'Error: $e\nStack: $stackTrace';
      response.results[caseName] = testResult;
    }
  }
  
  // Write the response to stdout
  final output = response.writeToBuffer();
  stdout.add(output);
  await stdout.flush();
}

GeneratedMessage _deserializeAny($1.Any any) {
  // Extract the type URL to determine which message type to create
  final typeUrl = any.typeUrl;
  final typeName = typeUrl.split('/').last;
  
  // Create the appropriate message type based on the type URL
  // This is a simplified mapping - in production, this would be more dynamic
  GeneratedMessage? message;
  
  switch (typeName) {
    // Bool cases
    case 'buf.validate.conformance.cases.BoolNone':
      message = BoolNone();
      break;
    case 'buf.validate.conformance.cases.BoolConstTrue':
      message = BoolConstTrue();
      break;
    case 'buf.validate.conformance.cases.BoolConstFalse':
      message = BoolConstFalse();
      break;
    case 'buf.validate.conformance.cases.BoolExample':
      message = BoolExample();
      break;
      
    // Bytes cases
    case 'buf.validate.conformance.cases.BytesNone':
      message = BytesNone();
      break;
    case 'buf.validate.conformance.cases.BytesConst':
      message = BytesConst();
      break;
      
    // Number cases
    case 'buf.validate.conformance.cases.Int32None':
      message = Int32None();
      break;
    case 'buf.validate.conformance.cases.Int64None':
      message = Int64None();
      break;
    case 'buf.validate.conformance.cases.UInt32None':
      message = UInt32None();
      break;
    case 'buf.validate.conformance.cases.UInt64None':
      message = UInt64None();
      break;
    case 'buf.validate.conformance.cases.FloatNone':
      message = FloatNone();
      break;
    case 'buf.validate.conformance.cases.DoubleNone':
      message = DoubleNone();
      break;
      
    // String cases
    case 'buf.validate.conformance.cases.StringNone':
      message = StringNone();
      break;
    case 'buf.validate.conformance.cases.StringConst':
      message = StringConst();
      break;
      
    // Add more cases as needed
    default:
      // For now, return a compilation error for unknown types
      stderr.writeln('Warning: Unknown message type: $typeName');
      throw UnimplementedError('Message type not yet supported: $typeName');
  }
  
  message.mergeFromBuffer(any.value);
  return message;
}