// This is a generated file - do not edit.
//
// Generated from buf/validate/conformance/cases/custom_rules/custom_rules.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum Enum implements $pb.ProtobufEnum {
  ENUM_UNSPECIFIED(0, _omitEnumNames ? '' : 'ENUM_UNSPECIFIED'),

  ENUM_ONE(1, _omitEnumNames ? '' : 'ENUM_ONE'),
  ;

  static final $core.Map<$core.int, Enum> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Enum? valueOf($core.int value) => _byValue[value];

  @$core.override
  final $core.int value;

  @$core.override
  final $core.String name;

  const Enum(this.value, this.name);

  /// Returns this enum's [name] or the [value] if names are not represented.
  @$core.override
  $core.String toString() => name == '' ? value.toString() : name;
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
