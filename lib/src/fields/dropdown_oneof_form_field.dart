import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/property_schema.dart';

class DropdownOneOfJFormField extends PropertyFieldWidget<Object?> {
  const DropdownOneOfJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<Object?, DropdownOneOfJFormField> createState() =>
      _SelectedFormFieldState();
}

class _SelectedFormFieldState
    extends PropertyFieldState<Object?, DropdownOneOfJFormField> {
  late WidgetBuilderInherited widgetBuilderInherited;
  SchemaProperty? valueSelected;
  @override
  Object? get value => valueSelected?.constValue;
  @override
  set value(Object? newValue) {
    setState(() {
      valueSelected = parseValue(newValue);
      super.value = newValue;
    });
  }

  @override
  void initState() {
    super.initState();
    // fill selected value
    final defaultValue = super.getDefaultValue<Object?>();
    if (defaultValue != null) {
      valueSelected = parseValue(defaultValue);
    }
  }

  JsonFormSelectPickerHandler? _previousPicker;
  Future<Object?> Function(Map<Object?, String>)? _customPicker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final currentPicker = widgetBuilderInherited.fieldSelectPicker;
    if (_previousPicker != currentPicker) {
      _customPicker = currentPicker?.call(this);
      _previousPicker = currentPicker;
    }
  }

  SchemaProperty parseValue(Object? value) {
    return property.oneOf.cast<SchemaProperty>().firstWhere(
          (e) => e.constValue == value,
        );
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = widgetBuilderInherited.uiConfig;
    return WrapFieldWithLabel(
      formValue: formValue,
      child: GestureDetector(
        onTap: _onTap,
        child: AbsorbPointer(
          absorbing: _customPicker != null,
          child: DropdownButtonFormField<SchemaProperty>(
            key: JsonFormKeys.inputField(idKey),
            focusNode: focusNode,
            value: valueSelected,
            autovalidateMode: uiConfig.autovalidateMode,
            hint: Text(uiConfig.localizedTexts.select()),
            validator: (value) {
              if (formValue.isRequiredNotNull && value == null) {
                return uiConfig.localizedTexts.required();
              }
              return customValidator(value);
            },
            items: _buildItems(),
            onChanged: _onChanged,
            onSaved: (v) => onSaved(v?.constValue),
            decoration: uiConfig.inputDecoration(formValue),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    if (_customPicker == null) return;
    final response = await _customPicker!(_getItems());

    if (response != null) _onChanged(response as SchemaProperty);
  }

  void _onChanged(SchemaProperty? value) {
    if (readOnly) return;

    setState(() {
      valueSelected = value;
    });
    onChanged(value?.constValue);
  }

  List<DropdownMenuItem<SchemaProperty>>? _buildItems() {
    final uiConfig = widgetBuilderInherited.uiConfig;
    int i = 0;
    return property.oneOf
        .cast<SchemaProperty>()
        .map(
          (item) => DropdownMenuItem<SchemaProperty>(
            key: JsonFormKeys.inputFieldItem(idKey, i++),
            value: item,
            child: Text(
              uiConfig.schemaTitleOrId(item),
              style:
                  readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
            ),
          ),
        )
        .toList(growable: false);
  }

  Map<Object?, String> _getItems() {
    return {
      for (final element in property.oneOf)
        element: widgetBuilderInherited.uiConfig.schemaTitleOrId(element),
    };
  }
}
