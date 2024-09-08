import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/property_schema.dart';
import 'package:json_form/src/models/schema.dart';

class DropdownOneOfJFormField extends PropertyFieldWidget<dynamic> {
  const DropdownOneOfJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    this.customPickerHandler,
    super.customValidator,
  });

  final Future<dynamic> Function(Map)? customPickerHandler;

  @override
  _SelectedFormFieldState createState() => _SelectedFormFieldState();
}

class _SelectedFormFieldState
    extends PropertyFieldState<dynamic, DropdownOneOfJFormField> {
  SchemaProperty? valueSelected;

  @override
  void initState() {
    super.initState();
    // fill selected value
    final defaultValue = super.getDefaultValue();
    if (defaultValue != null) {
      valueSelected = property.oneOf.cast<SchemaProperty>().firstWhere(
            (e) => e.constValue == defaultValue,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: widget.property,
      child: GestureDetector(
        onTap: _onTap,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<SchemaProperty>(
            key: Key(widget.property.idKey),
            value: valueSelected,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hint: Text(uiConfig.localizedTexts.select()),
            isExpanded: false,
            validator: (value) {
              if (widget.property.requiredNotNull && value == null) {
                return uiConfig.localizedTexts.required();
              }
              if (widget.customValidator != null)
                return widget.customValidator!(value);
              return null;
            },
            items: _buildItems(),
            onChanged: _onChanged,
            onSaved: (v) => widget.onSaved(v?.constValue),
            decoration: uiConfig.inputDecoration(widget.property),
          ),
        ),
      ),
    );
  }

  void _onTap() async {
    if (widget.customPickerHandler == null) return;
    final response = await widget.customPickerHandler!(_getItems());

    if (response != null) _onChanged(response as SchemaProperty);
  }

  void _onChanged(SchemaProperty? value) {
    if (readOnly) return;

    setState(() {
      valueSelected = value;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(value?.constValue);
    }
  }

  List<DropdownMenuItem<SchemaProperty>>? _buildItems() {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return property.oneOf
        .cast<SchemaProperty>()
        .map(
          (item) => DropdownMenuItem<SchemaProperty>(
            value: item,
            child: Text(
              item.title,
              style: readOnly ? uiConfig.labelReadOnly : uiConfig.label,
            ),
          ),
        )
        .toList();
  }

  Map _getItems() {
    final Map data = {};
    for (final element in property.oneOf) {
      data[element] = element.title;
    }

    return data;
  }
}
