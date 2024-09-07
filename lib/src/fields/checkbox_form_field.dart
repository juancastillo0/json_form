import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';

class CheckboxJFormField extends PropertyFieldWidget<bool> {
  const CheckboxJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _CheckboxJFormFieldState createState() => _CheckboxJFormFieldState();
}

class _CheckboxJFormFieldState
    extends PropertyFieldState<bool, CheckboxJFormField> {
  @override
  Widget build(BuildContext context) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final uiConfig = widgetBuilderInherited.uiConfig;
    return FormField<bool>(
      key: Key(widget.property.idKey),
      initialValue: super.getDefaultValue() ?? false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onSaved: widget.onSaved,
      validator: widget.customValidator,
      enabled: enabled,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              isError: field.hasError,
              value: field.value ?? false,
              enabled: enabled,
              controlAffinity: uiConfig.labelPosition == LabelPosition.table
                  ? ListTileControlAffinity.leading
                  : ListTileControlAffinity.platform,
              title: uiConfig.labelPosition == LabelPosition.table
                  ? null
                  : Text(
                      uiConfig.labelText(widget.property),
                      style: readOnly ? uiConfig.labelReadOnly : uiConfig.label,
                    ),
              onChanged: enabled
                  ? (bool? value) {
                      field.didChange(value);
                      if (widget.onChanged != null && value != null) {
                        widget.onChanged!(value);
                      }
                    }
                  : null,
            ),
            if (field.hasError) CustomErrorText(text: field.errorText!),
          ],
        );
      },
    );
  }
}
