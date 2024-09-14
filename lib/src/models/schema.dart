import 'package:flutter/widgets.dart';
import 'package:json_form/src/utils/either.dart';

import '../models/models.dart';

enum SchemaType {
  string,
  number,
  boolean,
  integer,
  object,
  array;

  factory SchemaType.fromJson(Object? json_) {
    String json;
    if (json_ is String) {
      json = json_;
    } else if (json_ is List) {
      if (json_.length > 2 || json_.isEmpty) {
        throw UnimplementedError(
          'Types with more than 2 elements are not implemented',
        );
      } else if (json_.every(_notNull) && json_.length != 1) {
        throw UnimplementedError('Union types are not implemented');
      } else {
        json = json_.firstWhere(
          _notNull,
          orElse: () =>
              throw UnimplementedError('Null types are not implemented'),
        );
      }
    } else {
      throw FormatException(
        'Expected String or List<String> found ${json_.runtimeType} in SchemaType.fromJson',
      );
    }
    return SchemaType.values.byName(json);
  }

  static bool isNullable(Object? json) {
    if (json is String) {
      return !_notNull(json);
    } else if (json is List) {
      return !json.every(_notNull);
    } else {
      throw FormatException(
        'Expected String or List<String> found ${json.runtimeType} in SchemaType.fromJson',
      );
    }
  }

  static bool _notNull(Object? v) => v != 'null' && v != null;
}

abstract class Schema implements SchemaUiInfo {
  Schema({
    required this.id,
    required this.type,
    required this.nullable,
    required this.defs,
    required List<Object?>? oneOf,
    this.requiredProperty = false,
    String? title,
    String? description,
    this.parent,
    List<String>? dependentsAddedBy,
  })  : dependentsAddedBy = dependentsAddedBy ?? [],
        _title = title,
        _description = description,
        oneOf = oneOf is List<Schema> ? oneOf : [] {
    if (oneOf != null && oneOf is! List<Schema>) {
      _setOneOf(oneOf);
    }
  }

  factory Schema.fromJson(
    Map<String, dynamic> json, {
    String id = kNoIdKey,
    Schema? parent,
  }) {
    Schema schema;

    final ref = json['\$ref'] as String?;
    if (ref != null) {
      final result = _resolveRef(ref, parent);
      if (result.isLeft) {
        return result.left!;
      }
      json = result.right!;
    }

    _tryCastType(json);
    json['type'] ??= 'object';

    switch (SchemaType.fromJson(json['type'])) {
      case SchemaType.object:
        schema = SchemaObject.fromJson(id, json, parent: parent);
        break;

      case SchemaType.array:
        schema = SchemaArray.fromJson(id, json, parent: parent);

        // validate if is a file array, it means multiplefile
        if (schema is SchemaArray && schema.isArrayMultipleFile())
          schema = schema.toSchemaPropertyMultipleFiles();
        break;

      default:
        schema = SchemaProperty.fromJson(id, json, parent: parent);
        break;
    }

    final uiSchema = json['ui:options'] as Map<String, dynamic>?;
    if (uiSchema != null) {
      schema.setUiSchema(uiSchema, fromOptions: true);
    }
    return schema;
  }

  // props
  final String id;
  final String? _title;
  final String? _description;
  @override
  String? get title => uiSchema.title ?? _title;
  @override
  String? get description => uiSchema.description ?? _description;
  @override
  final SchemaType type;
  final Map<String, Map<String, Object?>>? defs;
  final List<Schema> oneOf;

  bool requiredProperty;
  final bool nullable;

  bool get requiredNotNull => requiredProperty && !nullable;

  String get titleOrId => title != null ? title! : id;

  // util props
  final Schema? parent;
  final List<String> dependentsAddedBy;

  final UiSchemaData uiSchema = UiSchemaData();

  static String _appendId(String path, String id) {
    return id != kNoIdKey ? (path.isNotEmpty ? '$path.' : '') + id : path;
  }

  Schema copyWith({
    required String id,
    Schema? parent,
    List<String>? dependentsAddedBy,
  });

  @mustCallSuper
  void setUiSchema(
    Map<String, dynamic> data, {
    required bool fromOptions,
  }) {
    uiSchema.setUi(data, parent: parent?.uiSchema, fromOptions: fromOptions);
  }

  void _setOneOf(List<dynamic> oneOf) {
    for (Map<String, dynamic> element in oneOf.cast()) {
      this.oneOf.add(Schema.fromJson(element, parent: this));
    }
  }

  static void _tryCastType(Map<String, Object?> json) {
    var enumm = json['enum'] as List?;
    final constValue = json['const'];
    if (enumm == null && constValue != null) {
      enumm = [constValue];
      json['enum'] = enumm;
    }
    if (json['type'] == null && enumm != null) {
      if (enumm.every((e) => e is String)) {
        json['type'] = SchemaType.string.name;
      } else if (enumm.every((e) => e is int)) {
        json['type'] = SchemaType.integer.name;
      } else if (enumm.every((e) => e is num)) {
        json['type'] = SchemaType.number.name;
      } else if (enumm.every((e) => e is bool)) {
        json['type'] = SchemaType.boolean.name;
      }
    }
  }
}

Either<Schema, Map<String, Object?>> _resolveRef(String ref, Schema? parent) {
  if (parent == null) {
    throw ArgumentError('Reference "$ref" not supported without parent');
  }
  Schema root = parent;
  while (root.parent != null) {
    root = root.parent!;
  }
  if (!ref.startsWith('#')) {
    throw ArgumentError('Reference "$ref" not supported');
  } else if (ref == '#') {
    return Either.left(root);
  } else if (!ref.startsWith('#/definitions/') &&
      !ref.startsWith('#/\$defs/')) {
    throw ArgumentError(
      'Relative reference "$ref" outside of "defs" is not supported',
    );
  }

  final refKey = ref.split('/').last;
  final j = root.defs?[refKey];
  if (j == null) {
    throw ArgumentError('Reference "$ref" not found in definitions');
  }
  return Either.right(j);
}

abstract class SchemaUiInfo {
  /// User facing title
  String? get title;

  /// User facing description
  String? get description;

  /// The kind of the JSON Schema
  SchemaType get type;
}

/// A field that can be used to retrieve and update a
/// JSON Schema property in a form
abstract class JsonFormField<T> {
  /// It lets us know the key in the form's data Map
  String get idKey;

  /// Basic schema information of the field
  SchemaUiInfo get property;

  /// The current value of the field input
  T get value;

  /// Updates the value of the field input
  set value(T value);

  /// The focus node of the input.
  /// You may use this to retrieve and change the focus status.
  FocusNode get focusNode;
}
