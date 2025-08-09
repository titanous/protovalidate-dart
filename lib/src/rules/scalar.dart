import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import '../cursor.dart';
import '../evaluator.dart';

/// Evaluator for boolean field rules.
class BoolEvaluator implements Evaluator {
  final bool? constValue;
  
  BoolEvaluator({this.constValue});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! bool) {
      cursor.violate(
        message: 'Expected bool, got ${value.runtimeType}',
        constraintId: 'bool.type',
      );
      return;
    }
    
    if (constValue != null && value != constValue) {
      cursor.violate(
        message: 'Value must be $constValue',
        constraintId: 'bool.const',
      );
    }
  }
}

/// Base evaluator for numeric field rules.
abstract class NumericEvaluator<T extends Comparable> implements Evaluator {
  final T? constValue;
  final T? lt;
  final T? lte;
  final T? gt;
  final T? gte;
  final List<T>? inValues;
  final List<T>? notInValues;
  
  NumericEvaluator({
    this.constValue,
    this.lt,
    this.lte,
    this.gt,
    this.gte,
    this.inValues,
    this.notInValues,
  });
  
  String get typeName;
  String get constraintPrefix;
  
  bool isValidType(dynamic value);
  T toTypedValue(dynamic value);
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (!isValidType(value)) {
      cursor.violate(
        message: 'Expected $typeName, got ${value.runtimeType}',
        constraintId: '$constraintPrefix.type',
      );
      return;
    }
    
    final typedValue = toTypedValue(value);
    
    // Check const
    if (constValue != null && typedValue != constValue) {
      cursor.violate(
        message: 'Value must be $constValue',
        constraintId: '$constraintPrefix.const',
      );
    }
    
    // Check lt
    if (lt != null && typedValue.compareTo(lt!) >= 0) {
      cursor.violate(
        message: 'Value must be less than $lt',
        constraintId: '$constraintPrefix.lt',
      );
    }
    
    // Check lte
    if (lte != null && typedValue.compareTo(lte!) > 0) {
      cursor.violate(
        message: 'Value must be less than or equal to $lte',
        constraintId: '$constraintPrefix.lte',
      );
    }
    
    // Check gt
    if (gt != null && typedValue.compareTo(gt!) <= 0) {
      cursor.violate(
        message: 'Value must be greater than $gt',
        constraintId: '$constraintPrefix.gt',
      );
    }
    
    // Check gte
    if (gte != null && typedValue.compareTo(gte!) < 0) {
      cursor.violate(
        message: 'Value must be greater than or equal to $gte',
        constraintId: '$constraintPrefix.gte',
      );
    }
    
    // Check in
    if (inValues != null && !inValues!.contains(typedValue)) {
      cursor.violate(
        message: 'Value must be one of $inValues',
        constraintId: '$constraintPrefix.in',
      );
    }
    
    // Check not_in
    if (notInValues != null && notInValues!.contains(typedValue)) {
      cursor.violate(
        message: 'Value must not be one of $notInValues',
        constraintId: '$constraintPrefix.not_in',
      );
    }
  }
}

/// Evaluator for int32 field rules.
class Int32Evaluator extends NumericEvaluator<int> {
  Int32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'int32';
  
  @override
  String get constraintPrefix => 'int32';
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for int64 field rules.
class Int64Evaluator extends NumericEvaluator<Int64> {
  Int64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'int64';
  
  @override
  String get constraintPrefix => 'int64';
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for uint32 field rules.
class UInt32Evaluator extends NumericEvaluator<int> {
  UInt32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'uint32';
  
  @override
  String get constraintPrefix => 'uint32';
  
  @override
  bool isValidType(dynamic value) => value is int && value >= 0;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for uint64 field rules.
class UInt64Evaluator extends NumericEvaluator<Int64> {
  UInt64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'uint64';
  
  @override
  String get constraintPrefix => 'uint64';
  
  @override
  bool isValidType(dynamic value) => value is Int64 && !value.isNegative;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for float field rules.
class FloatEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  FloatEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'float';
  
  @override
  String get constraintPrefix => 'float';
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    super.evaluate(value, cursor);
    
    if (!isValidType(value)) return;
    
    final floatValue = value as double;
    
