/// Generic mapper helper for converting between different types
class GenericMapper {
  /// Map a single item using a mapping function
  static T map<T, R>(R source, T Function(R) mapper) {
    return mapper(source);
  }

  /// Map a list of items using a mapping function
  static List<T> mapList<T, R>(List<R> source, T Function(R) mapper) {
    return source.map(mapper).toList();
  }

  /// Map an optional item using a mapping function
  static T? mapOptional<T, R>(R? source, T Function(R) mapper) {
    if (source == null) return null;
    return mapper(source);
  }

  /// Map a list of optional items using a mapping function
  static List<T> mapOptionalList<T, R>(List<R?> source, T Function(R) mapper) {
    return source.whereType<R>().map(mapper).toList();
  }
}

/// Extension methods for easier mapping
extension MapperExtensions<T> on T {
  /// Map this item to another type
  R mapTo<R>(R Function(T) mapper) {
    return GenericMapper.map(this, mapper);
  }
}

extension ListMapperExtensions<T> on List<T> {
  /// Map this list to a list of another type
  List<R> mapTo<R>(R Function(T) mapper) {
    return GenericMapper.mapList(this, mapper);
  }
}

extension OptionalMapperExtensions<T> on T? {
  /// Map this optional item to another optional type
  R? mapToOptional<R>(R Function(T) mapper) {
    return GenericMapper.mapOptional(this, mapper);
  }
} 