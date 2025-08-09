import 'package:protobuf/protobuf.dart';

/// Represents a path element in a protobuf message field path.
abstract class PathElement {
  String toFieldPathString();
}

/// A field element in the path.
class FieldElement implements PathElement {
  final FieldInfo field;
  
  FieldElement(this.field);
  
  @override
  String toFieldPathString() => field.name;
}

/// A list index element in the path.
class ListElement implements PathElement {
  final int index;
  
  ListElement(this.index);
  
  @override
  String toFieldPathString() => '[$index]';
}

/// A map key element in the path.
class MapKeyElement implements PathElement {
  final dynamic key;
  
  MapKeyElement(this.key);
  
  @override
  String toFieldPathString() {
    if (key is String) {
      return '["$key"]';
    }
    return '[$key]';
  }
}

/// Represents a field path through a protobuf message structure.
class FieldPath {
  final List<PathElement> _elements;
  
  FieldPath() : _elements = [];
  
  FieldPath._(List<PathElement> elements) : _elements = List.from(elements);
  
  /// Creates a copy of this path.
  FieldPath clone() => FieldPath._(_elements);
  
  /// Adds a field to the path.
  FieldPath field(FieldInfo field) {
    final newPath = clone();
    newPath._elements.add(FieldElement(field));
    return newPath;
  }
  
  /// Adds a list index to the path.
  FieldPath listIndex(int index) {
    final newPath = clone();
    newPath._elements.add(ListElement(index));
    return newPath;
  }
  
  /// Adds a map key to the path.
  FieldPath mapKey(dynamic key) {
    final newPath = clone();
    newPath._elements.add(MapKeyElement(key));
    return newPath;
  }
  
  /// Returns the string representation of this path.
  String toFieldPathString() {
    if (_elements.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (var i = 0; i < _elements.length; i++) {
      final element = _elements[i];
      final str = element.toFieldPathString();
      
      if (i == 0 || str.startsWith('[')) {
        buffer.write(str);
      } else {
        buffer.write('.');
        buffer.write(str);
      }
    }
    return buffer.toString();
  }
  
  @override
  String toString() => toFieldPathString();
}