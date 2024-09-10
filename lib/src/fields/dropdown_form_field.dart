import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import '../models/models.dart';

class DropDownJFormField extends PropertyFieldWidget<dynamic> {
  const DropDownJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    this.customPickerHandler,
    super.customValidator,
  });

  final Future<dynamic> Function(Map)? customPickerHandler;
  @override
  _DropDownJFormFieldState createState() => _DropDownJFormFieldState();
}

class _DropDownJFormFieldState
    extends PropertyFieldState<dynamic, DropDownJFormField> {
  Object? _value;
  @override
  Object? get value => _value;
  @override
  set value(Object? newValue) {
    setState(() {
      _value = newValue;
    });
  }

  late List<dynamic> values;
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
      '[enumNames] and [enum]  must be the same size ',
    );
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: property,
      child: GestureDetector(
        onTap: enabled ? _onTap : null,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<dynamic>(
            key: Key(property.idKey),
            focusNode: focusNode,
            autovalidateMode: uiConfig.autovalidateMode,
            hint: Text(uiConfig.localizedTexts.select()),
            isExpanded: false,
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

  void _onTap() async {
    if (widget.customPickerHandler == null) return;
    final response = await widget.customPickerHandler!(_getItems());
    if (response != null) _onChanged(response);
  }

  void _onChanged(dynamic value) {
    if (widget.onChanged != null) widget.onChanged!(value);
    setState(() {
      this.value = value;
    });
  }

  List<DropdownMenuItem> _buildItems() {
    return List.generate(values.length, (i) {
      return DropdownMenuItem(
        key: Key('${property.idKey}_$i'),
        value: values[i],
        enabled:
            !(property.uiSchema.enumDisabled?.contains(values[i]) ?? false),
        child: Text(names[i]),
      );
    });
  }

  Map _getItems() {
    return {
      for (var i = 0; i < values.length; i++) values[i]: names[i],
    };
  }
}
