import '../models/models.dart';

// extension SchemaArrayX on SchemaArray {
//   bool get isMultipleFile {
//     return items.isNotEmpty &&
//         items.first is SchemaProperty &&
//         (items.first as SchemaProperty).format == PropertyFormat.dataurl;
//   }
// }

class SchemaArray extends Schema {
  SchemaArray({
    required super.id,
    required this.itemsBaseSchema,
    String? title,
    this.minItems,
    this.maxItems,
    this.uniqueItems = true,
    List<Schema>? items,
    super.requiredProperty,
    required super.nullable,
    super.parentIdKey,
    super.dependentsAddedBy,
  })  : items = items ?? [],
        super(title: title ?? kNoTitle, type: SchemaType.array);

  factory SchemaArray.fromJson(
    String id,
    Map<String, dynamic> json, {
    Schema? parent,
  }) {
    final schemaArray = SchemaArray(
      id: id,
      title: json['title'],
      minItems: json['minItems'],
      maxItems: json['maxItems'],
      uniqueItems: json['uniqueItems'] ?? true,
      itemsBaseSchema: json['items'],
      parentIdKey: parent?.idKey,
      nullable: SchemaType.isNullable(json['type']),
    );
    schemaArray.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? const []);

    return schemaArray;
  }

  @override
  SchemaArray copyWith({
    required String id,
    String? parentIdKey,
    List<String>? dependentsAddedBy,
  }) {
    final newSchema = SchemaArray(
      id: id,
      title: title,
      maxItems: maxItems,
      minItems: minItems,
      uniqueItems: uniqueItems,
      itemsBaseSchema: itemsBaseSchema,
      requiredProperty: requiredProperty,
      nullable: nullable,
      parentIdKey: parentIdKey ?? this.parentIdKey,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    );
    newSchema.items.addAll(
      items.map(
        (e) => e.copyWith(
          id: e.id,
          parentIdKey: newSchema.idKey,
          dependentsAddedBy: newSchema.dependentsAddedBy,
        ),
      ),
    );

    return newSchema;
  }

  /// can be array of [Schema] or [Schema]
  final List<Schema> items;

  // it allow us
  final dynamic itemsBaseSchema;

  int? minItems;
  int? maxItems;
  bool uniqueItems;

  bool isArrayMultipleFile() {
    return itemsBaseSchema is Map &&
        (itemsBaseSchema as Map)['format'] == 'data-url';
  }

  SchemaProperty toSchemaPropertyMultipleFiles() {
    return SchemaProperty(
      id: id,
      title: title,
      type: SchemaType.string,
      format: PropertyFormat.dataurl,
      requiredProperty: requiredProperty,
      nullable: nullable,
      description: description,
      parentIdKey: parentIdKey,
      dependentsAddedBy: dependentsAddedBy,
    )..isMultipleFile = true;
  }
}
