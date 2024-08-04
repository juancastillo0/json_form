import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:flutter_jsonschema_builder/src/utils/input_validation_json_schema.dart';

import '../utils/utils.dart';
import '../models/models.dart';

class TextJFormField extends PropertyFieldWidget<String> {
  const TextJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _TextJFormFieldState createState() => _TextJFormFieldState();
}

class _TextJFormFieldState extends PropertyFieldState<String, TextJFormField> {
  SchemaProperty get property => widget.property;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: property,
      child: AbsorbPointer(
        absorbing: property.disabled ?? false,
        child: TextFormField(
          key: Key(property.idKey),
          autofocus: (property.autoFocus ?? false),
          keyboardType: getTextInputTypeFromFormat(property.format),
          maxLines: property.widget == "textarea" ? null : 1,
          obscureText: property.format == PropertyFormat.password,
          initialValue: super.getDefaultValue() ?? '',
          onSaved: widget.onSaved,
          maxLength: property.maxLength,
          inputFormatters: [textInputCustomFormatter(property.format)],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          readOnly: property.readOnly,
          onChanged: widget.onChanged,
          validator: (String? value) {
            if (property.requiredNotNull && value != null) {
              final validated = inputValidationJsonSchema(
                localizedTexts: uiConfig.localizedTexts,
                newValue: value,
                property: property,
              );
              if (validated != null) return validated;
            }

            if (widget.customValidator != null)
              return widget.customValidator!(value);

            return null;
          },
          style: property.readOnly
              ? const TextStyle(color: Colors.grey)
              : uiConfig.label,
          decoration: uiConfig.inputDecoration(property),
        ),
      ),
    );
  }

  TextInputType getTextInputTypeFromFormat(PropertyFormat format) {
    switch (format) {
      case PropertyFormat.general:
      case PropertyFormat.time:
      case PropertyFormat.hostname:
      case PropertyFormat.idnHostname:
      case PropertyFormat.uuid:
      case PropertyFormat.ipv4:
      case PropertyFormat.ipv6:
      case PropertyFormat.jsonPointer:
      case PropertyFormat.relativeJsonPointer:
      case PropertyFormat.regex:
        return TextInputType.text;
      case PropertyFormat.password:
        return TextInputType.visiblePassword;
      case PropertyFormat.date:
        return TextInputType.datetime;
      case PropertyFormat.dateTime:
        return TextInputType.datetime;
      case PropertyFormat.email:
      case PropertyFormat.idnEmail:
        return TextInputType.emailAddress;
      case PropertyFormat.dataUrl:
        return TextInputType.text;
      case PropertyFormat.uri:
      case PropertyFormat.uriReference:
      case PropertyFormat.iri:
      case PropertyFormat.iriReference:
      case PropertyFormat.uriTemplate:
        return TextInputType.url;
    }
  }

  TextInputFormatter textInputCustomFormatter(PropertyFormat format) {
    late TextInputFormatter textInputFormatter;
    switch (format) {
      case PropertyFormat.email:
        textInputFormatter = EmailTextInputJsonFormatter();
        break;
      default:
        textInputFormatter =
            DefaultTextInputJsonFormatter(pattern: property.pattern);
        break;
    }
    return textInputFormatter;
  }
}
