import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/flutter_jsonschema_builder.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';

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
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              isError: field.hasError,
              value: field.value ?? false,
              controlAffinity: uiConfig.labelPosition == LabelPosition.table
                  ? ListTileControlAffinity.leading
                  : ListTileControlAffinity.platform,
              title: uiConfig.labelPosition == LabelPosition.table
                  ? null
                  : Text(
                      uiConfig.labelText(widget.property),
                      style: widget.property.readOnly
                          ? const TextStyle(color: Colors.grey)
                          : WidgetBuilderInherited.of(context).uiConfig.label,
                    ),
              onChanged: widget.property.readOnly
                  ? null
                  : (bool? value) {
                      field.didChange(value);
                      if (widget.onChanged != null && value != null) {
                        widget.onChanged!(value);
                      }
                    },
            ),
            if (field.hasError) CustomErrorText(text: field.errorText!),
          ],
        );
      },
    );
  }
}
