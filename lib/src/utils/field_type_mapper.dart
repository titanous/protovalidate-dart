import 'package:protobuf/protobuf.dart';
import 'package:protovalidate/src/gen/google/protobuf/descriptor.pbenum.dart';

/// Utility class for converting PbFieldType to FieldDescriptorProto_Type.
class FieldTypeMapper {
  /// Converts PbFieldType to FieldDescriptorProto_Type.
  ///
  /// For packed fields, extracts the base type by removing the packed bit.
  /// Maps standard protobuf field types to their descriptor equivalents.
  static FieldDescriptorProto_Type convertPbFieldTypeToDescriptorType(
      int pbFieldType) {
    // For packed fields, we need to extract the base type by removing the packed bit
    final baseType = pbFieldType & ~0x4; // Remove PACKED_BIT (0x4)

    // Map PbFieldType to FieldDescriptorProto_Type
    if (baseType == PbFieldType.OB ||
        baseType == PbFieldType.PB ||
        baseType == PbFieldType.QB) {
      return FieldDescriptorProto_Type.TYPE_BOOL;
    } else if (baseType == PbFieldType.O3 ||
        baseType == PbFieldType.P3 ||
        baseType == PbFieldType.Q3) {
      return FieldDescriptorProto_Type.TYPE_INT32;
    } else if (baseType == PbFieldType.O6 ||
        baseType == PbFieldType.P6 ||
        baseType == PbFieldType.Q6) {
      return FieldDescriptorProto_Type.TYPE_INT64;
    } else if (baseType == PbFieldType.OU3 ||
        baseType == PbFieldType.PU3 ||
        baseType == PbFieldType.QU3) {
      return FieldDescriptorProto_Type.TYPE_UINT32;
    } else if (baseType == PbFieldType.OU6 ||
        baseType == PbFieldType.PU6 ||
        baseType == PbFieldType.QU6) {
      return FieldDescriptorProto_Type.TYPE_UINT64;
    } else if (baseType == PbFieldType.OS3 ||
        baseType == PbFieldType.PS3 ||
        baseType == PbFieldType.QS3) {
      return FieldDescriptorProto_Type.TYPE_SINT32;
    } else if (baseType == PbFieldType.OS6 ||
        baseType == PbFieldType.PS6 ||
        baseType == PbFieldType.QS6) {
      return FieldDescriptorProto_Type.TYPE_SINT64;
    } else if (baseType == PbFieldType.OSF3 ||
        baseType == PbFieldType.PSF3 ||
        baseType == PbFieldType.QSF3) {
      return FieldDescriptorProto_Type.TYPE_SFIXED32;
    } else if (baseType == PbFieldType.OSF6 ||
        baseType == PbFieldType.PSF6 ||
        baseType == PbFieldType.QSF6) {
      return FieldDescriptorProto_Type.TYPE_SFIXED64;
    } else if (baseType == PbFieldType.OF3 ||
        baseType == PbFieldType.PF3 ||
        baseType == PbFieldType.QF3) {
      return FieldDescriptorProto_Type.TYPE_FIXED32;
    } else if (baseType == PbFieldType.OF6 ||
        baseType == PbFieldType.PF6 ||
        baseType == PbFieldType.QF6) {
      return FieldDescriptorProto_Type.TYPE_FIXED64;
    } else if (baseType == PbFieldType.OF ||
        baseType == PbFieldType.PF ||
        baseType == PbFieldType.QF) {
      return FieldDescriptorProto_Type.TYPE_FLOAT;
    } else if (baseType == PbFieldType.OD ||
        baseType == PbFieldType.PD ||
        baseType == PbFieldType.QD) {
      return FieldDescriptorProto_Type.TYPE_DOUBLE;
    } else if (baseType == PbFieldType.OS ||
        baseType == PbFieldType.PS ||
        baseType == PbFieldType.QS) {
      return FieldDescriptorProto_Type.TYPE_STRING;
    } else if (baseType == PbFieldType.OY ||
        baseType == PbFieldType.PY ||
        baseType == PbFieldType.QY) {
      return FieldDescriptorProto_Type.TYPE_BYTES;
    } else if (baseType == PbFieldType.OE ||
        baseType == PbFieldType.PE ||
        baseType == PbFieldType.QE) {
      return FieldDescriptorProto_Type.TYPE_ENUM;
    } else if (baseType == PbFieldType.OM ||
        baseType == PbFieldType.PM ||
        baseType == PbFieldType.QM) {
      return FieldDescriptorProto_Type.TYPE_MESSAGE;
    } else {
      // Default fallback
      return FieldDescriptorProto_Type.TYPE_STRING;
    }
  }
}
