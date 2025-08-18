import '../rule_paths.dart';

/// Utility class for mapping constraint names to their corresponding numbers and types.
/// Replaces large switch statements with efficient lookup tables.
class ConstraintMappings {
  /// Lookup table for string constraint name to number mapping
  static const Map<String, int> _stringConstraintNumbers = {
    'const': ConstraintNumbers.const_,
    'len': ConstraintNumbers.len,
    'min_len': ConstraintNumbers.minLen,
    'max_len': ConstraintNumbers.maxLen,
    'len_bytes': ConstraintNumbers.lenBytes,
    'min_bytes': ConstraintNumbers.minBytes,
    'max_bytes': ConstraintNumbers.maxBytes,
    'pattern': ConstraintNumbers.pattern,
    'prefix': ConstraintNumbers.prefix,
    'suffix': ConstraintNumbers.suffix,
    'contains': ConstraintNumbers.contains,
    'not_contains': ConstraintNumbers.notContains,
    'in': ConstraintNumbers.stringIn,
    'not_in': ConstraintNumbers.stringNotIn,
    'email': ConstraintNumbers.email,
    'hostname': ConstraintNumbers.hostname,
    'ip': ConstraintNumbers.ip,
    'ipv4': ConstraintNumbers.ipv4,
    'ipv6': ConstraintNumbers.ipv6,
    'uri': ConstraintNumbers.uri,
    'uri_ref': ConstraintNumbers.uriRef,
    'address': ConstraintNumbers.address,
    'uuid': ConstraintNumbers.uuid,
    'ipv4_prefix': ConstraintNumbers.ipv4Prefix,
    'ipv6_prefix': ConstraintNumbers.ipv6Prefix,
    'well_known_regex': ConstraintNumbers.wellKnownRegex,
    'strict': ConstraintNumbers.strict,
    'ip_with_prefixlen': ConstraintNumbers.ipWithPrefixlen,
    'ipv4_with_prefixlen': ConstraintNumbers.ipv4WithPrefixlen,
    'ipv6_with_prefixlen': ConstraintNumbers.ipv6WithPrefixlen,
    'ip_prefix': ConstraintNumbers.ipPrefix,
    'host_and_port': ConstraintNumbers.hostAndPort,
    'tuuid': ConstraintNumbers.tuuid,
  };

  /// Lookup table for numeric constraint name to number mapping
  static const Map<String, int> _numericConstraintNumbers = {
    'const': ConstraintNumbers.const_,
    'lt': ConstraintNumbers.lt,
    'lte': ConstraintNumbers.lte,
    'gt': ConstraintNumbers.gt,
    'gte': ConstraintNumbers.gte,
    'in': ConstraintNumbers.in_,
    'not_in': ConstraintNumbers.notIn,
    'finite': ConstraintNumbers.finite,
  };

  /// Gets the constraint number for a string constraint name.
  /// Throws ArgumentError if constraint name is unknown.
  static int getStringConstraintNumber(String constraintName) {
    final number = _stringConstraintNumbers[constraintName];
    if (number == null) {
      throw ArgumentError('Unknown string constraint: $constraintName');
    }
    return number;
  }

  /// Gets the constraint number for a numeric constraint name.
  /// Throws ArgumentError if constraint name is unknown.
  static int getNumericConstraintNumber(String constraintName) {
    final number = _numericConstraintNumbers[constraintName];
    if (number == null) {
      throw ArgumentError('Unknown numeric constraint: $constraintName');
    }
    return number;
  }
}