    // Check finite
    if (finite == true && !floatValue.isFinite) {
      cursor.violate(
        message: 'Value must be finite',
        constraintId: 'float.finite',
      );
    }
  }
}

/// Evaluator for double field rules.
class DoubleEvaluator extends NumericEvaluator<double> {
  final bool? finite;
  
  DoubleEvaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
    this.finite,
  });
  
  @override
  String get typeName => 'double';
  
  @override
  String get constraintPrefix => 'double';
  
  @override
  bool isValidType(dynamic value) => value is double;
  
  @override
  double toTypedValue(dynamic value) => value as double;
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    super.evaluate(value, cursor);
    
    if (!isValidType(value)) return;
    
    final doubleValue = value as double;
    
    // Check finite
    if (finite == true && !doubleValue.isFinite) {
      cursor.violate(
        message: 'Value must be finite',
        constraintId: 'double.finite',
      );
    }
  }
}

/// Evaluator for string field rules.
class StringRulesEvaluator implements Evaluator {
  final String? constValue;
  final int? len;
  final int? minLen;
  final int? maxLen;
  final int? minBytes;
  final int? maxBytes;
  final String? pattern;
  final String? prefix;
  final String? suffix;
  final String? contains;
  final String? notContains;
  final List<String>? inValues;
  final List<String>? notInValues;
  
  // Format validators
  final bool? email;
  final bool? hostname;
  final bool? ip;
  final bool? ipv4;
  final bool? ipv6;
  final bool? uri;
  final bool? uriRef;
  final bool? address;
  final bool? uuid;
  final bool? wellKnownRegex;
  
  // Cached compiled pattern
  RegExp? _compiledPattern;
  
