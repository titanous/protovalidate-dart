import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';
import 'field_path.dart';

/// Constants for field numbers in the validate.proto schema.
/// These correspond to the field numbers in buf.validate.FieldRules.
class FieldRuleNumbers {
  // Standard scalar types
  static const int float = 1;
  static const int double = 2;
  static const int int32 = 3;
  static const int int64 = 4;
  static const int uint32 = 5;
  static const int uint64 = 6;
  static const int sint32 = 7;
  static const int sint64 = 8;
  static const int fixed32 = 9;
  static const int fixed64 = 10;
  static const int sfixed32 = 11;
  static const int sfixed64 = 12;
  static const int bool = 13;
  static const int string = 14;
  static const int bytes = 15;
  static const int enum_ = 16;
  static const int message = 17;
  static const int repeated = 18;
  static const int map = 19;
  
  // Well-known types
  static const int any = 20;
  static const int duration = 21;
  static const int timestamp = 22;
}

/// Constants for constraint field numbers within each rule type.
class ConstraintNumbers {
  // Common constraints (used by multiple types)
  static const int const_ = 1;
  static const int in_ = 6;
  static const int notIn = 7;
  
  // String constraints
  static const int len = 19;
  static const int minLen = 2;
  static const int maxLen = 3;
  static const int lenBytes = 20;
  static const int minBytes = 4;
  static const int maxBytes = 5;
  static const int pattern = 6;
  static const int prefix = 7;
  static const int suffix = 8;
  static const int contains = 9;
  static const int notContains = 23;
  static const int email = 12;
  static const int hostname = 13;
  static const int ip = 14;
  static const int ipv4 = 15;
  static const int ipv6 = 16;
  static const int uri = 17;
  static const int uriRef = 18;
  static const int address = 21;
  static const int uuid = 22;
  static const int ipv4Prefix = 30;
  static const int ipv6Prefix = 31;
  static const int wellKnownRegex = 24;
  static const int strict = 25;
  static const int ipWithPrefixlen = 26;
  static const int ipv4WithPrefixlen = 27;
  static const int ipv6WithPrefixlen = 28;
  static const int ipPrefix = 29;
  static const int hostAndPort = 32;
  static const int tuuid = 33;
  
  // Numeric constraints (lt, lte, gt, gte)
  static const int lt = 2;
  static const int lte = 3;
  static const int gt = 4;
  static const int gte = 5;
  static const int finite = 8;
  
  // Repeated constraints
  static const int minItems = 1;
  static const int maxItems = 2;
  static const int unique = 3;
  static const int items = 4;
  
  // Map constraints  
  static const int minPairs = 1;
  static const int maxPairs = 2;
  static const int keys = 3;
  static const int values = 4;
  
  // Enum constraints
  static const int definedOnly = 2;
}

