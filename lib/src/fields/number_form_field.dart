import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/schema.dart';

class NumberJFormField extends PropertyFieldWidget<num?> {
  const NumberJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<num?, NumberJFormField> createState() =>
      _NumberJFormFieldState();
}

class _NumberJFormFieldState
    extends PropertyFieldState<num?, NumberJFormField> {
  late final textController = TextEditingController(
    text: super.getDefaultValue<num>()?.toString() ?? '',
  );
  @override
  num? get value => parseValue(textController.text);
  @override
  set value(num? newValue) {
    textController.text = newValue?.toString() ?? '';
    super.value = newValue;
  }

  num? parseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return property.type == JsonSchemaType.integer
        ? int.tryParse(value)
        : double.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final numberProperties = property.numberProperties;
    final signed = (numberProperties.minimum ?? -1) < 0 &&
        (numberProperties.exclusiveMinimum ?? -1) < 0;
    final decimal = property.type == JsonSchemaType.number;

    return WrapFieldWithLabel(
      formValue: formValue,
      child: TextFormField(
        key: JsonFormKeys.inputField(idKey),
        focusNode: focusNode,
        keyboardType: TextInputType.numberWithOptions(
          decimal: decimal,
          signed: signed,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp('${signed ? '-?' : ''}[0-9${decimal ? '.,' : ''}]*'),
          ),
        ],
        controller: textController,
        autofocus: property.uiSchema.autofocus,
        enableSuggestions: property.uiSchema.autocomplete,
        onSaved: (value) {
          value = value == null || value.isEmpty
              ? property.uiSchema.emptyValue
              : value;
          final v = parseValue(value);
          if (v == null) return;
          onSaved(v);
        },
        autovalidateMode: uiConfig.autovalidateMode,
        readOnly: readOnly,
        onChanged: (value) {
          final v = parseValue(value);
          if (v == null) return;
          onChanged(v);
        },
        enabled: enabled,
        style: readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
        validator: (String? value) {
          if (formValue.isRequiredNotNull &&
              property.uiSchema.emptyValue == null &&
              value != null &&
              value.isEmpty) {
            return uiConfig.localizedTexts.required();
          }
          if (property.minLength != null &&
              value != null &&
              value.isNotEmpty &&
              value.length <= property.minLength!) {
            return uiConfig.localizedTexts
                .minLength(minLength: property.minLength!);
          }
          final parsed = parseValue(value);
          if (parsed != null) {
            final error = uiConfig.localizedTexts.numberPropertiesError(
              property.numberProperties,
              parsed,
            );
            if (error != null) return error;
          }

          return customValidator(value);
        },
        decoration: uiConfig.inputDecoration(formValue),
      ),
    );
  }
}
