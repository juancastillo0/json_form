import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
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
  dynamic value;

  late List<dynamic> values;
  late List<String> names;

  @override
  void initState() {
    values = widget.property.type == SchemaType.boolean
        ? [true, false]
        : (widget.property.enumm ?? widget.property.enumNames ?? []);
    names =
        widget.property.enumNames ?? values.map((v) => v.toString()).toList();

    value = super.getDefaultValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      names.length == values.length,
      '[enumNames] and [enum]  must be the same size ',
    );
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: widget.property,
      child: GestureDetector(
        onTap: _onTap,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<dynamic>(
            key: Key(widget.property.idKey),
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
            value: value,
            onChanged: _onChanged,
            onSaved: widget.onSaved,
            style: widget.property.readOnly
                ? const TextStyle(color: Colors.grey)
                : uiConfig.label,
            decoration: uiConfig.inputDecoration(widget.property),
          ),
        ),
      ),
    );
  }

  void _onTap() async {
    log('ontap');
    if (widget.customPickerHandler == null) return;
    final response = await widget.customPickerHandler!(_getItems());
    if (response != null) _onChanged(response);
  }

  void _onChanged(dynamic value) {
    if (widget.property.readOnly) return;

    if (widget.onChanged != null) widget.onChanged!(value);
    setState(() {
      this.value = value;
    });
  }

  List<DropdownMenuItem> _buildItems() {
    return List.generate(values.length, (i) {
      return DropdownMenuItem(
        key: Key('${widget.property.idKey}_$i'),
        value: values[i],
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
