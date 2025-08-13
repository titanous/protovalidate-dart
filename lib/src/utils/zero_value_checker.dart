import 'package:fixnum/fixnum.dart';

/// Utility class for checking if values are considered "zero values" 
/// according to protobuf semantics for ignore conditions.
class ZeroValueChecker {
  /// Determines if a value is considered a "zero value" for validation purposes.
  /// 
  /// Zero values are:
  /// - null
  /// - false for booleans
  /// - 0 for integers (including Int64.ZERO)
  /// - 0.0 for doubles
  /// - empty string
  /// - empty List
  /// - empty Map
  /// 
  /// Note: For messages, only null/unset is considered a zero value.
  /// An explicitly created empty message {} is NOT a zero value.
  static bool isZeroValue(dynamic value) {
    if (value == null) return true;
    
    // Check for zero values based on type
    if (value is bool && !value) return true;
    if (value is int && value == 0) return true;
    if (value is Int64 && value == Int64.ZERO) return true;
    if (value is double && value == 0.0) return true;
    if (value is String && value.isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    
    return false;
  }
}