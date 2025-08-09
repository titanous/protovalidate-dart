import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';

/// Extracts validation rules from protobuf message descriptors.
class RuleExtractor {
  /// Extension number for field rules.
  static const int fieldExtensionNumber = 1158;
  
  /// Extension number for message rules.
  static const int messageExtensionNumber = 1159;
  
  /// Extension number for oneof rules.
  static const int oneofExtensionNumber = 1160;
  
  /// Gets field rules from a field's extensions.
  FieldRules? getFieldRules(GeneratedMessage message, FieldInfo field) {
    // Try to get field rules from the field descriptor
    // This is a simplified approach - in practice we need to access
    // the field descriptor's options/extensions
    
    // For now, return null as we need proper descriptor access
    // In a full implementation, we would:
    // 1. Get the field descriptor from the message descriptor
    // 2. Access the field options
    // 3. Extract the buf.validate.field extension
    // 4. Parse it as FieldRules
    
    return null;
  }
  
  /// Gets message rules from a message's extensions.
  MessageRules? getMessageRules(GeneratedMessage message) {
    // Try to get message rules from the message descriptor
    // This is a simplified approach - in practice we need to access
    // the message descriptor's options/extensions
    
    // For now, return null as we need proper descriptor access
    // In a full implementation, we would:
    // 1. Get the message descriptor
    // 2. Access the message options
    // 3. Extract the buf.validate.message extension
    // 4. Parse it as MessageRules
    
    return null;
  }
  
  /// Gets oneof rules from a oneof's extensions.
  OneofRules? getOneofRules(GeneratedMessage message, OneofInfo oneof) {
    // Try to get oneof rules from the oneof descriptor
    // This is a simplified approach - in practice we need to access
    // the oneof descriptor's options/extensions
    
    // For now, return null as we need proper descriptor access
    // In a full implementation, we would:
    // 1. Get the oneof descriptor from the message descriptor
    // 2. Access the oneof options
    // 3. Extract the buf.validate.oneof extension
    // 4. Parse it as OneofRules
    
    return null;
  }
  
