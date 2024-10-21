import 'package:json_form/src/models/array_schema.dart';
import 'package:json_form/src/models/property_schema.dart';
import 'package:json_form/src/utils/string_validation.dart';

/// The texts used in the form as hints, tooltips, labels, errors, etc.
/// Can be used to localize or internationalize the form.
class LocalizedTexts {
  /// The texts used in the form as hints, tooltips, labels, errors, etc.
  /// Can be used to localize or internationalize the form.
  const LocalizedTexts();

  /// Used to display the error message when a required field is empty
  String required() => 'Required';

  /// Used when a [String] is too short.
  String minLength({required int minLength}) =>
      'Should be at least $minLength characters';

  /// Used when a [String] is too long
  String maxLength({required int maxLength}) =>
      'Should be less than $maxLength characters';

  /// Used when a [String] does not match the [pattern]
  String noMatchForPattern({required String pattern}) =>
      'No match for pattern "$pattern"';

  /// Hint for dropdown buttons
  String select() => 'Select';

  /// Text for the button to remove an item from an array
  String removeItem() => 'Remove item';

  /// Text for the button to add an item to an array
  String addItem() => 'Add item';

  /// Text for the button to copy an item from an array
  String copyItem() => 'Copy';

  /// Text for the button to add a file
  String addFile() => 'Add file';

  /// Text for the button to submit the form
  String submit() => 'Submit';

  /// Number validation errors for [value] given [NumberProperties].
  /// Returns `null` if the value is valid and does not contain any of the [NumberPropertiesError]s.
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

  /// The tooltip shown when the user tries to add more items than allowed
  String maxItemsTooltip(int i) => 'You can only add $i items';

  /// Array validation errors for [value] given [ArrayProperties].
  /// Returns `null` if the value is valid and does not contain any of the [ArrayPropertiesError]s.
  String? arrayPropertiesError(
    ArrayProperties config,
    List<Object?> value,
  ) {
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

  /// Used when a [String] is not a valid date. For `date` and `date-time` fields
  String invalidDate() => 'Invalid date';

  /// Returns the error message for [value] given the [SchemaProperty] configuration.
  String? stringError(
    SchemaProperty property,
    String value,
  ) {
    final errors = validateJsonSchemaString(
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

  /// Returns the error message shown when a value is does not follow th [PropertyFormat].
  /// Used within [stringError].
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

  // The tooltip for the button to show items in an array
  String showItems() => 'Show items';

  /// The tooltip for the button to hide items in an array
  String hideItems() => 'Hide items';
}
