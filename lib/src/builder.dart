import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protovalidate/src/gen/buf/validate/validate.pb.dart';
import 'package:protovalidate/src/gen/google/protobuf/duration.pb.dart' as pb_duration;
import 'package:protovalidate/src/gen/google/protobuf/timestamp.pb.dart' as pb_timestamp;
import 'package:protovalidate/src/gen/google/protobuf/any.pb.dart' as pb_any;
import 'package:protovalidate/src/gen/google/protobuf/wrappers.pb.dart';
import 'descriptor_rules.dart';
import 'evaluator.dart';
import 'rules/scalar.dart';
import 'rules/enum.dart';
import 'rules/message.dart';
import 'rules/wkt.dart';
import 'error.dart';
import 'cursor.dart';

/// Builds evaluators from validation rules.
class EvaluatorBuilder {
  /// Cache of compiled evaluators by message type.
  final Map<Type, Evaluator> _cache = {};
  
  /// Optional descriptor rules for extracting validation rules from FileDescriptorSet.
  final DescriptorRules? descriptorRules;
  
  EvaluatorBuilder({this.descriptorRules});
  
  /// Builds an evaluator for the given message type.
  Evaluator buildForMessage(GeneratedMessage message) {
    final messageType = message.runtimeType;
    
    // Check cache
    if (_cache.containsKey(messageType)) {
      return _cache[messageType]!;
    }
    
    // Build evaluator
    final evaluator = _buildMessageEvaluator(message);
    _cache[messageType] = evaluator;
    return evaluator;
  }
  
  /// Builds a message evaluator.
  Evaluator _buildMessageEvaluator(GeneratedMessage message) {
    final evaluators = <Evaluator>[];
    
    // Build field evaluators
    for (final field in message.info_.fieldInfo.values) {
      final fieldEvaluator = _buildFieldEvaluator(field, message);
      if (fieldEvaluator != null) {
        evaluators.add(fieldEvaluator);
      }
    }
    
    if (evaluators.isEmpty) {
      // Return a no-op evaluator
      return NoOpEvaluator();
    }
    
    return CompositeEvaluator(evaluators);
  }
  
  /// Builds a field evaluator.
  Evaluator? _buildFieldEvaluator(FieldInfo field, GeneratedMessage message) {
    // Try to get field rules from the descriptor if available
    FieldRules? fieldRules;
    if (descriptorRules != null) {
      final messageTypeName = descriptorRules!.getFullTypeName(message);
      fieldRules = descriptorRules!.getFieldRules(messageTypeName, field.name);
    }
    
    // If we have field rules, build evaluator from them
    if (fieldRules != null) {
      final evaluator = buildFromFieldRules(fieldRules);
      if (evaluator != null) {
        return FieldValidatorWrapper(field, evaluator, rules: fieldRules);
      }
    }
    
    // Fall back to basic type validation
    // Handle repeated fields
    if (field.isRepeated && !field.isMapField) {
      final itemEvaluator = _buildScalarEvaluator(field);
      if (itemEvaluator != null) {
        return FieldValidatorWrapper(
          field,
          RepeatedFieldEvaluator(itemEvaluator: itemEvaluator),
        );
      }
    }
    
    // Handle map fields
    if (field.isMapField) {
      // For map fields, we need map rules from fieldRules
      if (fieldRules?.hasMap() == true) {
        final mapEvaluator = _buildMapEvaluator(fieldRules!.map);
        return FieldValidatorWrapper(field, mapEvaluator, rules: fieldRules);
      }
      return null;
    }
    
    // Handle message fields
    if (field.type == PbFieldType.OM || field.type == PbFieldType.PM) {
      // For message fields, check for required/ignore rules
      final messageEvaluator = MessageFieldEvaluator(
        required: fieldRules?.required ?? false,
        ignore: fieldRules?.hasIgnore() == true ? fieldRules!.ignore : null,
        nestedEvaluator: null, // Would need to recursively build for the nested type
      );
      return FieldValidatorWrapper(field, messageEvaluator, rules: fieldRules);
    }
    
    // Handle enum fields
    if (field.type == PbFieldType.OE || field.type == PbFieldType.PE) {
      if (fieldRules?.hasEnum_16() == true) {
        final enumEvaluator = _buildEnumEvaluator(fieldRules!.enum_16);
        return FieldValidatorWrapper(field, enumEvaluator, rules: fieldRules);
      } else {
        // Basic enum evaluator
        return FieldValidatorWrapper(field, EnumEvaluator());
      }
    }
    
    // Handle scalar fields
    final scalarEvaluator = _buildScalarEvaluator(field);
    if (scalarEvaluator != null) {
      return FieldValidatorWrapper(field, scalarEvaluator);
    }
    
    return null;
  }
  
