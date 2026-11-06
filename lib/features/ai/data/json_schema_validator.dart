/// A small, dependency-free JSON Schema validator covering the subset used by
/// DARAM's tool schemas.
///
/// Invalid arguments are never executed; they are returned to the model as a
/// structured tool error so it can ask the user a clarifying question.
class JsonSchemaValidator {
  const JsonSchemaValidator();

  /// Returns a list of human-readable validation errors (`path: message`).
  List<String> validate(Map<String, Object?> schema, Object? data) {
    final errors = <String>[];
    _validate(schema, data, r'$', errors);
    return errors;
  }

  void _validate(
    Map<String, Object?> schema,
    Object? data,
    String path,
    List<String> errors,
  ) {
    final type = schema['type'] as String?;
    if (type != null && !_matchesType(type, data)) {
      errors.add('$path: expected $type');
      return;
    }
    if (data == null) return;

    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.contains(data)) {
      errors.add('$path: must be one of ${enumValues.join(', ')}');
    }

    if (data is String) {
      final minLength = schema['minLength'];
      final maxLength = schema['maxLength'];
      if (minLength is int && data.length < minLength) {
        errors.add('$path: shorter than $minLength characters');
      }
      if (maxLength is int && data.length > maxLength) {
        errors.add('$path: longer than $maxLength characters');
      }
      final pattern = schema['pattern'];
      if (pattern is String) {
        try {
          if (!RegExp(pattern).hasMatch(data)) {
            errors.add('$path: invalid format');
          }
        } on FormatException {
          // A broken schema pattern must not crash validation.
        }
      }
    }

    if (data is num) {
      final minimum = schema['minimum'];
      final maximum = schema['maximum'];
      if (minimum is num && data < minimum) {
        errors.add('$path: must be >= $minimum');
      }
      if (maximum is num && data > maximum) {
        errors.add('$path: must be <= $maximum');
      }
    }

    if (data is List) {
      final minItems = schema['minItems'];
      final maxItems = schema['maxItems'];
      if (minItems is int && data.length < minItems) {
        errors.add('$path: needs at least $minItems items');
      }
      if (maxItems is int && data.length > maxItems) {
        errors.add('$path: needs at most $maxItems items');
      }
      final items = schema['items'];
      if (items is Map<String, Object?>) {
        for (var i = 0; i < data.length; i++) {
          _validate(items, data[i], '$path[$i]', errors);
        }
      }
    }

    if (data is Map) {
      final required = schema['required'];
      if (required is List) {
        for (final key in required) {
          if (!data.containsKey(key) || data[key] == null) {
            errors.add('$path.$key: required');
          }
        }
      }
      final properties = schema['properties'];
      final defined = <String>{};
      if (properties is Map) {
        for (final entry in properties.entries) {
          defined.add('${entry.key}');
          if (data.containsKey(entry.key) && data[entry.key] != null) {
            final child = entry.value;
            if (child is Map<String, Object?>) {
              _validate(child, data[entry.key], '$path.${entry.key}', errors);
            }
          }
        }
      }
      final additional = schema['additionalProperties'];
      if (additional == false) {
        for (final key in data.keys) {
          if (!defined.contains('$key')) {
            errors.add('$path.$key: unexpected property');
          }
        }
      } else if (additional is Map<String, Object?>) {
        for (final entry in data.entries) {
          if (!defined.contains('${entry.key}')) {
            _validate(additional, entry.value, '$path.${entry.key}', errors);
          }
        }
      }
    }
  }

  bool _matchesType(String type, Object? data) {
    return switch (type) {
      'object' => data is Map,
      'array' => data is List,
      'string' => data is String,
      'number' => data is num,
      'integer' =>
        data is int || (data is double && data == data.roundToDouble()),
      'boolean' => data is bool,
      'null' => data == null,
      _ => true,
    };
  }
}
