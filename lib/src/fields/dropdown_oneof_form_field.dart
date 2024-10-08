import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/property_schema.dart';

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
  Object? get value => valueSelected?.constValue;
  @override
  set value(Object? newValue) {
    setState(() {
      valueSelected = parseValue(newValue);
    });
  }

  @override
  void initState() {
    super.initState();
    // fill selected value
    final defaultValue = super.getDefaultValue();
    if (defaultValue != null) {
      valueSelected = parseValue(defaultValue);
    }
  }

  SchemaProperty parseValue(Object? value) {
    return property.oneOf.cast<SchemaProperty>().firstWhere(
          (e) => e.constValue == value,
        );
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: property,
      child: GestureDetector(
        onTap: _onTap,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<SchemaProperty>(
            key: Key(property.idKey),
            focusNode: focusNode,
            value: valueSelected,
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
            onChanged: _onChanged,
            onSaved: (v) => widget.onSaved(v?.constValue),
            decoration: uiConfig.inputDecoration(property),
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
    int i = 0;
    return property.oneOf
        .cast<SchemaProperty>()
        .map(
          (item) => DropdownMenuItem<SchemaProperty>(
            key: Key('${property.idKey}_${i++}'),
            value: item,
            child: Text(
              item.titleOrId,
              style:
                  readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
            ),
          ),
        )
        .toList(growable: false);
  }

  Map _getItems() {
    final Map data = {};
    for (final element in property.oneOf) {
      data[element] = element.title;
    }

    return data;
  }
}