  StringRulesEvaluator({
    this.constValue,
    this.len,
    this.minLen,
    this.maxLen,
    this.minBytes,
    this.maxBytes,
    this.pattern,
    this.prefix,
    this.suffix,
    this.contains,
    this.notContains,
    this.inValues,
    this.notInValues,
    this.email,
    this.hostname,
    this.ip,
    this.ipv4,
    this.ipv6,
    this.uri,
    this.uriRef,
    this.address,
    this.uuid,
    this.wellKnownRegex,
  }) {
    // Compile pattern once during construction
    if (pattern != null) {
      try {
        _compiledPattern = RegExp(pattern!);
      } catch (e) {
        // Pattern compilation error will be caught during validation
      }
    }
  }
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! String) {
      cursor.violate(
        message: 'Expected string, got ${value.runtimeType}',
        constraintId: 'string.type',
      );
      return;
    }
    
    final stringValue = value;
    
    // Check const
    if (constValue != null && stringValue != constValue) {
      cursor.violate(
        message: 'Value must be "$constValue"',
        constraintId: 'string.const',
      );
    }
    
    // Check exact length
    if (len != null && stringValue.length != len) {
      cursor.violate(
        message: 'String length must be exactly $len characters',
        constraintId: 'string.len',
      );
    }
    
    // Check min length
    if (minLen != null && stringValue.length < minLen!) {
      cursor.violate(
        message: 'String must be at least $minLen characters',
        constraintId: 'string.min_len',
      );
    }
    
    // Check max length
    if (maxLen != null && stringValue.length > maxLen!) {
      cursor.violate(
        message: 'String must be at most $maxLen characters',
        constraintId: 'string.max_len',
      );
    }
    
    // Check min bytes
    if (minBytes != null) {
      final byteLen = stringValue.codeUnits.length;
      if (byteLen < minBytes!) {
        cursor.violate(
          message: 'String must be at least $minBytes bytes',
          constraintId: 'string.min_bytes',
        );
      }
    }
    
    // Check max bytes
    if (maxBytes != null) {
      final byteLen = stringValue.codeUnits.length;
      if (byteLen > maxBytes!) {
        cursor.violate(
          message: 'String must be at most $maxBytes bytes',
          constraintId: 'string.max_bytes',
        );
      }
    }
    
    // Check pattern
    if (pattern != null) {
      if (_compiledPattern == null) {
        cursor.violate(
          message: 'Invalid regex pattern: $pattern',
          constraintId: 'string.pattern.compile_error',
        );
      } else if (!_compiledPattern!.hasMatch(stringValue)) {
        cursor.violate(
          message: 'String must match pattern: $pattern',
          constraintId: 'string.pattern',
        );
      }
    }
    
    // Check prefix
    if (prefix != null && !stringValue.startsWith(prefix!)) {
      cursor.violate(
        message: 'String must start with "$prefix"',
        constraintId: 'string.prefix',
      );
    }
    
    // Check suffix
    if (suffix != null && !stringValue.endsWith(suffix!)) {
      cursor.violate(
        message: 'String must end with "$suffix"',
        constraintId: 'string.suffix',
      );
    }
    
    // Check contains
    if (contains != null && !stringValue.contains(contains!)) {
      cursor.violate(
        message: 'String must contain "$contains"',
        constraintId: 'string.contains',
      );
    }
    
    // Check not_contains
    if (notContains != null && stringValue.contains(notContains!)) {
      cursor.violate(
        message: 'String must not contain "$notContains"',
        constraintId: 'string.not_contains',
      );
    }
    
    // Check in
    if (inValues != null && !inValues!.contains(stringValue)) {
      cursor.violate(
        message: 'Value must be one of: ${inValues!.join(", ")}',
        constraintId: 'string.in',
      );
    }
    
    // Check not_in
    if (notInValues != null && notInValues!.contains(stringValue)) {
      cursor.violate(
        message: 'Value must not be one of: ${notInValues!.join(", ")}',
        constraintId: 'string.not_in',
      );
    }
    
    // Format validators
    _validateFormats(stringValue, cursor);
  }
  
  void _validateFormats(String value, Cursor cursor) {
    // Email validation
    if (email == true && !_isValidEmail(value)) {
      cursor.violate(
        message: 'String must be a valid email address',
        constraintId: 'string.email',
      );
    }
    
    // Hostname validation
    if (hostname == true && !_isValidHostname(value)) {
      cursor.violate(
        message: 'String must be a valid hostname',
        constraintId: 'string.hostname',
      );
    }
    
    // IP validation (v4 or v6)
    if (ip == true && !_isValidIP(value)) {
      cursor.violate(
        message: 'String must be a valid IP address',
        constraintId: 'string.ip',
      );
    }
    
    // IPv4 validation
    if (ipv4 == true && !_isValidIPv4(value)) {
      cursor.violate(
        message: 'String must be a valid IPv4 address',
        constraintId: 'string.ipv4',
      );
    }
    
    // IPv6 validation
    if (ipv6 == true && !_isValidIPv6(value)) {
      cursor.violate(
        message: 'String must be a valid IPv6 address',
        constraintId: 'string.ipv6',
      );
    }
    
    // URI validation
    if (uri == true && !_isValidURI(value)) {
      cursor.violate(
        message: 'String must be a valid URI',
        constraintId: 'string.uri',
      );
    }
    
    // URI reference validation
    if (uriRef == true && !_isValidURIRef(value)) {
      cursor.violate(
        message: 'String must be a valid URI reference',
        constraintId: 'string.uri_ref',
      );
    }
    
    // UUID validation
    if (uuid == true && !_isValidUUID(value)) {
      cursor.violate(
        message: 'String must be a valid UUID',
        constraintId: 'string.uuid',
      );
    }
  }
  
  // Email validation - simplified version
  bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }
  
  // Hostname validation
  bool _isValidHostname(String value) {
    if (value.isEmpty || value.length > 253) return false;
    
    final labels = value.split('.');
    for (final label in labels) {
      if (label.isEmpty || label.length > 63) return false;
      if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$').hasMatch(label)) {
        return false;
      }
    }
    return true;
  }
  
  // IP validation (v4 or v6)
  bool _isValidIP(String value) {
    return _isValidIPv4(value) || _isValidIPv6(value);
  }
  
  // IPv4 validation
  bool _isValidIPv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }
  
  // IPv6 validation - simplified
  bool _isValidIPv6(String value) {
    // Basic IPv6 pattern - this is a simplified check
    final ipv6Regex = RegExp(
      r'^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,7}:|'
      r'([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|'
      r'([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|'
      r'([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|'
      r'[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|'
      r':((:[0-9a-fA-F]{1,4}){1,7}|:)|'
      r'fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|'
      r'::(ffff(:0{1,4}){0,1}:){0,1}'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|'
      r'([0-9a-fA-F]{1,4}:){1,4}:'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
    );
    return ipv6Regex.hasMatch(value);
  }
  
  // URI validation
  bool _isValidURI(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && (uri.hasAuthority || uri.hasAbsolutePath);
    } catch (_) {
      return false;
    }
  }
  
  // URI reference validation (can be relative)
  bool _isValidURIRef(String value) {
    try {
      Uri.parse(value);
      return true;
    } catch (_) {
      return false;
    }
  }
  
  // UUID validation
  bool _isValidUUID(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }
}

