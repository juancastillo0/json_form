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
    // fill enum property
    values = widget.property.type == SchemaType.boolean
        ? [true, false]
        : (widget.property.enumm ?? widget.property.enumNames ?? []);
    names =
        widget.property.enumNames ?? values.map((v) => v.toString()).toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.property.enumm != null, 'enum is required');
    assert(
      values.length == names.length,
      '[enumNames] and [enum] must be the same size ',
    );
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    inspect(widget.property);

    return FormField<dynamic>(
      key: Key(widget.property.idKey),
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
      builder: (field) {
        return WrapFieldWithLabel(
          property: widget.property,
          ignoreFieldLabel: uiConfig.labelPosition != LabelPosition.table,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List<Widget>.generate(
                  names.length,
                  (int i) => RadioListTile(
                    key: Key('${widget.property.idKey}_$i'),
                    value: values[i],
                    title: Text(
                      names[i],
                      style: widget.property.readOnly
                          ? const TextStyle(color: Colors.grey)
                          : uiConfig.label,
                    ),
                    groupValue: field.value,
                    onChanged: widget.property.readOnly
                        ? null
                        : (dynamic value) {
                            log(value.toString());
                            if (value != null) {
                              field.didChange(value);
                              if (widget.onChanged != null) {
                                widget.onChanged!(value!);
                              }
                            }
                          },
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
