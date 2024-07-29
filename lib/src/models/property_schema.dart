import 'dart:developer';

import '../models/models.dart';

enum PropertyFormat { general, password, date, datetime, email, dataurl, uri }

PropertyFormat propertyFormatFromString(String? value) {
  switch (value) {
    case 'password':
      return PropertyFormat.password;
    case 'date':
      return PropertyFormat.date;
    case 'datetime':
      return PropertyFormat.datetime;
    case 'email':
      return PropertyFormat.email;
    case 'data-url':
      return PropertyFormat.dataurl;
    case 'uri':
      return PropertyFormat.uri;
    default:
      return PropertyFormat.general;
  }
}

dynamic safeDefaultValue(Map<String, dynamic> json) {
  final value = json['default'];
  final type = SchemaType.fromJson(json['type']);
  if (type == SchemaType.boolean) {
    if (value is String) return value == 'true';
    if (value is int) return value == 1;
  } else if (type == SchemaType.number) {
    if (value is String) return double.tryParse(value);
    if (value is int) return value.toDouble();
  } else if (type == SchemaType.integer) {
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
  }

  return value;
}

class SchemaProperty extends Schema {
  SchemaProperty({
    required super.id,
    required super.type,
    String? title,
    super.description,
    this.defaultValue,
    this.examples,
    this.enumm,
    this.enumNames,
    super.requiredProperty = false,
    required super.nullable,
    this.format = PropertyFormat.general,
    this.numberProperties = const NumberProperties(),
    this.minLength,
    this.maxLength,
    this.pattern,
    this.oneOf,
    this.readOnly = false,
    super.parentIdKey,
    super.dependentsAddedBy,
  }) : super(
          title: title ?? kNoTitle,
        );

  factory SchemaProperty.fromJson(
    String id,
    Map<String, dynamic> json, {
    Schema? parent,
  }) {
    final property = SchemaProperty(
      id: id,
      title: json['title'],
      type: SchemaType.fromJson(json['type']),
      format: propertyFormatFromString(json['format']),
      defaultValue: safeDefaultValue(json),
      examples: json['examples'],
      description: json['description'],
      enumm: json['enum'],
      enumNames: (json['enumNames'] as List?)?.cast(),
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      pattern: json['pattern'],
      numberProperties: NumberProperties.fromJson(json),
      oneOf: json['oneOf'],
      readOnly: json['readOnly'] ?? false,
      parentIdKey: parent?.idKey,
      nullable: SchemaType.isNullable(json['type']),
    );
    property.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? const []);

    return property;
  }

  void setUi(Map<String, dynamic> uiSchema) {
    // set general ui schema
    setUiToProperty(uiSchema);

    // set custom ui schema for property
    if (uiSchema.containsKey(id)) {
      setUiToProperty(uiSchema[id]);
    }
  }

  @override
  SchemaProperty copyWith({
    required String id,
    String? parentIdKey,
    List<String>? dependentsAddedBy,
  }) {
    final newSchema = SchemaProperty(
      id: id,
      title: title,
      type: type,
      description: description,
      format: format,
      defaultValue: defaultValue,
      enumNames: enumNames,
      enumm: enumm,
      requiredProperty: requiredProperty,
      nullable: nullable,
      oneOf: oneOf,
      parentIdKey: parentIdKey ?? this.parentIdKey,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    )
      ..autoFocus = autoFocus
      ..order = order
      ..widget = widget
      ..disabled = disabled
      ..emptyValue = emptyValue
      ..help = help
      ..maxLength = maxLength
      ..minLength = minLength
      ..widget = widget
      ..dependents = dependents
      ..isMultipleFile = isMultipleFile;

    return newSchema;
  }

  PropertyFormat format;

  /// it means enum
  List<dynamic>? enumm;

  /// displayed as text if is not empty
  List<String>? enumNames;

  dynamic defaultValue;
  List<dynamic>? examples;

  // propiedades que se llenan con el json
  bool? disabled;
  List<String>? order;
  bool? autoFocus;
  int? minLength, maxLength;
  final NumberProperties numberProperties;
  String? pattern;
  dynamic dependents;
  bool readOnly;
  bool isMultipleFile = false;

  /// indica si sus dependentes han sido activados por XDependencies
  bool isDependentsActive = false;

  // not suported yet
  String? widget, emptyValue, help;
  List<dynamic>? oneOf;

  void setDependents(SchemaObject schema) {
    final dependents = schema.dependencies?[id];
    // Asignamos las propiedades que dependen de este
    if (schema.dependencies != null && dependents != null) {
      if (dependents is Map) {
        schema.isOneOf = dependents.containsKey("oneOf");
      }
      if (dependents is List || schema.isOneOf) {
        this.dependents = dependents;
      } else {
        this.dependents = Schema.fromJson(
          dependents,
          // id: '',
          parent: schema,
        );
      }
    }
  }

  void setUiToProperty(Map<String, dynamic> uiSchema) {
    uiSchema.forEach((key, data) {
      switch (key) {
        case "ui:disabled":
          log('aplicamos pues ctmr');
          disabled = data as bool;
          break;
        case "ui:order":
          order = List<String>.from(data);
          break;
        case "ui:autofocus":
          autoFocus = data as bool;
          break;
        case "ui:emptyValue":
          emptyValue = data as String;
          break;
        case "ui:title":
          title = data as String;
          break;
        case "ui:description":
          description = data as String;
          break;
        case "ui:help":
          help = data as String;
          break;
        case "ui:widget":
          widget = data as String;
          break;
        default:
          break;
      }
    });
  }
}

enum NumberPropertiesError {
  multipleOf,
  minimum,
  exclusiveMinimum,
  maximum,
  exclusiveMaximum,
}

class NumberProperties {
  final num? multipleOf;
  final num? minimum;
  final num? exclusiveMinimum;
  final num? maximum;
  final num? exclusiveMaximum;

  const NumberProperties({
    this.multipleOf,
    this.minimum,
    this.exclusiveMinimum,
    this.maximum,
    this.exclusiveMaximum,
  });

  factory NumberProperties.fromJson(Map<String, dynamic> json) {
    return NumberProperties(
      multipleOf: json['multipleOf'],
      minimum: json['minimum'],
      exclusiveMinimum: json['exclusiveMinimum'],
      maximum: json['maximum'],
      exclusiveMaximum: json['exclusiveMaximum'],
    );
  }

  List<NumberPropertiesError> errors(num value) {
    final errors = <NumberPropertiesError>[];
    if (multipleOf != null && value % multipleOf! != 0)
      errors.add(NumberPropertiesError.multipleOf);
    if (minimum != null && value < minimum!)
      errors.add(NumberPropertiesError.minimum);
    if (exclusiveMinimum != null && value <= exclusiveMinimum!)
      errors.add(NumberPropertiesError.exclusiveMinimum);
    if (maximum != null && value > maximum!)
      errors.add(NumberPropertiesError.maximum);
    if (exclusiveMaximum != null && value >= exclusiveMaximum!)
      errors.add(NumberPropertiesError.exclusiveMaximum);
    return errors;
  }
}
