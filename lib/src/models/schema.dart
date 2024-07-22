import '../models/models.dart';
// Esto transforma el JSON a Modelos

enum SchemaType {
  string,
  number,
  boolean,
  integer,
  object,
  array,
  enumm;

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

abstract class Schema {
  Schema({
    required this.id,
    required this.type,
    required this.nullable,
    this.requiredProperty = false,
    String? title,
    this.description,
    this.parentIdKey,
    List<String>? dependentsAddedBy,
  })  : dependentsAddedBy = dependentsAddedBy ?? [],
        title = title ?? kNoTitle;

  factory Schema.fromJson(
    Map<String, dynamic> json, {
    String id = kNoIdKey,
    Schema? parent,
  }) {
    Schema schema;

// Solucion temporal y personalizada
    final enumm = json['enum'];
    if (enumm is List<String> && enumm.length == 1) {
      return SchemaEnum(enumm: enumm, nullable: false);
    }

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

    return schema;
  }

  // props
  final String id;
  String title;
  String? description;
  final SchemaType type;

  bool requiredProperty;
  final bool nullable;

  bool get requiredNotNull => requiredProperty && !nullable;

  String get titleOrId => title != kNoTitle ? title : id;

  // util props
  final String? parentIdKey;
  final List<String> dependentsAddedBy;

  /// it lets us know the key in the formData Map {key}
  String get idKey {
    if (parentIdKey != null && parentIdKey != kGenesisIdKey) {
      return _appendId(parentIdKey!, id);
    }

    return id;
  }

  String _appendId(String path, String id) {
    return id != kNoIdKey ? (path.isNotEmpty ? '$path.' : '') + id : path;
  }

  Schema copyWith({
    required String id,
    String? parentIdKey,
    List<String>? dependentsAddedBy,
  });
}

// Solucion temporal y personalizada
class SchemaEnum extends Schema {
  SchemaEnum({
    String? id,
    required this.enumm,
    required super.nullable,
    super.parentIdKey,
    super.dependentsAddedBy,
  }) : super(
          id: id ?? kNoIdKey,
          title: kNoTitle,
          type: SchemaType.enumm,
        );

  final List<String> enumm;

  @override
  Schema copyWith({
    required String id,
    String? parentIdKey,
    List<String>? dependentsAddedBy,
  }) {
    return SchemaEnum(
      id: id,
      enumm: enumm,
      nullable: nullable,
      parentIdKey: parentIdKey ?? this.parentIdKey,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    );
  }
}
