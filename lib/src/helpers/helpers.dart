Object? copyJson(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key, copyJson(value)));
  } else if (json is List) {
    return json.map((e) => copyJson(e)).toList();
  } else {
    return json;
  }
}
