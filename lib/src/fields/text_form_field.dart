import 'dart:async';

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

class _TextJFormFieldState extends State<TextJFormField> {
  Timer? _timer;
  SchemaProperty get property => widget.property;

  @override
  void initState() {
    widget.triggerDefaultValue();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
          initialValue: property.defaultValue ?? '',
          onSaved: widget.onSaved,
          maxLength: property.maxLength,
          inputFormatters: [textInputCustomFormatter(property.format)],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          readOnly: property.readOnly,
          onChanged: (value) {
            if (_timer != null && _timer!.isActive) _timer!.cancel();

            _timer = Timer(const Duration(microseconds: 1), () {
              if (widget.onChanged != null) widget.onChanged!(value);
            });
          },
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
          decoration: InputDecoration(
            helperText: property.help != null && property.help!.isNotEmpty
                ? property.help
                : null,
            labelStyle: const TextStyle(color: Colors.blue),
            errorStyle: uiConfig.error,
            labelText: uiConfig.fieldLabelText(property),
          ),
        ),
      ),
    );
  }

  TextInputType getTextInputTypeFromFormat(PropertyFormat format) {
    late TextInputType textInputType;

    switch (format) {
      case PropertyFormat.general:
        textInputType = TextInputType.text;
        break;
      case PropertyFormat.password:
        textInputType = TextInputType.visiblePassword;
        break;
      case PropertyFormat.date:
        textInputType = TextInputType.datetime;
        break;
      case PropertyFormat.datetime:
        textInputType = TextInputType.datetime;
        break;
      case PropertyFormat.email:
        textInputType = TextInputType.emailAddress;
        break;
      case PropertyFormat.dataurl:
        textInputType = TextInputType.text;
        break;
      case PropertyFormat.uri:
        textInputType = TextInputType.url;
        break;
    }

    return textInputType;
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