  /// Builds a scalar evaluator based on field type.
  Evaluator? _buildScalarEvaluator(FieldInfo field) {
    // For now, create basic type validators
    // In a full implementation, we would read the actual rules from extensions
    
    switch (field.type) {
      case PbFieldType.OB:
      case PbFieldType.PB:
        return BoolEvaluator();
        
      case PbFieldType.O3:
      case PbFieldType.P3:
        return Int32Evaluator();
        
      case PbFieldType.O6:
      case PbFieldType.P6:
        return Int64Evaluator();
        
      case PbFieldType.OU3:
      case PbFieldType.PU3:
        return UInt32Evaluator();
        
      case PbFieldType.OU6:
      case PbFieldType.PU6:
        return UInt64Evaluator();
        
      case PbFieldType.OS3:
      case PbFieldType.PS3:
        return SInt32Evaluator();
        
      case PbFieldType.OS6:
      case PbFieldType.PS6:
        return SInt64Evaluator();
        
      case PbFieldType.OSF3:
      case PbFieldType.PSF3:
        return SFixed32Evaluator();
        
      case PbFieldType.OSF6:
      case PbFieldType.PSF6:
        return SFixed64Evaluator();
        
      case PbFieldType.OF3:
      case PbFieldType.PF3:
        return Fixed32Evaluator();
        
      case PbFieldType.OF6:
      case PbFieldType.PF6:
        return Fixed64Evaluator();
        
      case PbFieldType.OF:
      case PbFieldType.PF:
        return FloatEvaluator();
        
      case PbFieldType.OD:
      case PbFieldType.PD:
        return DoubleEvaluator();
        
      case PbFieldType.OS:
      case PbFieldType.PS:
        return StringRulesEvaluator();
        
      case PbFieldType.OY:
      case PbFieldType.PY:
        return BytesEvaluator();
        
      default:
        return null;
    }
  }
  
  /// Builds an evaluator from field rules.
  Evaluator? buildFromFieldRules(FieldRules rules) {
    // Build evaluator based on the type in the rules
    if (rules.hasBool_13()) {
      return _buildBoolEvaluator(rules.bool_13);
    }
    if (rules.hasInt32()) {
      return _buildInt32Evaluator(rules.int32);
    }
    if (rules.hasInt64()) {
      return _buildInt64Evaluator(rules.int64);
    }
    if (rules.hasUint32()) {
      return _buildUInt32Evaluator(rules.uint32);
    }
    if (rules.hasUint64()) {
      return _buildUInt64Evaluator(rules.uint64);
    }
    if (rules.hasSint32()) {
      return _buildSInt32Evaluator(rules.sint32);
    }
    if (rules.hasSint64()) {
      return _buildSInt64Evaluator(rules.sint64);
    }
    if (rules.hasFixed32()) {
      return _buildFixed32Evaluator(rules.fixed32);
    }
    if (rules.hasFixed64()) {
      return _buildFixed64Evaluator(rules.fixed64);
    }
    if (rules.hasSfixed32()) {
      return _buildSFixed32Evaluator(rules.sfixed32);
    }
    if (rules.hasSfixed64()) {
      return _buildSFixed64Evaluator(rules.sfixed64);
    }
    if (rules.hasFloat()) {
      return _buildFloatEvaluator(rules.float);
    }
    if (rules.hasDouble_2()) {
      return _buildDoubleEvaluator(rules.double_2);
    }
    if (rules.hasString()) {
      return _buildStringEvaluator(rules.string);
    }
    if (rules.hasBytes()) {
      return _buildBytesEvaluator(rules.bytes);
    }
    if (rules.hasEnum_16()) {
      return _buildEnumEvaluator(rules.enum_16);
    }
    if (rules.hasRepeated()) {
      return _buildRepeatedEvaluator(rules.repeated);
    }
    if (rules.hasMap()) {
      return _buildMapEvaluator(rules.map);
    }
    // Handle WKT types
    if (rules.hasDuration()) {
      return _buildDurationEvaluator(rules.duration);
    }
    if (rules.hasTimestamp()) {
      return _buildTimestampEvaluator(rules.timestamp);
    }
    if (rules.hasAny()) {
      return _buildAnyEvaluator(rules.any);
    }
    
    return null;
  }
  