  /// Creates field rules from a FileDescriptorSet for testing.
  /// This is a temporary method to support conformance testing.
  FieldRules? createFieldRulesForTesting(
    String messageName,
    String fieldName,
    Map<String, dynamic>? rulesData,
  ) {
    if (rulesData == null) {
      return null;
    }
    
    // Create FieldRules based on the provided data
    final rules = FieldRules();
    
    // Parse different rule types
    if (rulesData.containsKey('bool')) {
      final boolRules = BoolRules();
      final boolData = rulesData['bool'] as Map<String, dynamic>;
      if (boolData.containsKey('const')) {
        boolRules.const_1 = boolData['const'] as bool;
      }
      rules.bool_13 = boolRules;
    }
    
    if (rulesData.containsKey('int32')) {
      final int32Rules = Int32Rules();
      final int32Data = rulesData['int32'] as Map<String, dynamic>;
      _populateNumericRules(int32Rules, int32Data);
      rules.int32 = int32Rules;
    }
    
    if (rulesData.containsKey('int64')) {
      final int64Rules = Int64Rules();
      final int64Data = rulesData['int64'] as Map<String, dynamic>;
      _populateNumericRules(int64Rules, int64Data);
      rules.int64 = int64Rules;
    }
    
    if (rulesData.containsKey('uint32')) {
      final uint32Rules = UInt32Rules();
      final uint32Data = rulesData['uint32'] as Map<String, dynamic>;
      _populateNumericRules(uint32Rules, uint32Data);
      rules.uint32 = uint32Rules;
    }
    
    if (rulesData.containsKey('uint64')) {
      final uint64Rules = UInt64Rules();
      final uint64Data = rulesData['uint64'] as Map<String, dynamic>;
      _populateNumericRules(uint64Rules, uint64Data);
      rules.uint64 = uint64Rules;
    }
    
    if (rulesData.containsKey('float')) {
      final floatRules = FloatRules();
      final floatData = rulesData['float'] as Map<String, dynamic>;
      _populateNumericRules(floatRules, floatData);
      if (floatData.containsKey('finite')) {
        floatRules.finite = floatData['finite'] as bool;
      }
      rules.float = floatRules;
    }
    
    if (rulesData.containsKey('double')) {
      final doubleRules = DoubleRules();
      final doubleData = rulesData['double'] as Map<String, dynamic>;
      _populateNumericRules(doubleRules, doubleData);
      if (doubleData.containsKey('finite')) {
        doubleRules.finite = doubleData['finite'] as bool;
      }
      rules.double_2 = doubleRules;
    }
    
    if (rulesData.containsKey('string')) {
      final stringRules = StringRules();
      final stringData = rulesData['string'] as Map<String, dynamic>;
      _populateStringRules(stringRules, stringData);
      rules.string_14 = stringRules;
    }
    
    if (rulesData.containsKey('bytes')) {
      final bytesRules = BytesRules();
      final bytesData = rulesData['bytes'] as Map<String, dynamic>;
      _populateBytesRules(bytesRules, bytesData);
      rules.bytes_15 = bytesRules;
    }
    
    if (rulesData.containsKey('enum')) {
      final enumRules = EnumRules();
      final enumData = rulesData['enum'] as Map<String, dynamic>;
      _populateEnumRules(enumRules, enumData);
      rules.enum_16 = enumRules;
    }
    
    if (rulesData.containsKey('repeated')) {
      final repeatedRules = RepeatedRules();
      final repeatedData = rulesData['repeated'] as Map<String, dynamic>;
      _populateRepeatedRules(repeatedRules, repeatedData);
      rules.repeated = repeatedRules;
    }
    
    if (rulesData.containsKey('map')) {
      final mapRules = MapRules();
      final mapData = rulesData['map'] as Map<String, dynamic>;
      _populateMapRules(mapRules, mapData);
      rules.map = mapRules;
    }
    
    if (rulesData.containsKey('message')) {
      final messageRules = MessageRules();
      final messageData = rulesData['message'] as Map<String, dynamic>;
      if (messageData.containsKey('skip')) {
        messageRules.skip = messageData['skip'] as bool;
      }
      if (messageData.containsKey('required')) {
        messageRules.required_26 = messageData['required'] as bool;
      }
      rules.message = messageRules;
    }
    
    // Handle top-level field rules
    if (rulesData.containsKey('required')) {
      rules.required_25 = rulesData['required'] as bool;
    }
    
    if (rulesData.containsKey('ignore')) {
      final ignoreStr = rulesData['ignore'] as String;
      rules.ignore = _parseIgnore(ignoreStr);
    }
    
    return rules;
  }
  
  void _populateNumericRules(dynamic rules, Map<String, dynamic> data) {
    if (data.containsKey('const')) {
      rules.const_1 = data['const'];
    }
    if (data.containsKey('lt')) {
      rules.lt = data['lt'];
    }
    if (data.containsKey('lte')) {
      rules.lte = data['lte'];
    }
    if (data.containsKey('gt')) {
      rules.gt = data['gt'];
    }
    if (data.containsKey('gte')) {
      rules.gte = data['gte'];
    }
    if (data.containsKey('in')) {
      rules.in_6.addAll(data['in'] as List);
    }
    if (data.containsKey('not_in')) {
      rules.notIn.addAll(data['not_in'] as List);
    }
  }
  
  void _populateStringRules(StringRules rules, Map<String, dynamic> data) {
    if (data.containsKey('const')) {
      rules.const_1 = data['const'] as String;
    }
    if (data.containsKey('len')) {
      rules.len = data['len'] as int;
    }
    if (data.containsKey('min_len')) {
      rules.minLen = data['min_len'] as int;
    }
    if (data.containsKey('max_len')) {
      rules.maxLen = data['max_len'] as int;
    }
    if (data.containsKey('min_bytes')) {
      rules.minBytes = data['min_bytes'] as int;
    }
    if (data.containsKey('max_bytes')) {
      rules.maxBytes = data['max_bytes'] as int;
    }
    if (data.containsKey('pattern')) {
      rules.pattern = data['pattern'] as String;
    }
    if (data.containsKey('prefix')) {
      rules.prefix = data['prefix'] as String;
    }
    if (data.containsKey('suffix')) {
      rules.suffix = data['suffix'] as String;
    }
    if (data.containsKey('contains')) {
      rules.contains_9 = data['contains'] as String;
    }
    if (data.containsKey('not_contains')) {
      rules.notContains = data['not_contains'] as String;
    }
    if (data.containsKey('in')) {
      rules.in_10.addAll(data['in'] as List<String>);
    }
    if (data.containsKey('not_in')) {
      rules.notIn.addAll(data['not_in'] as List<String>);
    }
    
    // Well-known formats
    if (data.containsKey('email') && data['email'] == true) {
      rules.email = true;
    }
    if (data.containsKey('hostname') && data['hostname'] == true) {
      rules.hostname = true;
    }
    if (data.containsKey('ip') && data['ip'] == true) {
      rules.ip = true;
    }
    if (data.containsKey('ipv4') && data['ipv4'] == true) {
      rules.ipv4 = true;
    }
    if (data.containsKey('ipv6') && data['ipv6'] == true) {
      rules.ipv6 = true;
    }
    if (data.containsKey('uri') && data['uri'] == true) {
      rules.uri = true;
    }
    if (data.containsKey('uri_ref') && data['uri_ref'] == true) {
      rules.uriRef = true;
    }
    if (data.containsKey('uuid') && data['uuid'] == true) {
      rules.uuid = true;
    }
  }
  
