import '../models/models.dart';

class SchemaArray extends Schema {
  SchemaArray({
    required super.id,
    required dynamic itemsBaseSchema,
    String? title,
    super.description,
    this.arrayProperties = const ArrayProperties(),
    List<Schema>? items,
    super.requiredProperty,
    required super.nullable,
    super.parent,
    super.dependentsAddedBy,
  })  : items = items ?? [],
        super(title: title ?? kNoTitle, type: SchemaType.array) {
    this.itemsBaseSchema = itemsBaseSchema is Schema
        ? itemsBaseSchema.copyWith(id: kNoIdKey, parent: this)
        : Schema.fromJson(itemsBaseSchema, parent: this);
  }

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
      parent: parent,
      nullable: SchemaType.isNullable(json['type']),
    );
    schemaArray.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? const []);

    return schemaArray;
  }

  @override
  SchemaArray copyWith({
    required String id,
    Schema? parent,
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
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    );
    newSchema.items.addAll(
      items.map(
        (e) => e.copyWith(
          id: e.id,
          parent: newSchema,
          dependentsAddedBy: newSchema.dependentsAddedBy,
        ),
      ),
    );
    newSchema.setUiSchema(uiSchema.toJson(), fromOptions: false);

    return newSchema;
  }

  /// can be array of [Schema] or [Schema]
  final List<Schema> items;

  // it allow us
  late final Schema itemsBaseSchema;

  final ArrayProperties arrayProperties;

  bool isArrayMultipleFile() {
    final s = itemsBaseSchema;
    return s is SchemaProperty && s.format == PropertyFormat.dataUrl;
  }

  SchemaProperty toSchemaPropertyMultipleFiles() {
    return SchemaProperty(
      id: id,
      title: title,
      type: SchemaType.string,
      format: PropertyFormat.dataUrl,
      requiredProperty: requiredProperty,
      nullable: nullable,
      description: description,
      parent: parent,
      dependentsAddedBy: dependentsAddedBy,
    )..isMultipleFile = true;
  }

  @override
  void setUiSchema(
    Map<String, dynamic> data, {
    required bool fromOptions,
  }) {
    super.setUiSchema(data, fromOptions: fromOptions);
    final items = data['items'] as Map<String, Object?>?;
    if (items != null) {
      itemsBaseSchema.setUiSchema(items, fromOptions: false);
      uiSchema.children['items'] = itemsBaseSchema.uiSchema;
    }
  }
}

enum ArrayPropertiesError {
  minItems,
  maxItems,
  uniqueItems,
  // TODO: contains, prefixItems
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