  Evaluator _buildBoolEvaluator(BoolRules rules) {
    return BoolEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
    );
  }
  
  Evaluator _buildInt32Evaluator(Int32Rules rules) {
    return Int32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildInt64Evaluator(Int64Rules rules) {
    return Int64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildUInt32Evaluator(UInt32Rules rules) {
    return UInt32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildUInt64Evaluator(UInt64Rules rules) {
    return UInt64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildFloatEvaluator(FloatRules rules) {
    return FloatEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      finite: rules.hasFinite() ? rules.finite : null,
    );
  }
  
  Evaluator _buildDoubleEvaluator(DoubleRules rules) {
    return DoubleEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      finite: rules.hasFinite() ? rules.finite : null,
    );
  }
  
  Evaluator _buildSInt32Evaluator(SInt32Rules rules) {
    return SInt32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildSInt64Evaluator(SInt64Rules rules) {
    return SInt64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildFixed32Evaluator(Fixed32Rules rules) {
    return Fixed32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildFixed64Evaluator(Fixed64Rules rules) {
    return Fixed64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildSFixed32Evaluator(SFixed32Rules rules) {
    return SFixed32Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildSFixed64Evaluator(SFixed64Rules rules) {
    return SFixed64Evaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      lt: rules.hasLt() ? rules.lt : null,
      lte: rules.hasLte() ? rules.lte : null,
      gt: rules.hasGt() ? rules.gt : null,
      gte: rules.hasGte() ? rules.gte : null,
      inValues: rules.in_6.isNotEmpty ? rules.in_6 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
    );
  }
  
  Evaluator _buildStringEvaluator(StringRules rules) {
    return StringRulesEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      len: rules.hasLen() ? rules.len.toInt() : null,
      minLen: rules.hasMinLen() ? rules.minLen.toInt() : null,
      maxLen: rules.hasMaxLen() ? rules.maxLen.toInt() : null,
      minBytes: rules.hasMinBytes() ? rules.minBytes.toInt() : null,
      maxBytes: rules.hasMaxBytes() ? rules.maxBytes.toInt() : null,
      pattern: rules.hasPattern() ? rules.pattern : null,
      prefix: rules.hasPrefix() ? rules.prefix : null,
      suffix: rules.hasSuffix() ? rules.suffix : null,
      contains: rules.hasContains() ? rules.contains : null,
      notContains: rules.hasNotContains() ? rules.notContains : null,
      inValues: rules.in_10.isNotEmpty ? rules.in_10 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      email: rules.hasEmail() ? rules.email : null,
      hostname: rules.hasHostname() ? rules.hostname : null,
      ip: rules.hasIp() ? rules.ip : null,
      ipv4: rules.hasIpv4() ? rules.ipv4 : null,
      ipv6: rules.hasIpv6() ? rules.ipv6 : null,
      uri: rules.hasUri() ? rules.uri : null,
      uriRef: rules.hasUriRef() ? rules.uriRef : null,
      address: rules.hasAddress() ? rules.address : null,
      uuid: rules.hasUuid() ? rules.uuid : null,
      wellKnownRegex: rules.hasWellKnownRegex() ? (rules.wellKnownRegex.value > 0) : null,
    );
  }
  
  Evaluator _buildBytesEvaluator(BytesRules rules) {
    return BytesEvaluator(
      constValue: rules.hasConst_1() ? rules.const_1 : null,
      len: rules.hasLen() ? rules.len.toInt() : null,
      minLen: rules.hasMinLen() ? rules.minLen.toInt() : null,
      maxLen: rules.hasMaxLen() ? rules.maxLen.toInt() : null,
      pattern: rules.hasPattern() ? rules.pattern : null,
      prefix: rules.hasPrefix() ? rules.prefix : null,
      suffix: rules.hasSuffix() ? rules.suffix : null,
      contains: rules.hasContains() ? rules.contains : null,
      inValues: rules.in_8.isNotEmpty ? rules.in_8 : null,
      notInValues: rules.notIn.isNotEmpty ? rules.notIn : null,
      ip: rules.hasIp() ? rules.ip : null,
      ipv4: rules.hasIpv4() ? rules.ipv4 : null,
      ipv6: rules.hasIpv6() ? rules.ipv6 : null,
    );
  }
  
  Evaluator _buildEnumEvaluator(EnumRules rules) {
    // TODO: Need to get enum value names from the field descriptor
    // For now, just return the basic enum rules evaluator
    return EnumRulesEvaluator(
      rules: rules,
      enumValueNames: null, // Would need to be populated from field descriptor
    );
  }
  
  Evaluator _buildRepeatedEvaluator(RepeatedRules rules) {
    // Build item evaluator from rules.items if present
    Evaluator? itemEvaluator;
    if (rules.hasItems()) {
      itemEvaluator = buildFromFieldRules(rules.items);
    }
    
    // If no item evaluator, use a no-op
    itemEvaluator ??= NoOpEvaluator();
    
    return RepeatedFieldEvaluator(
      itemEvaluator: itemEvaluator,
      minItems: rules.hasMinItems() ? rules.minItems.toInt() : null,
      maxItems: rules.hasMaxItems() ? rules.maxItems.toInt() : null,
      unique: rules.hasUnique() ? rules.unique : null,
    );
  }
  
  Evaluator _buildMapEvaluator(MapRules rules) {
    // Build key and value evaluators from rules if present
    Evaluator? keyEvaluator;
    if (rules.hasKeys()) {
      keyEvaluator = buildFromFieldRules(rules.keys);
    }
    
    Evaluator? valueEvaluator;
    if (rules.hasValues()) {
      valueEvaluator = buildFromFieldRules(rules.values);
    }
    
    return MapFieldEvaluator(
      keyEvaluator: keyEvaluator,
      valueEvaluator: valueEvaluator,
      minPairs: rules.hasMinPairs() ? rules.minPairs.toInt() : null,
      maxPairs: rules.hasMaxPairs() ? rules.maxPairs.toInt() : null,
    );
  }
  
  Evaluator _buildDurationEvaluator(DurationRules rules) {
    return DurationEvaluator(rules: rules);
  }
  
  Evaluator _buildTimestampEvaluator(TimestampRules rules) {
    return TimestampEvaluator(rules: rules);
  }
  
  Evaluator _buildAnyEvaluator(AnyRules rules) {
    return AnyEvaluator(rules: rules);
  }
  
  /// Checks if a message type is a well-known type and builds appropriate evaluator.
  Evaluator? buildWKTEvaluator(GeneratedMessage message, FieldRules? fieldRules) {
    final typeName = message.info_.messageName;
    
    // Check for wrapper types
    if (message is BoolValue) {
      return BoolValueEvaluator(rules: fieldRules?.bool_13);
    } else if (message is BytesValue) {
      return BytesValueEvaluator(rules: fieldRules?.bytes);
    } else if (message is DoubleValue) {
      return DoubleValueEvaluator(rules: fieldRules?.double_2);
    } else if (message is FloatValue) {
      return FloatValueEvaluator(rules: fieldRules?.float);
    } else if (message is Int32Value) {
      return Int32ValueEvaluator(rules: fieldRules?.int32);
    } else if (message is Int64Value) {
      return Int64ValueEvaluator(rules: fieldRules?.int64);
    } else if (message is StringValue) {
      return StringValueEvaluator(rules: fieldRules?.string);
    } else if (message is UInt32Value) {
      return UInt32ValueEvaluator(rules: fieldRules?.uint32);
    } else if (message is UInt64Value) {
      return UInt64ValueEvaluator(rules: fieldRules?.uint64);
    }
    // Check for other WKT types
    else if (message is pb_duration.Duration) {
      return DurationEvaluator(rules: fieldRules?.duration ?? DurationRules());
    } else if (message is pb_timestamp.Timestamp) {
      return TimestampEvaluator(rules: fieldRules?.timestamp ?? TimestampRules());
    } else if (message is pb_any.Any) {
      return AnyEvaluator(rules: fieldRules?.any ?? AnyRules());
    }
    
    return null;
  }
}

/// Wrapper that evaluates a field value.
class FieldValidatorWrapper implements Evaluator {
  final FieldInfo field;
  final Evaluator evaluator;
  final FieldRules? rules;
  
  FieldValidatorWrapper(this.field, this.evaluator, {this.rules});
  
  @override
  void evaluate(dynamic value, Cursor cursor) {
    if (value is! GeneratedMessage) {
      return;
    }
    
    final message = value as GeneratedMessage;
    final fieldValue = message.getField(field.tagNumber);
    
    // Check if we should skip validation based on ignore rules
    // For proto3, if field is not set and doesn't have const or required rules, skip
    final hasField = message.hasField(field.tagNumber);
    
    // Always validate if there's a const rule or required rule
    final hasConstRule = rules?.hasBool_13() == true && rules!.bool_13.hasConst_1();
    final hasRequiredRule = rules?.hasRequired() == true && rules!.required;
    
    if (!hasField && !hasConstRule && !hasRequiredRule) {
      // Skip validation for unset fields without const/required rules
      return;
    }
    
    final fieldCursor = cursor.field(field);
    evaluator.evaluate(fieldValue, fieldCursor);
  }
}

/// No-op evaluator that does nothing.
class NoOpEvaluator implements Evaluator {
  @override
  void evaluate(dynamic value, Cursor cursor) {
    // Do nothing
  }
}