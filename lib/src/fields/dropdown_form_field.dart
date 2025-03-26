import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class DropDownJFormField extends PropertyFieldWidget<Object?> {
  const DropDownJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<Object?, PropertyFieldWidget<Object?>> createState() =>
      _DropDownJFormFieldState();
}

class _DropDownJFormFieldState
    extends PropertyFieldState<Object?, DropDownJFormField> {
  Object? _value;
  @override
  Object? get value => _value;
  @override
  set value(Object? newValue) {
    setState(() {
      _value = newValue;
      super.value = newValue;
    });
  }

  late List<Object?> values;
  late List<String> names;

  @override
  void initState() {
    super.initState();
    final enumNames = property.uiSchema.enumNames;
    values = property.type == JsonSchemaType.boolean
        ? [true, false]
        : (property.enumm ?? enumNames ?? []);
    names = enumNames ?? values.map((v) => v.toString()).toList();

    _value = super.getDefaultValue();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      names.length == values.length,
      '[enumNames] and [enum] must be the same size ',
    );
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      formValue: formValue,
      child: GestureDetector(
        onTap: enabled ? _onTap : null,
        child: AbsorbPointer(
          absorbing: _customPicker != null,
          child: DropdownButtonFormField<Object?>(
            key: JsonFormKeys.inputField(idKey),
            focusNode: focusNode,
            autovalidateMode: uiConfig.autovalidateMode,
            hint: Text(uiConfig.localizedTexts.select()),
            validator: (value) {
              if (formValue.isRequiredNotNull && value == null) {
                return uiConfig.localizedTexts.required();
              }
              return customValidator(value);
            },
            items: _buildItems(),
            value: value,
            onChanged: enabled ? _onChanged : null,
            onSaved: onSaved,
            style: readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
            decoration: uiConfig.inputDecoration(formValue),
            isExpanded: true,
          ),
        ),
      ),
    );
  }

  JsonFormSelectPickerHandler? _previousPicker;
  Future<Object?> Function(Map<Object?, String>)? _customPicker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPicker = WidgetBuilderInherited.of(context).fieldSelectPicker;
    if (_previousPicker != currentPicker) {
      _customPicker = currentPicker?.call(this);
      _previousPicker = currentPicker;
    }
  }

  Future<void> _onTap() async {
    if (_customPicker == null) return;
    final response = await _customPicker!(_getItems());
    if (response != null) _onChanged(response);
  }

  void _onChanged(Object? value) {
    onChanged(value);
    setState(() {
      this.value = value;
    });
  }

  List<DropdownMenuItem<Object?>> _buildItems() {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return List.generate(
      values.length,
      (i) {
        final readOnlyValue = readOnly ||
            (property.uiSchema.enumDisabled?.contains(values[i]) ?? false);
        return DropdownMenuItem(
          key: JsonFormKeys.inputFieldItem(idKey, i),
          value: values[i],
          enabled: !readOnlyValue,
          child: Text(
            names[i],
            style: readOnlyValue
                ? uiConfig.fieldInputReadOnly
                : uiConfig.fieldInput,
          ),
        );
      },
      growable: false,
    );
  }

  Map<Object?, String> _getItems() {
    return {
      for (var i = 0; i < values.length; i++) values[i]: names[i],
    };
  }
}
