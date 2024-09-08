import '../models/models.dart';

class SchemaObject extends Schema {
  SchemaObject({
    required super.id,
    required super.defs,
    required super.oneOf,
    this.required = const [],
    required this.dependentRequired,
    required this.dependentSchemas,
    super.title,
    super.description,
    required super.nullable,
    super.requiredProperty,
    super.parent,
    super.dependentsAddedBy,
  }) : super(type: SchemaType.object);

  factory SchemaObject.fromJson(
    String id,
    Map<String, dynamic> json, {
    Schema? parent,
  }) {
    final dependentSchemas = <String, Schema>{};
    final dependentRequired = <String, List<String>>{};
    final schema = SchemaObject(
      id: id,
      title: json['title'],
      description: json['description'],
      required:
          json["required"] != null ? List<String>.from(json["required"]) : [],
      nullable: SchemaType.isNullable(json['type']),
      dependentRequired: dependentRequired,
      dependentSchemas: dependentSchemas,
      oneOf: json['oneOf'],
      defs: ((json['\$defs'] ?? json['definitions']) as Map?)?.cast(),
      parent: parent,
    );
    schema.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? const []);

    (json['dependencies'] as Map<String, dynamic>?)?.forEach((key, value) {
      if (value is List) {
        dependentRequired[key] = value.cast();
      } else {
        dependentSchemas[key] = Schema.fromJson(value, parent: schema);
      }
    });
    (json['dependentSchemas'] as Map<String, dynamic>?)?.forEach((key, value) {
      dependentSchemas[key] =
          Schema.fromJson(value as Map<String, dynamic>, parent: schema);
    });
    (json['dependentRequired'] as Map<String, dynamic>?)?.forEach((key, value) {
      dependentRequired[key] = (value as List).cast();
    });

    if (json['properties'] != null) {
      schema._setProperties(json['properties']);
    }

    return schema;
  }

  @override
  Schema copyWith({
    required String id,
    Schema? parent,
    List<String>? dependentsAddedBy,
  }) {
    final newSchema = SchemaObject(
      id: id,
      defs: defs,
      title: title,
      description: description,
      required: required,
      nullable: nullable,
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
      dependentSchemas: dependentSchemas,
      dependentRequired: dependentRequired,
      oneOf: oneOf,
    );

    newSchema.properties.addAll(
      properties.map(
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

  /// array of required keys
  final List<String> required;
  final List<Schema> properties = [];

  /// the dependencies keyword from an earlier draft of JSON Schema
  /// (note that this is not part of the latest JSON Schema spec, though).
  /// Dependencies can be used to create dynamic schemas that change fields based on what data is entered
  final Map<String, Schema> dependentSchemas;
  final Map<String, List<String>> dependentRequired;

  @override
  void setUiSchema(
    Map<String, dynamic> data, {
    required bool fromOptions,
  }) {
    super.setUiSchema(data, fromOptions: fromOptions);
    // set UI Schema to their properties
    for (var _property in properties) {
      final v = data[_property.id] as Map<String, dynamic>?;
      if (v != null) {
        _property.setUiSchema(v, fromOptions: false);
        uiSchema.children[_property.id] = _property.uiSchema;
      }
    }

    // order logic
    final order = uiSchema.order;
    if (order != null) {
      properties.sort((a, b) {
        return order.indexOf(a.id) - order.indexOf(b.id);
      });
    }
  }

  void _setProperties(Map<String, dynamic> properties) {
    properties.forEach((key, _property) {
      final isRequired = required.contains(key);

      final property = Schema.fromJson(
        _property,
        id: key,
        parent: this,
      );

      property.requiredProperty = isRequired;
      if (property is SchemaProperty) {
        // Asignamos las propiedades que dependen de este
        property.setDependents(this);
      }

      this.properties.add(property);
    });
  }
}
