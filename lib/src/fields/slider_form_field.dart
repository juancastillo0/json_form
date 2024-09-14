import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class SliderJFormField extends PropertyFieldWidget<num> {
  const SliderJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _SliderJFormFieldState createState() => _SliderJFormFieldState();
}

class _SliderJFormFieldState extends PropertyFieldState<num, SliderJFormField> {
  late FormFieldState<num> field;
  @override
  num get value => field.value!;
  @override
  set value(num newValue) {
    field.didChange(newValue);
  }

  late List<num> values;

  @override
  void initState() {
    super.initState();
    values = property.enumm?.cast() ?? property.numberProperties.options();
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    inspect(property);

    return FormField<num>(
      key: Key(idKey),
      autovalidateMode: uiConfig.autovalidateMode,
      initialValue: super.getDefaultValue() ?? values.first,
      onSaved: (newValue) {
        widget.onSaved(newValue);
      },
      validator: (value) {
        if (widget.customValidator != null)
          return widget.customValidator!(value);

        return null;
      },
      enabled: enabled,
      builder: (field) {
        this.field = field;
        final value = field.value!.toDouble();
        return WrapFieldWithLabel(
          property: property,
          ignoreFieldLabel: uiConfig.labelPosition != LabelPosition.table,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    value.toString(),
                    style: readOnly
                        ? uiConfig.fieldInputReadOnly
                        : uiConfig.fieldInput,
                  ),
                  Expanded(
                    child: Slider(
                      focusNode: focusNode,
                      label: value.toString(),
                      value: value,
                      min: values.first.toDouble(),
                      max: values.last.toDouble(),
                      divisions: values.length - 1,
                      autofocus: property.uiSchema.autofocus,
                      onChanged: enabled
                          ? (double value) {
                              final v = property.type == SchemaType.integer
                                  ? value.round()
                                  : value;
                              field.didChange(v);
                              widget.onChanged!(v);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              if (field.hasError) CustomErrorText(text: field.errorText!),
            ],
          ),
        );
      },
    );
  }
}
