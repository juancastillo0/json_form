import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';

class RadioButtonJFormField extends PropertyFieldWidget<Object?> {
  const RadioButtonJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  PropertyFieldState<Object?, RadioButtonJFormField> createState() =>
      _RadioButtonJFormFieldState();
}

class _RadioButtonJFormFieldState
    extends PropertyFieldState<Object?, RadioButtonJFormField> {
  late FormFieldState<Object?> field;
  @override
  Object? get value => field.value;
  @override
  set value(Object? newValue) {
    field.didChange(newValue);
  }

  late List<Object?> values;
  late List<String> names;

  @override
  void initState() {
    super.initState();
    // fill enum property
    final enumNames = property.uiSchema.enumNames;
    switch (property.type) {
      case SchemaType.boolean:
        values = [true, false];
        break;
      case SchemaType.integer:
      case SchemaType.number:
        values = property.enumm ?? property.numberProperties.options();
        break;
      default:
        values = (property.enumm ?? enumNames)!;
    }
    names =
        enumNames ?? values.map((v) => v.toString()).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      values.length == names.length,
      '[enumNames] and [enum] must be the same size ',
    );
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    inspect(property);

    return FormField<Object?>(
      key: Key(idKey),
      autovalidateMode: uiConfig.autovalidateMode,
      initialValue: super.getDefaultValue(),
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
        return Focus(
          focusNode: focusNode,
          child: WrapFieldWithLabel(
            formValue: formValue,
            ignoreFieldLabel: uiConfig.labelPosition != LabelPosition.table,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(
                    names.length,
                    (int i) => RadioListTile<Object?>(
                      key: Key('${idKey}_$i'),
                      value: values[i],
                      title: Text(
                        names[i],
                        style: readOnly
                            ? uiConfig.fieldInputReadOnly
                            : uiConfig.fieldInput,
                      ),
                      groupValue: field.value,
                      autofocus: i == 0 && property.uiSchema.autofocus,
                      onChanged: enabled
                          ? (Object? value) {
                              log(value.toString());
                              if (value != null) {
                                field.didChange(value);
                                widget.onChanged?.call(value);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
                if (field.hasError) CustomErrorText(text: field.errorText!),
              ],
            ),
          ),
        );
      },
    );
  }
}
