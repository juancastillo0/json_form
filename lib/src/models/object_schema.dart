import 'dart:developer';

import '../models/models.dart';

class SchemaObject extends Schema {
  SchemaObject({
    required super.id,
    this.required = const [],
    this.dependencies,
    String? title,
    super.description,
    required super.nullable,
    super.requiredProperty,
    super.parent,
    super.dependentsAddedBy,
  }) : super(title: title ?? kNoTitle, type: SchemaType.object);

  factory SchemaObject.fromJson(
    String id,
    Map<String, dynamic> json, {
    Schema? parent,
  }) {
    final schema = SchemaObject(
      id: id,
      title: json['title'],
      description: json['description'],
      required:
          json["required"] != null ? List<String>.from(json["required"]) : [],
      nullable: SchemaType.isNullable(json['type']),
      dependencies: json['dependencies'],
      parent: parent,
    );
    schema.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? []);

    if (json['properties'] != null) {
      schema._setProperties(json['properties']);
    }
    if (json['oneOf'] != null) {
      schema._setOneOf(json['oneOf']);
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
      title: title,
      description: description,
      required: required,
      nullable: nullable,
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
      dependencies: dependencies,
    )..oneOf = oneOf;

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

  // ! Getters
  bool get isGenesis => id == kGenesisIdKey;

  bool isOneOf = false;

  /// array of required keys
  final List<String> required;
  final List<Schema> properties = [];

  /// the dependencies keyword from an earlier draft of JSON Schema
  /// (note that this is not part of the latest JSON Schema spec, though).
  /// Dependencies can be used to create dynamic schemas that change fields based on what data is entered
  final Map<String, dynamic>? dependencies;

  /// A [Schema] with [oneOf] is valid if exactly one of the subschemas is valid.
  List<Schema>? oneOf;

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

      if (property is SchemaProperty) {
        property.requiredProperty = isRequired;
        // Asignamos las propiedades que dependen de este
        property.setDependents(this);
      } else {
        property.requiredProperty = isRequired;
      }

      this.properties.add(property);
    });
  }

  void _setOneOf(List<dynamic> oneOf) {
    final oneOfs = <Schema>[];
    for (Map<String, dynamic> element in oneOf.cast()) {
      log(element.toString());
      oneOfs.add(Schema.fromJson(element, parent: this));
    }

    this.oneOf = oneOfs;
  }
}
