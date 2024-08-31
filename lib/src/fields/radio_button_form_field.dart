import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/flutter_jsonschema_builder.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import '../models/models.dart';

class RadioButtonJFormField extends PropertyFieldWidget<dynamic> {
  const RadioButtonJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _RadioButtonJFormFieldState createState() => _RadioButtonJFormFieldState();
}

class _RadioButtonJFormFieldState
    extends PropertyFieldState<dynamic, RadioButtonJFormField> {
  late List<dynamic> values;
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

    return FormField<dynamic>(
      key: Key(property.idKey),
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
        return WrapFieldWithLabel(
          property: property,
          ignoreFieldLabel: uiConfig.labelPosition != LabelPosition.table,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List<Widget>.generate(
                  names.length,
                  (int i) => RadioListTile(
                    key: Key('${property.idKey}_$i'),
                    value: values[i],
                    title: Text(
                      names[i],
                      style: readOnly
                          ? const TextStyle(color: Colors.grey)
                          : uiConfig.label,
                    ),
                    groupValue: field.value,
                    onChanged: enabled
                        ? (dynamic value) {
                            log(value.toString());
                            if (value != null) {
                              field.didChange(value);
                              if (widget.onChanged != null) {
                                widget.onChanged!(value!);
                              }
                            }
                          }
                        : null,
                  ),
                ),
              ),
              if (field.hasError) CustomErrorText(text: field.errorText!),
            ],
          ),
        );
      },
    );
  }
}
