import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';
import 'package:json_form/src/utils/utils.dart';

class TextJFormField extends PropertyFieldWidget<String> {
  const TextJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  PropertyFieldState<String, TextJFormField> createState() =>
      _TextJFormFieldState();
}

class _TextJFormFieldState extends PropertyFieldState<String, TextJFormField> {
  late final textController = TextEditingController(
    text: super.getDefaultValue<String>()?.toString() ?? '',
  );
  @override
  String get value => textController.text;
  @override
  set value(String newValue) {
    textController.text = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final uiSchema = property.uiSchema;
    return WrapFieldWithLabel(
      property: property,
      child: TextFormField(
        key: Key(idKey),
        focusNode: focusNode,
        autofocus: uiSchema.autofocus,
        enableSuggestions: uiSchema.autocomplete,
        keyboardType: getTextInputTypeFromFormat(
          property.format,
          uiSchema.widget,
        ),
        enabled: enabled,
        maxLines: uiSchema.widget == "textarea" ? null : 1,
        obscureText: uiSchema.widget == "password",
        controller: textController,
        onSaved: (v) => widget.onSaved(
          v == null || v.isEmpty ? property.uiSchema.emptyValue : v,
        ),
        maxLength: property.maxLength,
        inputFormatters: [textInputCustomFormatter(property.format)],
        autovalidateMode: uiConfig.autovalidateMode,
        readOnly: readOnly,
        onChanged: widget.onChanged,
        validator: (String? value) {
          if (property.requiredNotNull &&
              property.uiSchema.emptyValue == null &&
              (value == null || value.isEmpty)) {
            return uiConfig.localizedTexts.required();
          }
          if (widget.customValidator != null)
            return widget.customValidator!(value);
          if (value != null && value.isNotEmpty) {
            final error = uiConfig.localizedTexts.stringError(
              property,
              value,
            );
            if (error != null) return error;
          }
          return null;
        },
        style: readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
        decoration: uiConfig.inputDecoration(property),
      ),
    );
  }

  TextInputType getTextInputTypeFromFormat(
    PropertyFormat format,
    String? widget,
  ) {
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
        return widget == 'password'
            ? TextInputType.visiblePassword
            : TextInputType.text;
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
      default:
        textInputFormatter =
            DefaultTextInputJsonFormatter(pattern: property.pattern);
        break;
    }
    return textInputFormatter;
  }
}
