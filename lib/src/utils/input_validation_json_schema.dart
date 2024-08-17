import 'package:validators/validators.dart' as validators;
import 'package:flutter_jsonschema_builder/src/models/property_schema.dart';

enum StringValidationError {
  minLength,
  maxLength,
  noMatchForPattern,
  format,
}

List<StringValidationError> inputValidationJsonSchema({
  required String newValue,
  required SchemaProperty property,
}) {
  final errors = <StringValidationError>[];
  final maxLength = property.maxLength;
  if (newValue.length < (property.minLength ?? 0)) {
    errors.add(StringValidationError.minLength);
  }
  if (maxLength != null && newValue.length > maxLength) {
    errors.add(StringValidationError.maxLength);
  }
  if (property.pattern != null &&
      !validators.matches(newValue, property.pattern!)) {
    errors.add(StringValidationError.noMatchForPattern);
  }
  if (!isValidFormat(property.format, newValue)) {
    errors.add(StringValidationError.format);
  }
  return errors;
}

bool isValidFormat(PropertyFormat format, String value) {
  switch (format) {
    case PropertyFormat.email:
    case PropertyFormat.idnEmail:
      return validators.isEmail(value);
    case PropertyFormat.time:
      return RegExp(r'^[0-9]{2}:[0-9]{2}(:[0-9]{2})?$').hasMatch(value);
    case PropertyFormat.uuid:
      return validators.isUUID(value);
    case PropertyFormat.regex:
      try {
        RegExp(value);
        return true;
      } catch (_) {
        return false;
      }
    case PropertyFormat.ipv4:
    case PropertyFormat.ipv6:
      return validators.isIP(
        value,
        format == PropertyFormat.ipv4 ? '4' : '6',
      );
    case PropertyFormat.hostname:
    case PropertyFormat.idnHostname:
    case PropertyFormat.uriTemplate:
    case PropertyFormat.dataUrl:
    case PropertyFormat.uri:
    case PropertyFormat.uriReference:
    case PropertyFormat.iri:
    case PropertyFormat.iriReference:
      return validators.isURL(value);
    // TODO:
    case PropertyFormat.date:
    case PropertyFormat.dateTime:
    case PropertyFormat.jsonPointer:
    case PropertyFormat.relativeJsonPointer:
    case PropertyFormat.general:
      return true;
  }
}
