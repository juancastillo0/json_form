import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';
import 'package:json_form/src/models/models.dart';

class DropDownJFormField extends PropertyFieldWidget<Object?> {
  const DropDownJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    this.customPickerHandler,
    super.customValidator,
  });

  final Future<Object?> Function(Map<Object?, Object?>)? customPickerHandler;
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
    });
  }

  late List<Object?> values;
  late List<String> names;

  @override
  void initState() {
    super.initState();
    final enumNames = property.uiSchema.enumNames;
    values = property.type == SchemaType.boolean
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
      property: property,
      child: GestureDetector(
        onTap: enabled ? _onTap : null,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<Object?>(
            key: Key(idKey),
            focusNode: focusNode,
            autovalidateMode: uiConfig.autovalidateMode,
            hint: Text(uiConfig.localizedTexts.select()),
            validator: (value) {
              if (property.requiredNotNull && value == null) {
                return uiConfig.localizedTexts.required();
              }
              if (widget.customValidator != null)
                return widget.customValidator!(value);
              return null;
            },
            items: _buildItems(),
            value: value,
            onChanged: enabled ? _onChanged : null,
            onSaved: widget.onSaved,
            style: readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
            decoration: uiConfig.inputDecoration(property),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    if (widget.customPickerHandler == null) return;
    final response = await widget.customPickerHandler!(_getItems());
    if (response != null) _onChanged(response);
  }

  void _onChanged(Object? value) {
    widget.onChanged?.call(value);
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
          key: Key('${idKey}_$i'),
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
