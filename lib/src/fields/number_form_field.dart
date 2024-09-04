import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/property_schema.dart';
import 'package:json_form/src/models/schema.dart';

class NumberJFormField extends PropertyFieldWidget<num?> {
  const NumberJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _NumberJFormFieldState createState() => _NumberJFormFieldState();
}

class _NumberJFormFieldState
    extends PropertyFieldState<num?, NumberJFormField> {
  num? parseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return widget.property.type == SchemaType.integer
        ? int.tryParse(value)
        : double.tryParse(value);
  }

  SchemaProperty get property => widget.property;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final numberProperties = property.numberProperties;
    final signed = (numberProperties.minimum ?? -1) < 0 &&
        (numberProperties.exclusiveMinimum ?? -1) < 0;
    final decimal = property.type == SchemaType.number;

    return WrapFieldWithLabel(
      property: property,
      child: TextFormField(
        key: Key(property.idKey),
        keyboardType: TextInputType.numberWithOptions(
          decimal: decimal,
          signed: signed,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp('${signed ? '-?' : ''}[0-9${decimal ? '.,' : ''}]*'),
          ),
        ],
        initialValue: super.getDefaultValue()?.toString() ?? '',
        autofocus: property.uiSchema.autoFocus,
        enableSuggestions: property.uiSchema.autoComplete,
        onSaved: (value) {
          value = value == null || value.isEmpty
              ? property.uiSchema.emptyValue
              : value;
          final v = parseValue(value);
          if (v == null) return;
          widget.onSaved(v);
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        readOnly: readOnly,
        onChanged: (value) {
          final v = parseValue(value);
          if (v == null) return;
          if (widget.onChanged != null) widget.onChanged!(v);
        },
        enabled: enabled,
        style: readOnly ? const TextStyle(color: Colors.grey) : uiConfig.label,
        validator: (String? value) {
          if (property.requiredNotNull &&
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

          if (widget.customValidator != null)
            return widget.customValidator!(value);
          return null;
        },
        decoration: uiConfig.inputDecoration(property),
      ),
    );
  }
}