/// Evaluator for bytes field rules.
class BytesEvaluator implements Evaluator {
  final List<int>? constValue;
  final int? len;
  final int? minLen;
  final int? maxLen;
  final String? pattern;
  final List<int>? prefix;
  final List<int>? suffix;
  final List<int>? contains;
  final List<List<int>>? inValues;
  final List<List<int>>? notInValues;
  
  // Special format validators
  final bool? ip;
  final bool? ipv4;
  final bool? ipv6;
  
  // Cached compiled pattern for hex representation
  RegExp? _compiledPattern;
  
  BytesEvaluator({
    this.constValue,
    this.len,
    this.minLen,
    this.maxLen,
    this.pattern,
    this.prefix,
    this.suffix,
    this.contains,
    this.inValues,
    this.notInValues,
    this.ip,
    this.ipv4,
    this.ipv6,
  }) {
    // Compile pattern once during construction
    if (pattern != null) {
      try {
        _compiledPattern = RegExp(pattern!);
      } catch (e) {
        // Pattern compilation error will be caught during validation
      }
    }
  }
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Accept both List<int> and Uint8List
    if (value is! List<int>) {
      cursor.violate(
        message: 'Expected bytes, got ${value.runtimeType}',
        constraintId: 'bytes.type',
      );
      return;
    }
    
    final bytesValue = value;
    
    // Check const
    if (constValue != null && !_bytesEqual(bytesValue, constValue!)) {
      cursor.violate(
        message: 'Value must be exactly the specified bytes',
        constraintId: 'bytes.const',
      );
    }
    
    // Check exact length
    if (len != null && bytesValue.length != len) {
      cursor.violate(
        message: 'Bytes must be exactly $len bytes',
        constraintId: 'bytes.len',
      );
    }
    
    // Check min length
    if (minLen != null && bytesValue.length < minLen!) {
      cursor.violate(
        message: 'Bytes must be at least $minLen bytes',
        constraintId: 'bytes.min_len',
      );
    }
    
    // Check max length
    if (maxLen != null && bytesValue.length > maxLen!) {
      cursor.violate(
        message: 'Bytes must be at most $maxLen bytes',
        constraintId: 'bytes.max_len',
      );
    }
    
    // Check pattern (on hex representation)
    if (pattern != null) {
      if (_compiledPattern == null) {
        cursor.violate(
          message: 'Invalid regex pattern: $pattern',
          constraintId: 'bytes.pattern.compile_error',
        );
      } else {
        final hexString = _toHexString(bytesValue);
        if (!_compiledPattern!.hasMatch(hexString)) {
          cursor.violate(
            message: 'Bytes must match pattern: $pattern',
            constraintId: 'bytes.pattern',
          );
        }
      }
    }
    
    // Check prefix
    if (prefix != null && !_hasPrefix(bytesValue, prefix!)) {
      cursor.violate(
        message: 'Bytes must start with the specified prefix',
        constraintId: 'bytes.prefix',
      );
    }
    
    // Check suffix
    if (suffix != null && !_hasSuffix(bytesValue, suffix!)) {
      cursor.violate(
        message: 'Bytes must end with the specified suffix',
        constraintId: 'bytes.suffix',
      );
    }
    
    // Check contains
    if (contains != null && !_containsBytes(bytesValue, contains!)) {
      cursor.violate(
        message: 'Bytes must contain the specified sequence',
        constraintId: 'bytes.contains',
      );
    }
    
    // Check in
    if (inValues != null) {
      bool found = false;
      for (final allowedValue in inValues!) {
        if (_bytesEqual(bytesValue, allowedValue)) {
          found = true;
          break;
        }
      }
      if (!found) {
        cursor.violate(
          message: 'Bytes must be one of the allowed values',
          constraintId: 'bytes.in',
        );
      }
    }
    
    // Check not_in
    if (notInValues != null) {
      for (final disallowedValue in notInValues!) {
        if (_bytesEqual(bytesValue, disallowedValue)) {
          cursor.violate(
            message: 'Bytes must not be one of the disallowed values',
            constraintId: 'bytes.not_in',
          );
          break;
        }
      }
    }
    
