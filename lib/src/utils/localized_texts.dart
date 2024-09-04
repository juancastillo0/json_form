import 'package:json_form/src/models/array_schema.dart';
import 'package:json_form/src/models/property_schema.dart';
import 'package:json_form/src/utils/input_validation_json_schema.dart';

class LocalizedTexts {
  const LocalizedTexts();

  String required() => 'Required';
  String minLength({required int minLength}) =>
      'Should be at least $minLength characters';
  String maxLength({required int maxLength}) =>
      'Should be less than $maxLength characters';
  String noMatchForPattern({required String pattern}) =>
      'No match for $pattern';
  String select() => 'Select';
  String removeItem() => 'Remove item';
  String addItem() => 'Add item';
  String copyItem() => 'Copy';
  String addFile() => 'Add file';
  String shouldBeUri() => 'Should be a valid URL';
  String submit() => 'Submit';

  String? numberPropertiesError(
    NumberProperties config,
    num value,
  ) {
    final errors = config.errors(value);
    final l = <String>[];
    if (errors.contains(NumberPropertiesError.multipleOf))
      l.add('The value must be a multiple of ${config.multipleOf}');
    if (errors.contains(NumberPropertiesError.minimum))
      l.add('The value must be greater than or equal to ${config.minimum}');
    if (errors.contains(NumberPropertiesError.exclusiveMinimum))
      l.add('The value must be greater than ${config.exclusiveMinimum}');
    if (errors.contains(NumberPropertiesError.maximum))
      l.add('The value must be less than or equal to ${config.maximum}');
    if (errors.contains(NumberPropertiesError.exclusiveMaximum))
      l.add('The value must be less than ${config.exclusiveMaximum}');
    return l.isEmpty ? null : l.join('\n');
  }

  String maxItemsTooltip(int i) => 'You can only add $i items';

  String? arrayPropertiesError(ArrayProperties config, List value) {
    final errors = config.errors(value);
    final l = <String>[];
    if (errors.contains(ArrayPropertiesError.minItems))
      l.add('You must add at least ${config.minItems} items');
    if (errors.contains(ArrayPropertiesError.maxItems))
      l.add('You can only add ${config.maxItems} items');
    if (errors.contains(ArrayPropertiesError.uniqueItems))
      l.add('Items must be unique');
    return l.isEmpty ? null : l.join('\n');
  }

  String invalidDate() => 'Invalid date';

  String? stringError(
    SchemaProperty property,
    String value,
  ) {
    final errors = inputValidationJsonSchema(
      newValue: value,
      property: property,
    );
    if (errors.isEmpty) return null;

    final l = <String>[];
    if (errors.contains(StringValidationError.minLength))
      l.add(minLength(minLength: property.minLength!));
    if (errors.contains(StringValidationError.maxLength))
      l.add(maxLength(maxLength: property.maxLength!));
    if (errors.contains(StringValidationError.noMatchForPattern))
      l.add(noMatchForPattern(pattern: property.pattern!));
    if (errors.contains(StringValidationError.format))
      l.add(validFormatError(property.format));
    return l.join('\n');
  }

  String validFormatError(PropertyFormat format) {
    switch (format) {
      case PropertyFormat.email:
      case PropertyFormat.idnEmail:
        return 'Should be an email';
      case PropertyFormat.time:
        return 'Invalid time';
      case PropertyFormat.uuid:
        return 'Should be a UUID';
      case PropertyFormat.regex:
        return 'Should be a regular expression';
      case PropertyFormat.ipv4:
      case PropertyFormat.ipv6:
        return 'Should be an IPv${format == PropertyFormat.ipv4 ? '4' : '6'}';
      case PropertyFormat.hostname:
      case PropertyFormat.idnHostname:
      case PropertyFormat.uriTemplate:
      case PropertyFormat.dataUrl:
      case PropertyFormat.uri:
      case PropertyFormat.uriReference:
      case PropertyFormat.iri:
      case PropertyFormat.iriReference:
        return 'Should be a valid URL';
      case PropertyFormat.date:
      case PropertyFormat.dateTime:
        return 'Should be a date';
      case PropertyFormat.jsonPointer:
      case PropertyFormat.relativeJsonPointer:
      // TODO:
      case PropertyFormat.general:
        return 'Invalid format';
    }
  }

  String showItems() => 'Show items';
  String hideItems() => 'Hide items';
}
