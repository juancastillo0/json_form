import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:intl/intl.dart';
import 'package:extended_masked_text/extended_masked_text.dart';

import '../utils/date_text_input_json_formatter.dart';

class DateJFormField extends PropertyFieldWidget<DateTime> {
  const DateJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    super.customValidator,
  });

  @override
  _DateJFormFieldState createState() => _DateJFormFieldState();
}

class _DateJFormFieldState extends State<DateJFormField> {
  final txtDateCtrl = MaskedTextController(mask: '0000-00-00');
  final formatter = DateFormat(dateFormatString);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final defaultValue = widget.property.defaultValue as String?;
      if (defaultValue != null && DateTime.tryParse(defaultValue) != null)
        txtDateCtrl.updateText(defaultValue);
    });

    widget.triggerDefaultValue();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;

    return WrapFieldWithLabel(
      property: widget.property,
      child: TextFormField(
        key: Key(widget.property.idKey),
        controller: txtDateCtrl,
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (widget.property.requiredNotNull &&
              (value == null || value.isEmpty)) {
            return uiConfig.localizedTexts.required();
          }
          if (widget.customValidator != null)
            return widget.customValidator!(value);
          return null;
        },
        // inputFormatters: [DateTextInputJsonFormatter()],
        readOnly: widget.property.readOnly,
        style: widget.property.readOnly
            ? const TextStyle(color: Colors.grey)
            : uiConfig.label,

        onSaved: (value) {
          if (value != null) widget.onSaved(formatter.parse(value));
        },
        onChanged: (value) {
          try {
            if (widget.onChanged != null && DateTime.tryParse(value) != null)
              widget.onChanged!(formatter.parse(value));
          } catch (e) {
            return;
          }
        },
        decoration: uiConfig.inputDecoration(widget.property).copyWith(
              hintText: dateFormatString.toUpperCase(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.date_range_outlined),
                onPressed: widget.property.readOnly ? null : _openCalendar,
              ),
            ),
      ),
    );
  }

  void _openCalendar() async {
    late DateTime tempDate;
    try {
      tempDate = formatter.parse(txtDateCtrl.text);
    } catch (e) {
      tempDate = DateTime.now();
    }

    final date = await showDatePicker(
      context: context,
      initialDate: tempDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2099),
    );

    if (date != null) txtDateCtrl.text = formatter.format(date);

    widget.onSaved(date);
  }
}
