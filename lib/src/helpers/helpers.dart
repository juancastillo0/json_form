Object? copyJson(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key as String, copyJson(value)));
  } else if (json is List) {
    return json.map(copyJson).toList();
  } else {
    return json;
  }
}

bool jsonEqual(Object? json, Object? other) {
  if (json is Map) {
    return other is Map &&
        other.length == json.length &&
        json.entries.every((e) => jsonEqual(other[e.key], e.value));
  } else if (json is List) {
    return other is List &&
        other.length == json.length &&
        Iterable<int>.generate(json.length)
            .every((i) => jsonEqual(json[i], other[i]));
  } else {
    return json == other;
  }
}

/// Converts a string to title case.
///
/// Examples:
/// userName     -> User Name
/// user.name    -> User Name
/// user/name    -> User Name
/// user  name2  -> User Name 2
/// UserName26   -> User Name 26
/// User1Name26  -> User 1 Name 26
/// User NAME-26 -> User NAME 26
String toTitleCase(String id) {
  final buffer = StringBuffer();
  bool wroteSpace = true;
  bool wroteUppercase = true;
  final separator = RegExp(r'[-_\s/\\\.]');
  final uppercase = RegExp('[A-Z0-9]');
  final lowercase = RegExp('[a-z]');
  for (var i = 0; i < id.length; i++) {
    final char = id[i];
    if (separator.hasMatch(char)) {
      if (!wroteSpace) {
        wroteSpace = true;
        buffer.write(' ');
      }
    } else {
      final isUppercase = uppercase.hasMatch(char);
      if (isUppercase &&
          !wroteSpace &&
          (!wroteUppercase ||
              i < id.length - 1 && lowercase.hasMatch(id[i + 1]))) {
        buffer.write(' ');
      }
      buffer.write(wroteSpace ? char.toUpperCase() : char);
      wroteUppercase = isUppercase;
      wroteSpace = false;
    }
  }
  return buffer.toString();
}