/// Helper class for constructing rule paths for different validation scenarios.
class RulePathBuilder {
  /// Creates a rule path for string constraints.
  static RulePath stringConstraint(String constraintName) {
    final fieldNumber = _getStringConstraintNumber(constraintName);
    final fieldType = _getStringConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('string', FieldRuleNumbers.string)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a rule path for numeric constraints.
  static RulePath numericConstraint(String ruleTypeName, int ruleTypeNumber, String constraintName) {
    final fieldNumber = _getNumericConstraintNumber(constraintName);
    final fieldType = _getNumericConstraintType(constraintName, ruleTypeName);
    
    return RulePath.fromFieldRules()
        .ruleType(ruleTypeName, ruleTypeNumber)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a rule path for repeated constraints.
  static RulePath repeatedConstraint(String constraintName) {
    final fieldNumber = _getRepeatedConstraintNumber(constraintName);
    final fieldType = _getRepeatedConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('repeated', FieldRuleNumbers.repeated)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a base rule path for repeated items (repeated.items)
  static RulePath repeatedItemsBase() {
    return RulePath.fromFieldRules()
        .ruleType('repeated', FieldRuleNumbers.repeated)
        .ruleType('items', ConstraintNumbers.items);
  }
  
  /// Creates a rule path for repeated items with a specific item constraint
  static RulePath repeatedItemsConstraint(RulePath itemRulePath) {
    return repeatedItemsBase().appendPath(itemRulePath);
  }
  
  /// Creates a rule path for bool constraints.
  static RulePath boolConstraint(String constraintName) {
    return RulePath.fromFieldRules()
        .ruleType('bool', FieldRuleNumbers.bool)
        .constraint(constraintName, ConstraintNumbers.const_, FieldDescriptorProto_Type.TYPE_BOOL);
  }
  
  /// Creates a rule path for enum constraints.
  static RulePath enumConstraint(String constraintName) {
    final fieldNumber = _getEnumConstraintNumber(constraintName);
    final fieldType = _getEnumConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('enum', FieldRuleNumbers.enum_)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a rule path for bytes constraints.
  static RulePath bytesConstraint(String constraintName) {
    final fieldNumber = _getBytesConstraintNumber(constraintName);
    final fieldType = _getBytesConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('bytes', FieldRuleNumbers.bytes)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a rule path for map constraints.
  static RulePath mapConstraint(String constraintName) {
    final fieldNumber = _getMapConstraintNumber(constraintName);
    final fieldType = _getMapConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('map', FieldRuleNumbers.map)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  /// Creates a rule path for duration constraints.
  static RulePath durationConstraint(String constraintName) {
    final fieldNumber = _getDurationConstraintNumber(constraintName);
    final fieldType = _getDurationConstraintType(constraintName);
    
    return RulePath.fromFieldRules()
        .ruleType('duration', FieldRuleNumbers.duration)
        .constraint(constraintName, fieldNumber, fieldType);
  }
  
  static int _getStringConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'const': return ConstraintNumbers.const_;
      case 'len': return ConstraintNumbers.len;
      case 'min_len': return ConstraintNumbers.minLen;
      case 'max_len': return ConstraintNumbers.maxLen;
      case 'len_bytes': return ConstraintNumbers.lenBytes;
      case 'min_bytes': return ConstraintNumbers.minBytes;
      case 'max_bytes': return ConstraintNumbers.maxBytes;
      case 'pattern': return ConstraintNumbers.pattern;
      case 'prefix': return ConstraintNumbers.prefix;
      case 'suffix': return ConstraintNumbers.suffix;
      case 'contains': return ConstraintNumbers.contains;
      case 'not_contains': return ConstraintNumbers.notContains;
      case 'in': return ConstraintNumbers.in_;
      case 'not_in': return ConstraintNumbers.notIn;
      case 'email': return ConstraintNumbers.email;
      case 'hostname': return ConstraintNumbers.hostname;
      case 'ip': return ConstraintNumbers.ip;
      case 'ipv4': return ConstraintNumbers.ipv4;
      case 'ipv6': return ConstraintNumbers.ipv6;
      case 'uri': return ConstraintNumbers.uri;
      case 'uri_ref': return ConstraintNumbers.uriRef;
      case 'address': return ConstraintNumbers.address;
      case 'uuid': return ConstraintNumbers.uuid;
      case 'ipv4_prefix': return ConstraintNumbers.ipv4Prefix;
      case 'ipv6_prefix': return ConstraintNumbers.ipv6Prefix;
      case 'well_known_regex': return ConstraintNumbers.wellKnownRegex;
      case 'strict': return ConstraintNumbers.strict;
      case 'ip_with_prefixlen': return ConstraintNumbers.ipWithPrefixlen;
      case 'ipv4_with_prefixlen': return ConstraintNumbers.ipv4WithPrefixlen;
      case 'ipv6_with_prefixlen': return ConstraintNumbers.ipv6WithPrefixlen;
      case 'ip_prefix': return ConstraintNumbers.ipPrefix;
      case 'host_and_port': return ConstraintNumbers.hostAndPort;
      case 'tuuid': return ConstraintNumbers.tuuid;
      default: throw ArgumentError('Unknown string constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getStringConstraintType(String constraintName) {
    switch (constraintName) {
      case 'const':
      case 'pattern':
      case 'prefix':
      case 'suffix':
      case 'contains':
      case 'not_contains':
        return FieldDescriptorProto_Type.TYPE_STRING;
      case 'len':
      case 'min_len':
      case 'max_len':
      case 'len_bytes':
      case 'min_bytes':
      case 'max_bytes':
        return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'in':
      case 'not_in':
        return FieldDescriptorProto_Type.TYPE_STRING; // repeated string
      case 'email':
      case 'hostname':
      case 'ip':
      case 'ipv4':
      case 'ipv6':
      case 'uri':
      case 'uri_ref':
      case 'address':
      case 'uuid':
      case 'ipv4_prefix':
      case 'ipv6_prefix':
      case 'well_known_regex':
      case 'ip_with_prefixlen':
      case 'ipv4_with_prefixlen':
      case 'ipv6_with_prefixlen':
      case 'ip_prefix':
      case 'host_and_port':
      case 'tuuid':
      case 'strict':
        return FieldDescriptorProto_Type.TYPE_BOOL;
      default:
        return FieldDescriptorProto_Type.TYPE_STRING;
    }
  }
  
  static int _getNumericConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'const': return ConstraintNumbers.const_;
      case 'lt': return ConstraintNumbers.lt;
      case 'lte': return ConstraintNumbers.lte;
      case 'gt': return ConstraintNumbers.gt;
      case 'gte': return ConstraintNumbers.gte;
      case 'in': return ConstraintNumbers.in_;
      case 'not_in': return ConstraintNumbers.notIn;
      case 'finite': return ConstraintNumbers.finite;
      default: throw ArgumentError('Unknown numeric constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getNumericConstraintType(String constraintName, String ruleTypeName) {
    if (constraintName == 'finite') {
      return FieldDescriptorProto_Type.TYPE_BOOL;
    }
    
    // Return the same type as the rule type for value constraints
    switch (ruleTypeName) {
      case 'float': return FieldDescriptorProto_Type.TYPE_FLOAT;
      case 'double': return FieldDescriptorProto_Type.TYPE_DOUBLE;
      case 'int32': return FieldDescriptorProto_Type.TYPE_INT32;
      case 'int64': return FieldDescriptorProto_Type.TYPE_INT64;
      case 'uint32': return FieldDescriptorProto_Type.TYPE_UINT32;
      case 'uint64': return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'sint32': return FieldDescriptorProto_Type.TYPE_SINT32;
      case 'sint64': return FieldDescriptorProto_Type.TYPE_SINT64;
      case 'fixed32': return FieldDescriptorProto_Type.TYPE_FIXED32;
      case 'fixed64': return FieldDescriptorProto_Type.TYPE_FIXED64;
      case 'sfixed32': return FieldDescriptorProto_Type.TYPE_SFIXED32;
      case 'sfixed64': return FieldDescriptorProto_Type.TYPE_SFIXED64;
      default: return FieldDescriptorProto_Type.TYPE_INT32;
    }
  }
  
  static int _getRepeatedConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'min_items': return ConstraintNumbers.minItems;
      case 'max_items': return ConstraintNumbers.maxItems;
      case 'unique': return ConstraintNumbers.unique;
      case 'items': return ConstraintNumbers.items;
      default: throw ArgumentError('Unknown repeated constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getRepeatedConstraintType(String constraintName) {
    switch (constraintName) {
      case 'min_items':
      case 'max_items':
        return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'unique':
        return FieldDescriptorProto_Type.TYPE_BOOL;
      case 'items':
        return FieldDescriptorProto_Type.TYPE_MESSAGE;
      default:
        return FieldDescriptorProto_Type.TYPE_UINT64;
    }
  }
  
  static int _getEnumConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'const': return ConstraintNumbers.const_;
      case 'defined_only': return ConstraintNumbers.definedOnly;
      case 'in': return ConstraintNumbers.in_;
      case 'not_in': return ConstraintNumbers.notIn;
      default: throw ArgumentError('Unknown enum constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getEnumConstraintType(String constraintName) {
    switch (constraintName) {
      case 'const':
      case 'in':
      case 'not_in':
        return FieldDescriptorProto_Type.TYPE_INT32;
      case 'defined_only':
        return FieldDescriptorProto_Type.TYPE_BOOL;
      default:
        return FieldDescriptorProto_Type.TYPE_INT32;
    }
  }
  
  static int _getBytesConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'const': return 1;
      case 'len': return 13;
      case 'min_len': return 2;
      case 'max_len': return 3;
      case 'pattern': return 4;
      case 'prefix': return 5;
      case 'suffix': return 6;
      case 'contains': return 7;
      case 'in': return 8;
      case 'not_in': return 9;
      case 'ip': return 10;
      case 'ipv4': return 11;
      case 'ipv6': return 12;
      default: throw ArgumentError('Unknown bytes constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getBytesConstraintType(String constraintName) {
    switch (constraintName) {
      case 'const':
      case 'prefix':
      case 'suffix':
      case 'contains':
      case 'in':
      case 'not_in':
        return FieldDescriptorProto_Type.TYPE_BYTES;
      case 'len':
      case 'min_len':
      case 'max_len':
        return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'pattern':
        return FieldDescriptorProto_Type.TYPE_STRING;
      case 'ip':
      case 'ipv4':
      case 'ipv6':
        return FieldDescriptorProto_Type.TYPE_BOOL;
      default:
        return FieldDescriptorProto_Type.TYPE_BYTES;
    }
  }
  
  static int _getMapConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'min_pairs': return ConstraintNumbers.minPairs;
      case 'max_pairs': return ConstraintNumbers.maxPairs;
      case 'keys': return ConstraintNumbers.keys;
      case 'values': return ConstraintNumbers.values;
      default: throw ArgumentError('Unknown map constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getMapConstraintType(String constraintName) {
    switch (constraintName) {
      case 'min_pairs':
      case 'max_pairs':
        return FieldDescriptorProto_Type.TYPE_UINT64;
      case 'keys':
      case 'values':
        return FieldDescriptorProto_Type.TYPE_MESSAGE;
      default:
        return FieldDescriptorProto_Type.TYPE_UINT64;
    }
  }
  
  static int _getDurationConstraintNumber(String constraintName) {
    switch (constraintName) {
      case 'const': return 2; // DurationRules.const field number
      case 'lt': return 3;    // DurationRules.lt field number
      case 'lte': return 4;   // DurationRules.lte field number
      case 'gt': return 5;    // DurationRules.gt field number
      case 'gte': return 6;   // DurationRules.gte field number
      case 'in': return 7;    // DurationRules.in field number
      case 'not_in': return 8; // DurationRules.not_in field number
      default: throw ArgumentError('Unknown duration constraint: $constraintName');
    }
  }
  
  static FieldDescriptorProto_Type _getDurationConstraintType(String constraintName) {
    switch (constraintName) {
      case 'const':
      case 'lt':
      case 'lte':
      case 'gt':
      case 'gte':
        return FieldDescriptorProto_Type.TYPE_MESSAGE;
      case 'in':
      case 'not_in':
        return FieldDescriptorProto_Type.TYPE_MESSAGE; // repeated Duration
      default:
        return FieldDescriptorProto_Type.TYPE_MESSAGE;
    }
  }
}