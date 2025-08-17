// This is a generated file - do not edit.
//
// Generated from buf/validate/conformance/cases/other_package/embed.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum Embed_Enumerated implements $pb.ProtobufEnum {
  ENUMERATED_UNSPECIFIED(0, _omitEnumNames ? '' : 'ENUMERATED_UNSPECIFIED'),

  ENUMERATED_VALUE(1, _omitEnumNames ? '' : 'ENUMERATED_VALUE'),
  ;

  static final $core.Map<$core.int, Embed_Enumerated> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Embed_Enumerated? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const Embed_Enumerated(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

enum Embed_DoubleEmbed_DoubleEnumerated implements $pb.ProtobufEnum {
  DOUBLE_ENUMERATED_UNSPECIFIED(
      0, _omitEnumNames ? '' : 'DOUBLE_ENUMERATED_UNSPECIFIED'),

  DOUBLE_ENUMERATED_VALUE(1, _omitEnumNames ? '' : 'DOUBLE_ENUMERATED_VALUE'),
  ;

  static final $core.Map<$core.int, Embed_DoubleEmbed_DoubleEnumerated>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static Embed_DoubleEmbed_DoubleEnumerated? valueOf($core.int value) =>
      _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const Embed_DoubleEmbed_DoubleEnumerated(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
