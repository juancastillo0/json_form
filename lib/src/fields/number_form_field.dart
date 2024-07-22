import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:flutter_jsonschema_builder/src/models/schema.dart';

class NumberJFormField extends PropertyFieldWidget<num?> {
  const NumberJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _NumberJFormFieldState createState() => _NumberJFormFieldState();
}

class _NumberJFormFieldState extends State<NumberJFormField> {
  Timer? _timer;

  static final inputFormatters = [
    FilteringTextInputFormatter.allow(RegExp('[0-9.,]+')),
  ];

  @override
  void initState() {
    widget.triggerDefaultValue();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  num? parseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return widget.property.type == SchemaType.integer
        ? int.tryParse(value)
        : double.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: widget.property,
      child: TextFormField(
        key: Key(widget.property.idKey),
        keyboardType: TextInputType.number,
        inputFormatters: inputFormatters,
        initialValue: widget.property.defaultValue?.toString() ?? '',
        autofocus: false,
        onSaved: (value) {
          final v = parseValue(value);
          if (v == null) return;
          widget.onSaved(v);
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        readOnly: widget.property.readOnly,
        onChanged: (value) {
          final v = parseValue(value);
          if (v == null) return;
          if (_timer != null && _timer!.isActive) _timer!.cancel();

          _timer = Timer(const Duration(microseconds: 1), () {
            if (widget.onChanged != null) widget.onChanged!(v);
          });
        },
        style: widget.property.readOnly
            ? const TextStyle(color: Colors.grey)
            : uiConfig.label,
        validator: (String? value) {
          if (widget.property.requiredNotNull &&
              value != null &&
              value.isEmpty) {
            return uiConfig.localizedTexts.required();
          }
          if (widget.property.minLength != null &&
              value != null &&
              value.isNotEmpty &&
              value.length <= widget.property.minLength!) {
            return uiConfig.localizedTexts
                .minLength(minLength: widget.property.minLength!);
          }
          final parsed = parseValue(value);
          if (parsed != null) {
            final error = uiConfig.localizedTexts.numberPropertiesError(
              widget.property.numberProperties,
              parsed,
            );
            if (error != null) return error;
          }

          if (widget.customValidator != null)
            return widget.customValidator!(value);
          return null;
        },
        decoration: InputDecoration(
          helperText:
              widget.property.help != null && widget.property.help!.isNotEmpty
                  ? widget.property.help
                  : null,
          errorStyle: uiConfig.error,
          labelText: uiConfig.fieldLabelText(widget.property),
        ),
      ),
    );
  }
}
