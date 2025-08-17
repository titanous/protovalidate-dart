// This is a generated file - do not edit.
//
// Generated from google/protobuf/descriptor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// The full set of known editions.
enum Edition implements $pb.ProtobufEnum {
  /// A placeholder for an unknown edition value.
  EDITION_UNKNOWN(0, _omitEnumNames ? '' : 'EDITION_UNKNOWN'),

  /// A placeholder edition for specifying default behaviors *before* a feature
  /// was first introduced.  This is effectively an "infinite past".
  EDITION_LEGACY(900, _omitEnumNames ? '' : 'EDITION_LEGACY'),

  /// Legacy syntax "editions".  These pre-date editions, but behave much like
  /// distinct editions.  These can't be used to specify the edition of proto
  /// files, but feature definitions must supply proto2/proto3 defaults for
  /// backwards compatibility.
  EDITION_PROTO2(998, _omitEnumNames ? '' : 'EDITION_PROTO2'),

  EDITION_PROTO3(999, _omitEnumNames ? '' : 'EDITION_PROTO3'),

  /// Editions that have been released.  The specific values are arbitrary and
  /// should not be depended on, but they will always be time-ordered for easy
  /// comparison.
  EDITION_2023(1000, _omitEnumNames ? '' : 'EDITION_2023'),

  EDITION_2024(1001, _omitEnumNames ? '' : 'EDITION_2024'),

  /// Placeholder editions for testing feature resolution.  These should not be
  /// used or relied on outside of tests.
  EDITION_1_TEST_ONLY(1, _omitEnumNames ? '' : 'EDITION_1_TEST_ONLY'),

  EDITION_2_TEST_ONLY(2, _omitEnumNames ? '' : 'EDITION_2_TEST_ONLY'),

  EDITION_99997_TEST_ONLY(
      99997, _omitEnumNames ? '' : 'EDITION_99997_TEST_ONLY'),

  EDITION_99998_TEST_ONLY(
      99998, _omitEnumNames ? '' : 'EDITION_99998_TEST_ONLY'),

  EDITION_99999_TEST_ONLY(
      99999, _omitEnumNames ? '' : 'EDITION_99999_TEST_ONLY'),

  /// Placeholder for specifying unbounded edition support.  This should only
  /// ever be used by plugins that can expect to never require any changes to
  /// support a new edition.
  EDITION_MAX(2147483647, _omitEnumNames ? '' : 'EDITION_MAX'),
  ;