    // Check IP formats
    _validateIPFormats(bytesValue, cursor);
  }
  
  void _validateIPFormats(List<int> value, Cursor cursor) {
    // IP validation (v4 or v6)
    if (ip == true) {
      if (!_isValidIPBytes(value)) {
        cursor.violate(
          message: 'Bytes must be a valid IP address (4 or 16 bytes)',
          constraintId: 'bytes.ip',
        );
      }
    }
    
    // IPv4 validation
    if (ipv4 == true) {
      if (value.length != 4) {
        cursor.violate(
          message: 'Bytes must be a valid IPv4 address (4 bytes)',
          constraintId: 'bytes.ipv4',
        );
      }
    }
    
    // IPv6 validation
    if (ipv6 == true) {
      if (value.length != 16) {
        cursor.violate(
          message: 'Bytes must be a valid IPv6 address (16 bytes)',
          constraintId: 'bytes.ipv6',
        );
      }
    }
  }
  
  bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  bool _hasPrefix(List<int> bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
  
  bool _hasSuffix(List<int> bytes, List<int> suffix) {
    if (bytes.length < suffix.length) return false;
    final offset = bytes.length - suffix.length;
    for (int i = 0; i < suffix.length; i++) {
      if (bytes[offset + i] != suffix[i]) return false;
    }
    return true;
  }
  
  bool _containsBytes(List<int> bytes, List<int> sequence) {
    if (bytes.length < sequence.length) return false;
    
    for (int i = 0; i <= bytes.length - sequence.length; i++) {
      bool found = true;
      for (int j = 0; j < sequence.length; j++) {
        if (bytes[i + j] != sequence[j]) {
          found = false;
          break;
        }
      }
      if (found) return true;
    }
    return false;
  }
  
  String _toHexString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  bool _isValidIPBytes(List<int> bytes) {
    return bytes.length == 4 || bytes.length == 16;
  }
}

/// Evaluator for fixed32 field rules (unsigned).
class Fixed32Evaluator extends NumericEvaluator<int> {
  Fixed32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'fixed32';
  
  @override
  String get constraintPrefix => 'fixed32';
  
  @override
  bool isValidType(dynamic value) => value is int && value >= 0;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for fixed64 field rules (unsigned).
class Fixed64Evaluator extends NumericEvaluator<Int64> {
  Fixed64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'fixed64';
  
  @override
  String get constraintPrefix => 'fixed64';
  
  @override
  bool isValidType(dynamic value) => value is Int64 && !value.isNegative;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for sfixed32 field rules (signed).
class SFixed32Evaluator extends NumericEvaluator<int> {
  SFixed32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'sfixed32';
  
  @override
  String get constraintPrefix => 'sfixed32';
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for sfixed64 field rules (signed).
class SFixed64Evaluator extends NumericEvaluator<Int64> {
  SFixed64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'sfixed64';
  
  @override
  String get constraintPrefix => 'sfixed64';
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}

/// Evaluator for sint32 field rules (zigzag encoded signed).
class SInt32Evaluator extends NumericEvaluator<int> {
  SInt32Evaluator({
    super.constValue,
    super.lt,
    super.lte,
    super.gt,
    super.gte,
    super.inValues,
    super.notInValues,
  });
  
  @override
  String get typeName => 'sint32';
  
  @override
  String get constraintPrefix => 'sint32';
  
  @override
  bool isValidType(dynamic value) => value is int;
  
  @override
  int toTypedValue(dynamic value) => value as int;
}

/// Evaluator for sint64 field rules (zigzag encoded signed).
class SInt64Evaluator extends NumericEvaluator<Int64> {
  SInt64Evaluator({
    Int64? constValue,
    Int64? lt,
    Int64? lte,
    Int64? gt,
    Int64? gte,
    List<Int64>? inValues,
    List<Int64>? notInValues,
  }) : super(
    constValue: constValue,
    lt: lt,
    lte: lte,
    gt: gt,
    gte: gte,
    inValues: inValues,
    notInValues: notInValues,
  );
  
  @override
  String get typeName => 'sint64';
  
  @override
  String get constraintPrefix => 'sint64';
  
  @override
  bool isValidType(dynamic value) => value is Int64;
  
  @override
  Int64 toTypedValue(dynamic value) => value as Int64;
}