import '../models/models.dart';

class SchemaArray extends Schema {
  SchemaArray({
    required super.id,
    required this.itemsBaseSchema,
    String? title,
    super.description,
    this.arrayProperties = const ArrayProperties(),
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
      description: json['description'],
      arrayProperties: ArrayProperties.fromJson(json),
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
      description: description,
      arrayProperties: arrayProperties,
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

  final ArrayProperties arrayProperties;

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

enum ArrayPropertiesError {
  minItems,
  maxItems,
  uniqueItems,
  // contains, prefixItems
}

class ArrayProperties {
  final int? minItems;
  final int? maxItems;
  final bool? uniqueItems;

  const ArrayProperties({
    this.minItems,
    this.maxItems,
    this.uniqueItems,
  });

  factory ArrayProperties.fromJson(Map<String, dynamic> json) {
    return ArrayProperties(
      minItems: json['minItems'],
      maxItems: json['maxItems'],
      uniqueItems: json['uniqueItems'],
    );
  }

  List<ArrayPropertiesError> errors(List<dynamic> value) {
    final errors = <ArrayPropertiesError>[];
    if (minItems != null && value.length < minItems!)
      errors.add(ArrayPropertiesError.minItems);
    if (maxItems != null && value.length > maxItems!)
      errors.add(ArrayPropertiesError.maxItems);
    if (uniqueItems != null && value.toSet().length != value.length)
      errors.add(ArrayPropertiesError.uniqueItems);
    return errors;
  }
}
