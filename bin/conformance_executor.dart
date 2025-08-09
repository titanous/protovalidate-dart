import 'dart:io';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/protovalidate.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
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
  
  // Create extension registry and register validation extensions
  final registry = ExtensionRegistry();
  Validate.registerAllExtensions(registry);
  
  final request = TestConformanceRequest()..mergeFromBuffer(input, registry);
  final response = TestConformanceResponse();
  
  // Create validator with FileDescriptorSet if provided
  final validator = Validator(
    fileDescriptorSet: request.hasFdset() ? request.fdset : null,
  );
  
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
    case 'buf.validate.conformance.cases.StringIn':
      message = StringIn();
      break;
    case 'buf.validate.conformance.cases.StringNotIn':
      message = StringNotIn();
      break;
    case 'buf.validate.conformance.cases.StringLen':
      message = StringLen();
      break;
    case 'buf.validate.conformance.cases.StringMinLen':
      message = StringMinLen();
      break;
    case 'buf.validate.conformance.cases.StringMaxLen':
      message = StringMaxLen();
      break;
    case 'buf.validate.conformance.cases.StringMinMaxLen':
      message = StringMinMaxLen();
      break;
    case 'buf.validate.conformance.cases.StringEqualMinMaxLen':
      message = StringEqualMinMaxLen();
      break;
    case 'buf.validate.conformance.cases.StringLenBytes':
      message = StringLenBytes();
      break;
    case 'buf.validate.conformance.cases.StringMinBytes':
      message = StringMinBytes();
      break;
    case 'buf.validate.conformance.cases.StringMaxBytes':
      message = StringMaxBytes();
      break;
    case 'buf.validate.conformance.cases.StringMinMaxBytes':
      message = StringMinMaxBytes();
      break;
    case 'buf.validate.conformance.cases.StringEqualMinMaxBytes':
      message = StringEqualMinMaxBytes();
      break;
    case 'buf.validate.conformance.cases.StringPattern':
      message = StringPattern();
      break;
    case 'buf.validate.conformance.cases.StringPatternEscapes':
      message = StringPatternEscapes();
      break;
    case 'buf.validate.conformance.cases.StringPrefix':
      message = StringPrefix();
      break;
    case 'buf.validate.conformance.cases.StringContains':
      message = StringContains();
      break;
    case 'buf.validate.conformance.cases.StringNotContains':
      message = StringNotContains();
      break;
    case 'buf.validate.conformance.cases.StringSuffix':
      message = StringSuffix();
      break;
    case 'buf.validate.conformance.cases.StringEmail':
      message = StringEmail();
      break;
    case 'buf.validate.conformance.cases.StringNotEmail':
      message = StringNotEmail();
      break;
    case 'buf.validate.conformance.cases.StringAddress':
      message = StringAddress();
      break;
    case 'buf.validate.conformance.cases.StringNotAddress':
      message = StringNotAddress();
      break;
    case 'buf.validate.conformance.cases.StringHostname':
      message = StringHostname();
      break;
    case 'buf.validate.conformance.cases.StringNotHostname':
      message = StringNotHostname();
      break;
    case 'buf.validate.conformance.cases.StringIP':
      message = StringIP();
      break;
    case 'buf.validate.conformance.cases.StringNotIP':
      message = StringNotIP();
      break;
    case 'buf.validate.conformance.cases.StringIPv4':
      message = StringIPv4();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv4':
      message = StringNotIPv4();
      break;
    case 'buf.validate.conformance.cases.StringIPv6':
      message = StringIPv6();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv6':
      message = StringNotIPv6();
      break;
    case 'buf.validate.conformance.cases.StringIPWithPrefixLen':
      message = StringIPWithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringNotIPWithPrefixLen':
      message = StringNotIPWithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringIPv4WithPrefixLen':
      message = StringIPv4WithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv4WithPrefixLen':
      message = StringNotIPv4WithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringIPv6WithPrefixLen':
      message = StringIPv6WithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv6WithPrefixLen':
      message = StringNotIPv6WithPrefixLen();
      break;
    case 'buf.validate.conformance.cases.StringIPPrefix':
      message = StringIPPrefix();
      break;
    case 'buf.validate.conformance.cases.StringNotIPPrefix':
      message = StringNotIPPrefix();
      break;
    case 'buf.validate.conformance.cases.StringIPv4Prefix':
      message = StringIPv4Prefix();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv4Prefix':
      message = StringNotIPv4Prefix();
      break;
    case 'buf.validate.conformance.cases.StringIPv6Prefix':
      message = StringIPv6Prefix();
      break;
    case 'buf.validate.conformance.cases.StringNotIPv6Prefix':
      message = StringNotIPv6Prefix();
      break;
    case 'buf.validate.conformance.cases.StringURI':
      message = StringURI();
      break;
    case 'buf.validate.conformance.cases.StringNotURI':
      message = StringNotURI();
      break;
    case 'buf.validate.conformance.cases.StringURIRef':
      message = StringURIRef();
      break;
    case 'buf.validate.conformance.cases.StringNotURIRef':
      message = StringNotURIRef();
      break;
    case 'buf.validate.conformance.cases.StringUUID':
      message = StringUUID();
      break;
    case 'buf.validate.conformance.cases.StringNotUUID':
      message = StringNotUUID();
      break;
    case 'buf.validate.conformance.cases.StringTUUID':
      message = StringTUUID();
      break;
    case 'buf.validate.conformance.cases.StringNotTUUID':
      message = StringNotTUUID();
      break;
    case 'buf.validate.conformance.cases.StringHttpHeaderName':
      message = StringHttpHeaderName();
      break;
    case 'buf.validate.conformance.cases.StringHttpHeaderValue':
      message = StringHttpHeaderValue();
      break;
    case 'buf.validate.conformance.cases.StringHttpHeaderNameLoose':
      message = StringHttpHeaderNameLoose();
      break;
    case 'buf.validate.conformance.cases.StringHttpHeaderValueLoose':
      message = StringHttpHeaderValueLoose();
      break;
    case 'buf.validate.conformance.cases.StringUUIDIgnore':
      message = StringUUIDIgnore();
      break;
    case 'buf.validate.conformance.cases.StringInOneof':
      message = StringInOneof();
      break;
    case 'buf.validate.conformance.cases.StringHostAndPort':
      message = StringHostAndPort();
      break;
    case 'buf.validate.conformance.cases.StringHostAndOptionalPort':
      message = StringHostAndOptionalPort();
      break;
    case 'buf.validate.conformance.cases.StringExample':
      message = StringExample();
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