  static final $core.Map<$core.int, Edition> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Edition? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const Edition(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// Describes the 'visibility' of a symbol with respect to the proto import
/// system. Symbols can only be imported when the visibility rules do not prevent
/// it (ex: local symbols cannot be imported).  Visibility modifiers can only set
/// on `message` and `enum` as they are the only types available to be referenced
/// from other files.
enum SymbolVisibility implements $pb.ProtobufEnum {
  VISIBILITY_UNSET(0, _omitEnumNames ? '' : 'VISIBILITY_UNSET'),

  VISIBILITY_LOCAL(1, _omitEnumNames ? '' : 'VISIBILITY_LOCAL'),

  VISIBILITY_EXPORT(2, _omitEnumNames ? '' : 'VISIBILITY_EXPORT'),
  ;

  static final $core.Map<$core.int, SymbolVisibility> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SymbolVisibility? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const SymbolVisibility(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// The verification state of the extension range.
enum ExtensionRangeOptions_VerificationState implements $pb.ProtobufEnum {
  /// All the extensions of the range must be declared.
  DECLARATION(0, _omitEnumNames ? '' : 'DECLARATION'),

  UNVERIFIED(1, _omitEnumNames ? '' : 'UNVERIFIED'),
  ;

  static final $core.Map<$core.int, ExtensionRangeOptions_VerificationState>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static ExtensionRangeOptions_VerificationState? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const ExtensionRangeOptions_VerificationState(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FieldDescriptorProto_Type implements $pb.ProtobufEnum {
  /// 0 is reserved for errors.
  /// Order is weird for historical reasons.
  TYPE_DOUBLE(1, _omitEnumNames ? '' : 'TYPE_DOUBLE'),

  TYPE_FLOAT(2, _omitEnumNames ? '' : 'TYPE_FLOAT'),

  /// Not ZigZag encoded.  Negative numbers take 10 bytes.  Use TYPE_SINT64 if
  /// negative values are likely.
  TYPE_INT64(3, _omitEnumNames ? '' : 'TYPE_INT64'),

  TYPE_UINT64(4, _omitEnumNames ? '' : 'TYPE_UINT64'),

  /// Not ZigZag encoded.  Negative numbers take 10 bytes.  Use TYPE_SINT32 if
  /// negative values are likely.
  TYPE_INT32(5, _omitEnumNames ? '' : 'TYPE_INT32'),

  TYPE_FIXED64(6, _omitEnumNames ? '' : 'TYPE_FIXED64'),

  TYPE_FIXED32(7, _omitEnumNames ? '' : 'TYPE_FIXED32'),

  TYPE_BOOL(8, _omitEnumNames ? '' : 'TYPE_BOOL'),

  TYPE_STRING(9, _omitEnumNames ? '' : 'TYPE_STRING'),

  /// Tag-delimited aggregate.
  /// Group type is deprecated and not supported after google.protobuf. However, Proto3
  /// implementations should still be able to parse the group wire format and
  /// treat group fields as unknown fields.  In Editions, the group wire format
  /// can be enabled via the `message_encoding` feature.
  TYPE_GROUP(10, _omitEnumNames ? '' : 'TYPE_GROUP'),

  TYPE_MESSAGE(11, _omitEnumNames ? '' : 'TYPE_MESSAGE'),

  /// New in version 2.
  TYPE_BYTES(12, _omitEnumNames ? '' : 'TYPE_BYTES'),

  TYPE_UINT32(13, _omitEnumNames ? '' : 'TYPE_UINT32'),

  TYPE_ENUM(14, _omitEnumNames ? '' : 'TYPE_ENUM'),

  TYPE_SFIXED32(15, _omitEnumNames ? '' : 'TYPE_SFIXED32'),

  TYPE_SFIXED64(16, _omitEnumNames ? '' : 'TYPE_SFIXED64'),

  TYPE_SINT32(17, _omitEnumNames ? '' : 'TYPE_SINT32'),

  TYPE_SINT64(18, _omitEnumNames ? '' : 'TYPE_SINT64'),
  ;

  static final $core.Map<$core.int, FieldDescriptorProto_Type> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldDescriptorProto_Type? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldDescriptorProto_Type(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FieldDescriptorProto_Label implements $pb.ProtobufEnum {
  /// 0 is reserved for errors
  LABEL_OPTIONAL(1, _omitEnumNames ? '' : 'LABEL_OPTIONAL'),

  LABEL_REPEATED(3, _omitEnumNames ? '' : 'LABEL_REPEATED'),

  /// The required label is only allowed in google.protobuf.  In proto3 and Editions
  /// it's explicitly prohibited.  In Editions, the `field_presence` feature
  /// can be used to get this behavior.
  LABEL_REQUIRED(2, _omitEnumNames ? '' : 'LABEL_REQUIRED'),
  ;

  static final $core.Map<$core.int, FieldDescriptorProto_Label> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldDescriptorProto_Label? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldDescriptorProto_Label(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// Generated classes can be optimized for speed or code size.
enum FileOptions_OptimizeMode implements $pb.ProtobufEnum {
  SPEED(1, _omitEnumNames ? '' : 'SPEED'),

  /// etc.
  CODE_SIZE(2, _omitEnumNames ? '' : 'CODE_SIZE'),

  LITE_RUNTIME(3, _omitEnumNames ? '' : 'LITE_RUNTIME'),
  ;

  static final $core.Map<$core.int, FileOptions_OptimizeMode> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FileOptions_OptimizeMode? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FileOptions_OptimizeMode(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FieldOptions_CType implements $pb.ProtobufEnum {
  /// Default mode.
  STRING(0, _omitEnumNames ? '' : 'STRING'),

  /// The option [ctype=CORD] may be applied to a non-repeated field of type
  /// "bytes". It indicates that in C++, the data should be stored in a Cord
  /// instead of a string.  For very large strings, this may reduce memory
  /// fragmentation. It may also allow better performance when parsing from a
  /// Cord, or when parsing with aliasing enabled, as the parsed Cord may then
  /// alias the original buffer.
  CORD(1, _omitEnumNames ? '' : 'CORD'),

  STRING_PIECE(2, _omitEnumNames ? '' : 'STRING_PIECE'),
  ;

  static final $core.Map<$core.int, FieldOptions_CType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_CType? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldOptions_CType(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FieldOptions_JSType implements $pb.ProtobufEnum {
  /// Use the default type.
  JS_NORMAL(0, _omitEnumNames ? '' : 'JS_NORMAL'),

  /// Use JavaScript strings.
  JS_STRING(1, _omitEnumNames ? '' : 'JS_STRING'),

  /// Use JavaScript numbers.
  JS_NUMBER(2, _omitEnumNames ? '' : 'JS_NUMBER'),
  ;

  static final $core.Map<$core.int, FieldOptions_JSType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_JSType? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldOptions_JSType(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// If set to RETENTION_SOURCE, the option will be omitted from the binary.
enum FieldOptions_OptionRetention implements $pb.ProtobufEnum {
  RETENTION_UNKNOWN(0, _omitEnumNames ? '' : 'RETENTION_UNKNOWN'),

  RETENTION_RUNTIME(1, _omitEnumNames ? '' : 'RETENTION_RUNTIME'),

  RETENTION_SOURCE(2, _omitEnumNames ? '' : 'RETENTION_SOURCE'),
  ;

  static final $core.Map<$core.int, FieldOptions_OptionRetention> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_OptionRetention? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldOptions_OptionRetention(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// This indicates the types of entities that the field may apply to when used
/// as an option. If it is unset, then the field may be freely used as an
/// option on any kind of entity.
enum FieldOptions_OptionTargetType implements $pb.ProtobufEnum {
  TARGET_TYPE_UNKNOWN(0, _omitEnumNames ? '' : 'TARGET_TYPE_UNKNOWN'),

  TARGET_TYPE_FILE(1, _omitEnumNames ? '' : 'TARGET_TYPE_FILE'),

  TARGET_TYPE_EXTENSION_RANGE(
      2, _omitEnumNames ? '' : 'TARGET_TYPE_EXTENSION_RANGE'),

  TARGET_TYPE_MESSAGE(3, _omitEnumNames ? '' : 'TARGET_TYPE_MESSAGE'),

  TARGET_TYPE_FIELD(4, _omitEnumNames ? '' : 'TARGET_TYPE_FIELD'),

  TARGET_TYPE_ONEOF(5, _omitEnumNames ? '' : 'TARGET_TYPE_ONEOF'),

  TARGET_TYPE_ENUM(6, _omitEnumNames ? '' : 'TARGET_TYPE_ENUM'),

  TARGET_TYPE_ENUM_ENTRY(7, _omitEnumNames ? '' : 'TARGET_TYPE_ENUM_ENTRY'),

  TARGET_TYPE_SERVICE(8, _omitEnumNames ? '' : 'TARGET_TYPE_SERVICE'),

  TARGET_TYPE_METHOD(9, _omitEnumNames ? '' : 'TARGET_TYPE_METHOD'),
  ;

  static final $core.Map<$core.int, FieldOptions_OptionTargetType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FieldOptions_OptionTargetType? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FieldOptions_OptionTargetType(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// Is this method side-effect-free (or safe in HTTP parlance), or idempotent,
/// or neither? HTTP based RPC implementation may choose GET verb for safe
/// methods, and PUT verb for idempotent methods instead of the default POST.
enum MethodOptions_IdempotencyLevel implements $pb.ProtobufEnum {
  IDEMPOTENCY_UNKNOWN(0, _omitEnumNames ? '' : 'IDEMPOTENCY_UNKNOWN'),

  NO_SIDE_EFFECTS(1, _omitEnumNames ? '' : 'NO_SIDE_EFFECTS'),

  IDEMPOTENT(2, _omitEnumNames ? '' : 'IDEMPOTENT'),
  ;

  static final $core.Map<$core.int, MethodOptions_IdempotencyLevel> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static MethodOptions_IdempotencyLevel? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const MethodOptions_IdempotencyLevel(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_FieldPresence implements $pb.ProtobufEnum {
  FIELD_PRESENCE_UNKNOWN(0, _omitEnumNames ? '' : 'FIELD_PRESENCE_UNKNOWN'),

  EXPLICIT(1, _omitEnumNames ? '' : 'EXPLICIT'),

  IMPLICIT(2, _omitEnumNames ? '' : 'IMPLICIT'),

  LEGACY_REQUIRED(3, _omitEnumNames ? '' : 'LEGACY_REQUIRED'),
  ;

  static final $core.Map<$core.int, FeatureSet_FieldPresence> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_FieldPresence? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_FieldPresence(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_EnumType implements $pb.ProtobufEnum {
  ENUM_TYPE_UNKNOWN(0, _omitEnumNames ? '' : 'ENUM_TYPE_UNKNOWN'),

  OPEN(1, _omitEnumNames ? '' : 'OPEN'),

  CLOSED(2, _omitEnumNames ? '' : 'CLOSED'),
  ;

  static final $core.Map<$core.int, FeatureSet_EnumType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_EnumType? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_EnumType(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_RepeatedFieldEncoding implements $pb.ProtobufEnum {
  REPEATED_FIELD_ENCODING_UNKNOWN(
      0, _omitEnumNames ? '' : 'REPEATED_FIELD_ENCODING_UNKNOWN'),

  PACKED(1, _omitEnumNames ? '' : 'PACKED'),

  EXPANDED(2, _omitEnumNames ? '' : 'EXPANDED'),
  ;

  static final $core.Map<$core.int, FeatureSet_RepeatedFieldEncoding> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_RepeatedFieldEncoding? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_RepeatedFieldEncoding(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_Utf8Validation implements $pb.ProtobufEnum {
  UTF8_VALIDATION_UNKNOWN(0, _omitEnumNames ? '' : 'UTF8_VALIDATION_UNKNOWN'),

  VERIFY(2, _omitEnumNames ? '' : 'VERIFY'),

  NONE(3, _omitEnumNames ? '' : 'NONE'),
  ;

  static final $core.Map<$core.int, FeatureSet_Utf8Validation> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_Utf8Validation? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_Utf8Validation(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_MessageEncoding implements $pb.ProtobufEnum {
  MESSAGE_ENCODING_UNKNOWN(0, _omitEnumNames ? '' : 'MESSAGE_ENCODING_UNKNOWN'),

  LENGTH_PREFIXED(1, _omitEnumNames ? '' : 'LENGTH_PREFIXED'),

  DELIMITED(2, _omitEnumNames ? '' : 'DELIMITED'),
  ;

  static final $core.Map<$core.int, FeatureSet_MessageEncoding> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_MessageEncoding? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_MessageEncoding(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_JsonFormat implements $pb.ProtobufEnum {
  JSON_FORMAT_UNKNOWN(0, _omitEnumNames ? '' : 'JSON_FORMAT_UNKNOWN'),

  ALLOW(1, _omitEnumNames ? '' : 'ALLOW'),

  LEGACY_BEST_EFFORT(2, _omitEnumNames ? '' : 'LEGACY_BEST_EFFORT'),
  ;

  static final $core.Map<$core.int, FeatureSet_JsonFormat> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_JsonFormat? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_JsonFormat(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_EnforceNamingStyle implements $pb.ProtobufEnum {
  ENFORCE_NAMING_STYLE_UNKNOWN(
      0, _omitEnumNames ? '' : 'ENFORCE_NAMING_STYLE_UNKNOWN'),

  STYLE2024(1, _omitEnumNames ? '' : 'STYLE2024'),

  STYLE_LEGACY(2, _omitEnumNames ? '' : 'STYLE_LEGACY'),
  ;

  static final $core.Map<$core.int, FeatureSet_EnforceNamingStyle> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_EnforceNamingStyle? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_EnforceNamingStyle(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum FeatureSet_VisibilityFeature_DefaultSymbolVisibility
    implements $pb.ProtobufEnum {
  DEFAULT_SYMBOL_VISIBILITY_UNKNOWN(
      0, _omitEnumNames ? '' : 'DEFAULT_SYMBOL_VISIBILITY_UNKNOWN'),

  /// Default pre-EDITION_2024, all UNSET visibility are export.
  EXPORT_ALL(1, _omitEnumNames ? '' : 'EXPORT_ALL'),

  /// All top-level symbols default to export, nested default to local.
  EXPORT_TOP_LEVEL(2, _omitEnumNames ? '' : 'EXPORT_TOP_LEVEL'),

  /// All symbols default to local.
  LOCAL_ALL(3, _omitEnumNames ? '' : 'LOCAL_ALL'),

  /// All symbols local by default. Nested types cannot be exported.
  /// With special case caveat for message { enum {} reserved 1 to max; }
  /// This is the recommended setting for new protos.
  STRICT(4, _omitEnumNames ? '' : 'STRICT'),
  ;

  static final $core
      .Map<$core.int, FeatureSet_VisibilityFeature_DefaultSymbolVisibility>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static FeatureSet_VisibilityFeature_DefaultSymbolVisibility? valueOf(
          $core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const FeatureSet_VisibilityFeature_DefaultSymbolVisibility(
      this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

/// Represents the identified object's effect on the element in the original
/// .proto file.
enum GeneratedCodeInfo_Annotation_Semantic implements $pb.ProtobufEnum {
  /// There is no effect or the effect is indescribable.
  NONE(0, _omitEnumNames ? '' : 'NONE'),

  /// The element is set or otherwise mutated.
  SET(1, _omitEnumNames ? '' : 'SET'),

  /// An alias to the element is returned.
  ALIAS(2, _omitEnumNames ? '' : 'ALIAS'),
  ;

  static final $core.Map<$core.int, GeneratedCodeInfo_Annotation_Semantic>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static GeneratedCodeInfo_Annotation_Semantic? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const GeneratedCodeInfo_Annotation_Semantic(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
