import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/fields.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:flutter_jsonschema_builder/src/models/property_schema.dart';

import 'package:flutter_jsonschema_builder/src/utils/date_text_input_json_formatter.dart';

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

class _DateJFormFieldState
    extends PropertyFieldState<DateTime, DateJFormField> {
  final txtDateCtrl = MaskedTextController(mask: '0000-00-00');
  DateFormat formatter = DateFormat(dateFormatString);

  bool get isDateTime => widget.property.format == PropertyFormat.dateTime;

  @override
  void initState() {
    super.initState();
    if (isDateTime) {
      txtDateCtrl.updateMask('0000-00-00 00:00:00');
      formatter = DateFormat(dateTimeFormatString);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final defaultValue = widget.property.defaultValue as String?;
      if (defaultValue != null && DateTime.tryParse(defaultValue) != null)
        txtDateCtrl.updateText(defaultValue);
    });
  }

  DateTime parseDate() {
    return formatter.tryParse(txtDateCtrl.text) ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final dateIcon = IconButton(
      icon: const Icon(Icons.date_range_outlined),
      onPressed: widget.property.readOnly ? null : _openCalendar,
    );

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
          if (value != null &&
              value.isNotEmpty &&
              formatter.tryParse(value) == null)
            return uiConfig.localizedTexts.invalidDate();

          return null;
        },
        // inputFormatters: [DateTextInputJsonFormatter()],
        readOnly: widget.property.readOnly,
        style: widget.property.readOnly
            ? const TextStyle(color: Colors.grey)
            : uiConfig.label,
        onSaved: (value) {
          if (value != null && value.isNotEmpty)
            widget.onSaved(formatter.parse(value));
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
              hintText: formatter.pattern!.toUpperCase(),
              suffixIcon: isDateTime
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        dateIcon,
                        IconButton(
                          icon: const Icon(Icons.access_time_rounded),
                          onPressed:
                              widget.property.readOnly ? null : _openTime,
                        ),
                      ],
                    )
                  : dateIcon,
            ),
      ),
    );
  }

  void _openCalendar() async {
    final tempDate = parseDate();
    // TODO: configure params
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: tempDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2099),
    );
    if (date == null) return;
    date = date.copyWith(
      hour: tempDate.hour,
      minute: tempDate.minute,
      second: tempDate.second,
    );
    txtDateCtrl.text = formatter.format(date);
    widget.onSaved(date);
  }

  void _openTime() async {
    late DateTime date = parseDate();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
    );
    if (time == null) return;
    date = date.copyWith(hour: time.hour, minute: time.minute);
    txtDateCtrl.text = formatter.format(date);
    widget.onSaved(date);
  }
}
