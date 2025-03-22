import 'package:json_form/src/models/models.dart';

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
  regex;

  static PropertyFormat fromString(String? value) {
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
}

dynamic _safeDefaultValue(Map<String, dynamic> json) {
  final value = json['default'];
  final type = JsonSchemaType.fromJson(json['type']);
  if (type == JsonSchemaType.boolean) {
    if (value is String) return value == 'true';
    if (value is int) return value == 1;
  } else if (type == JsonSchemaType.number) {
    if (value is String) return double.tryParse(value);
    if (value is int) return value.toDouble();
  } else if (type == JsonSchemaType.integer) {
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
  }

  return value;
}

class SchemaProperty extends Schema {
  SchemaProperty({
    required super.id,
    required super.type,
    required super.oneOf,
    super.title,
    super.description,
    this.defaultValue,
    this.enumm,
    super.requiredProperty = false,
    required super.nullable,
    this.format = PropertyFormat.general,
    this.numberProperties = const NumberProperties(),
    this.minLength,
    this.maxLength,
    this.pattern,
    this.isMultipleFile = false,
    super.parent,
    super.dependentsAddedBy,
  }) : super(
          defs: null,
        );

  factory SchemaProperty.fromJson(
    String id,
    Map<String, dynamic> json, {
    Schema? parent,
  }) {
    final property = SchemaProperty(
      id: id,
      title: json['title'] as String?,
      type: JsonSchemaType.fromJson(json['type']),
      format: PropertyFormat.fromString(json['format'] as String?),
      defaultValue: _safeDefaultValue(json),
      description: json['description'] as String?,
      enumm: json['enum'] as List?,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      numberProperties: NumberProperties.fromJson(json),
      oneOf: json['oneOf'] as List?,
      parent: parent,
      nullable: JsonSchemaType.isNullable(json['type']),
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
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      requiredProperty: requiredProperty,
      nullable: nullable,
      oneOf: oneOf,
      parent: parent ?? this.parent,
      dependentsAddedBy: dependentsAddedBy ?? this.dependentsAddedBy,
      isMultipleFile: isMultipleFile,
    )..dependents = dependents;
    newSchema.setUiSchema(uiSchema.toJson(), fromOptions: false);

    return newSchema;
  }

  final PropertyFormat format;

  /// "enum" property in JSON Schema. The possible values that can be selected
  final List<dynamic>? enumm;
  dynamic get constValue =>
      enumm != null && enumm!.length == 1 ? enumm!.first : null;
  final dynamic defaultValue;

  // Validation properties
  final int? minLength;
  final int? maxLength;
  final NumberProperties numberProperties;
  final String? pattern;
  final bool isMultipleFile;
  PropertyDependents? dependents;

  void setDependents(SchemaObject schema) {
    if (schema.dependentRequired.containsKey(id) ||
        schema.dependentSchemas.containsKey(id)) {
      // if (dependents is Map) {
      // TODO:  schema.isOneOf = dependents.containsKey("oneOf");
      dependents = PropertyDependents(
        requiredProps: schema.dependentRequired[id],
        schema: schema.dependentSchemas[id],
      );
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
      multipleOf: json['multipleOf'] as num?,
      minimum: json['minimum'] as num?,
      exclusiveMinimum: json['exclusiveMinimum'] as num?,
      maximum: json['maximum'] as num?,
      exclusiveMaximum: json['exclusiveMaximum'] as num?,
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

  /// Returns the list of options that can be selected
  /// for the [minimum], [maximum] and [multipleOf] properties
  List<num> options() {
    final mi = (minimum != null ? minimum! : exclusiveMinimum! + 1);
    final ma = (maximum != null ? maximum! : exclusiveMaximum! - 1);
    final mof = multipleOf;
    if (mof == null) {
      return List.generate((ma - mi).toInt() + 1, (i) => mi + i);
    }
    final mi2 = mi % mof == 0 ? mi : mi + mof - mi % mof;
    final ma2 = ma % mof == 0 ? ma : ma - ma % mof;
    final range = (ma2 - mi2) ~/ mof;
    return List.generate(range + 1, (i) => mi2 + i * mof);
  }
}

class PropertyDependents {
  final List<String>? requiredProps;
  final Schema? schema;

  const PropertyDependents({
    required this.requiredProps,
    required this.schema,
  });
}
