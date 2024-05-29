import '../models/models.dart';
// Esto transforma el JSON a Modelos

enum SchemaType { string, number, boolean, integer, object, array, enumm }

class Schema {
  Schema({
    required this.id,
    required this.type,
    this.title = kNoTitle,
    this.description,
    this.parentIdKey,
    List<String>? dependentsAddedBy,
  }) : dependentsAddedBy = dependentsAddedBy ?? [];

  factory Schema.fromJson(
    Map<String, dynamic> json, {
    String id = kNoIdKey,
    Schema? parent,
  }) {
    Schema schema;

// Solucion temporal y personalizada
    final enumm = json['enum'];
    if (enumm is List<String> && enumm.length == 1) {
      return SchemaEnum(enumm: enumm);
    }

    json['type'] ??= 'object';

    switch (SchemaType.values.byName(json['type'])) {
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
  }) {
    return Schema(
      id: id,
      type: type,
      title: title,
      description: description,
      parentIdKey: parentIdKey ?? this.parentIdKey,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    );
  }
}

// Solucion temporal y personalizada
class SchemaEnum extends Schema {
  SchemaEnum({required this.enumm})
      : super(
          id: kNoIdKey,
          title: kNoTitle,
          type: SchemaType.enumm,
        );

  final List<String> enumm;
}
