import '../models/models.dart';

enum PropertyFormat {
  general,
  date,
  dateTime,
  time,
  email,
  idnEmail,
  dataUrl,
  hostname,
  idnHostname,
  uri,
  uriReference,
  iri,
  iriReference,
  uuid,
  ipv4,
  ipv6,
  uriTemplate,
  jsonPointer,
  relativeJsonPointer,
  regex,
}

PropertyFormat propertyFormatFromString(String? value) {
  switch (value) {
    case 'date':
      return PropertyFormat.date;
    case 'date-time':
      return PropertyFormat.dateTime;
    case 'email':
      return PropertyFormat.email;
    case 'data-url':
      return PropertyFormat.dataUrl;
    case 'uri':
      return PropertyFormat.uri;
    case 'uri-reference':
      return PropertyFormat.uriReference;
    case 'iri':
      return PropertyFormat.iri;
    case 'iri-reference':
      return PropertyFormat.iriReference;
    case 'time':
      return PropertyFormat.time;
    case 'idn-email':
      return PropertyFormat.idnEmail;
    case 'hostname':
      return PropertyFormat.hostname;
    case 'idn-hostname':
      return PropertyFormat.idnHostname;
    case 'uuid':
      return PropertyFormat.uuid;
    case 'ipv4':
      return PropertyFormat.ipv4;
    case 'ipv6':
      return PropertyFormat.ipv6;
    case 'uri-template':
      return PropertyFormat.uriTemplate;
    case 'json-pointer':
      return PropertyFormat.jsonPointer;
    case 'relative-json-pointer':
      return PropertyFormat.relativeJsonPointer;
    case 'regex':
      return PropertyFormat.regex;
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
    super.requiredProperty = false,
    required super.nullable,
    this.format = PropertyFormat.general,
    this.numberProperties = const NumberProperties(),
    this.minLength,
    this.maxLength,
    this.pattern,
    this.oneOf,
    super.parent,
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
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      pattern: json['pattern'],
      numberProperties: NumberProperties.fromJson(json),
      oneOf: json['oneOf'],
      parent: parent,
      nullable: SchemaType.isNullable(json['type']),
    );
    property.dependentsAddedBy.addAll(parent?.dependentsAddedBy ?? const []);

    return property;
  }

  @override
  SchemaProperty copyWith({
    required String id,
    Schema? parent,
    List<String>? dependentsAddedBy,
  }) {
    final newSchema = SchemaProperty(
      id: id,
      title: title,
      type: type,
      description: description,
      format: format,
      defaultValue: defaultValue,
      enumm: enumm,
      requiredProperty: requiredProperty,
      nullable: nullable,
      oneOf: oneOf,
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
    )
      ..maxLength = maxLength
      ..minLength = minLength
      ..dependents = dependents
      ..isMultipleFile = isMultipleFile;
    newSchema.setUiSchema(uiSchema.toJson(), fromOptions: false);

    return newSchema;
  }

  PropertyFormat format;

  /// it means enum
  List<dynamic>? enumm;

  dynamic defaultValue;
  List<dynamic>? examples;

  // propiedades que se llenan con el json
  int? minLength;
  int? maxLength;
  final NumberProperties numberProperties;
  String? pattern;
  dynamic dependents;
  bool isMultipleFile = false;

  /// indica si sus dependentes han sido activados por XDependencies
  bool isDependentsActive = false;

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