  void _populateBytesRules(BytesRules rules, Map<String, dynamic> data) {
    if (data.containsKey('const')) {
      rules.const_1 = (data['const'] as List<int>);
    }
    if (data.containsKey('len')) {
      rules.len = data['len'] as int;
    }
    if (data.containsKey('min_len')) {
      rules.minLen = data['min_len'] as int;
    }
    if (data.containsKey('max_len')) {
      rules.maxLen = data['max_len'] as int;
    }
    if (data.containsKey('pattern')) {
      rules.pattern = data['pattern'] as String;
    }
    if (data.containsKey('prefix')) {
      rules.prefix = (data['prefix'] as List<int>);
    }
    if (data.containsKey('suffix')) {
      rules.suffix = (data['suffix'] as List<int>);
    }
    if (data.containsKey('contains')) {
      rules.contains_7 = (data['contains'] as List<int>);
    }
    if (data.containsKey('in')) {
      for (final item in data['in'] as List) {
        rules.in_8.add(item as List<int>);
      }
    }
    if (data.containsKey('not_in')) {
      for (final item in data['not_in'] as List) {
        rules.notIn.add(item as List<int>);
      }
    }
  }
  
  void _populateEnumRules(EnumRules rules, Map<String, dynamic> data) {
    if (data.containsKey('const')) {
      rules.const_1 = data['const'] as int;
    }
    if (data.containsKey('defined_only')) {
      rules.definedOnly = data['defined_only'] as bool;
    }
    if (data.containsKey('in')) {
      rules.in_3.addAll(data['in'] as List<int>);
    }
    if (data.containsKey('not_in')) {
      rules.notIn.addAll(data['not_in'] as List<int>);
    }
  }
  
  void _populateRepeatedRules(RepeatedRules rules, Map<String, dynamic> data) {
    if (data.containsKey('min_items')) {
      rules.minItems = data['min_items'] as int;
    }
    if (data.containsKey('max_items')) {
      rules.maxItems = data['max_items'] as int;
    }
    if (data.containsKey('unique')) {
      rules.unique = data['unique'] as bool;
    }
    if (data.containsKey('items')) {
      rules.items = createFieldRulesForTesting('', '', data['items'] as Map<String, dynamic>);
    }
  }
  
  void _populateMapRules(MapRules rules, Map<String, dynamic> data) {
    if (data.containsKey('min_pairs')) {
      rules.minPairs = data['min_pairs'] as int;
    }
    if (data.containsKey('max_pairs')) {
      rules.maxPairs = data['max_pairs'] as int;
    }
    if (data.containsKey('no_sparse')) {
      rules.noSparse = data['no_sparse'] as bool;
    }
    if (data.containsKey('keys')) {
      rules.keys = createFieldRulesForTesting('', '', data['keys'] as Map<String, dynamic>);
    }
    if (data.containsKey('values')) {
      rules.values = createFieldRulesForTesting('', '', data['values'] as Map<String, dynamic>);
    }
  }
  
  Ignore _parseIgnore(String value) {
    switch (value) {
      case 'ALWAYS':
        return Ignore.ALWAYS;
      case 'IF_UNPOPULATED':
        return Ignore.IF_UNPOPULATED;
      case 'IF_DEFAULT_VALUE':
        return Ignore.IF_DEFAULT_VALUE;
      default:
        return Ignore.DEFAULT;
    }
  }
}