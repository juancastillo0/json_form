import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';

class CheckboxJFormField extends PropertyFieldWidget<bool> {
  const CheckboxJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<bool, CheckboxJFormField> createState() =>
      _CheckboxJFormFieldState();
}

class _CheckboxJFormFieldState
    extends PropertyFieldState<bool, CheckboxJFormField> {
  late FormFieldState<bool> field;
  @override
  bool get value => field.value!;
  @override
  set value(bool newValue) {
    field.didChange(newValue);
    super.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final uiConfig = widgetBuilderInherited.uiConfig;
    return FormField<bool>(
      key: JsonFormKeys.inputField(idKey),
      initialValue: super.getDefaultValue() ?? false,
      autovalidateMode: uiConfig.autovalidateMode,
      onSaved: onSaved,
      validator: customValidator,
      enabled: enabled,
      builder: (field) {
        this.field = field;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              isError: field.hasError,
              value: field.value ?? false,
              enabled: enabled,
              focusNode: focusNode,
              controlAffinity: uiConfig.labelPosition == LabelPosition.table
                  ? ListTileControlAffinity.leading
                  : ListTileControlAffinity.platform,
              title: uiConfig.labelPosition == LabelPosition.table
                  ? null
                  : Text(
                      uiConfig.labelText(formValue),
                      style: readOnly
                          ? uiConfig.fieldInputReadOnly
                          : uiConfig.fieldLabel,
                    ),
              onChanged: enabled
                  ? (bool? value) {
                      field.didChange(value);
                      if (value != null) {
                        onChanged(value);
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
