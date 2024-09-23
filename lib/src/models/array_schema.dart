import 'package:json_form/src/models/models.dart';

class SchemaArray extends Schema {
  SchemaArray({
    required super.id,
    required super.defs,
    required super.oneOf,
    required Object? itemsBaseSchema,
    super.title,
    super.description,
    this.arrayProperties = const ArrayProperties(),
    super.requiredProperty,
    required super.nullable,
    super.parent,
    super.dependentsAddedBy,
  }) : super(type: JsonSchemaType.array) {
    this.itemsBaseSchema = itemsBaseSchema is Schema
        ? itemsBaseSchema.copyWith(id: kNoIdKey, parent: this)
        : Schema.fromJson(
            itemsBaseSchema! as Map<String, Object?>,
            parent: this,
          );
  }

  factory SchemaArray.fromJson(
    String id,
    Map<String, Object?> json, {
    Schema? parent,
  }) {
    final schemaArray = SchemaArray(
      id: id,
      oneOf: json['oneOf'] as List?,
      defs: ((json['\$defs'] ?? json['definitions']) as Map?)?.cast(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      arrayProperties: ArrayProperties.fromJson(json),
      itemsBaseSchema: json['items'],
      parent: parent,
      nullable: JsonSchemaType.isNullable(json['type']),
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
      defs: defs,
      title: title,
      description: description,
      arrayProperties: arrayProperties,
      itemsBaseSchema: itemsBaseSchema,
      requiredProperty: requiredProperty,
      nullable: nullable,
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
      oneOf: oneOf,
    );
    newSchema.setUiSchema(uiSchema.toJson(), fromOptions: false);

    return newSchema;
  }

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
      type: JsonSchemaType.string,
      format: PropertyFormat.dataUrl,
      requiredProperty: requiredProperty,
      nullable: nullable,
      description: description,
      parent: parent,
      dependentsAddedBy: dependentsAddedBy,
      isMultipleFile: true,
      oneOf: oneOf,
    );
  }

  @override
  void setUiSchema(
    Map<String, Object?> data, {
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

  factory ArrayProperties.fromJson(Map<String, Object?> json) {
    return ArrayProperties(
      minItems: json['minItems'] as int?,
      maxItems: json['maxItems'] as int?,
      uniqueItems: json['uniqueItems'] as bool?,
    );
  }

  List<ArrayPropertiesError> errors(List<Object?> value) {
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
