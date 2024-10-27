import 'package:extended_masked_text/extended_masked_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';
import 'package:json_form/src/models/property_schema.dart';

import 'package:json_form/src/utils/date_text_input_json_formatter.dart';

class DateJFormField extends PropertyFieldWidget<DateTime> {
  const DateJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<DateTime, DateJFormField> createState() =>
      _DateJFormFieldState();
}

class _DateJFormFieldState
    extends PropertyFieldState<DateTime, DateJFormField> {
  final txtDateCtrl = MaskedTextController(mask: '0000-00-00');
  DateFormat formatter = DateFormat(dateFormatString);

  @override
  DateTime get value => parseDate();
  @override
  set value(DateTime newValue) {
    txtDateCtrl.updateText(formatter.format(newValue));
  }

  bool get isDateTime => property.format == PropertyFormat.dateTime;

  @override
  void initState() {
    super.initState();
    if (isDateTime) {
      txtDateCtrl.updateMask('0000-00-00 00:00:00');
      formatter = DateFormat(dateTimeFormatString);
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final defaultValue = super.getDefaultValue(parse: false) as String?;
      if (defaultValue != null && DateTime.tryParse(defaultValue) != null)
        txtDateCtrl.updateText(defaultValue);
    });
  }

  DateTime parseDate() {
    return formatter.tryParse(txtDateCtrl.text) ??
        DateTime.now().copyWith(second: 0, millisecond: 0, microsecond: 0);
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final dateIcon = IconButton(
      key: JsonFormKeys.selectDate(idKey),
      icon: const Icon(Icons.date_range_outlined),
      onPressed: enabled ? _openCalendar : null,
    );

    return WrapFieldWithLabel(
      formValue: formValue,
      child: TextFormField(
        key: JsonFormKeys.inputField(idKey),
        controller: txtDateCtrl,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        autofocus: property.uiSchema.autofocus,
        enableSuggestions: property.uiSchema.autocomplete,
        validator: (value) {
          if (formValue.isRequiredNotNull && (value == null || value.isEmpty)) {
            return uiConfig.localizedTexts.required();
          }
          if (value != null &&
              value.isNotEmpty &&
              formatter.tryParse(value) == null)
            return uiConfig.localizedTexts.invalidDate();

          return customValidator(value);
        },
        // inputFormatters: [DateTextInputJsonFormatter()],
        readOnly: readOnly,
        enabled: enabled,
        style: readOnly ? uiConfig.fieldInputReadOnly : uiConfig.fieldInput,
        onSaved: (value) {
          if (value != null && value.isNotEmpty)
            onSaved(formatter.parse(value));
        },
        onChanged: enabled
            ? (value) {
                try {
                  if (DateTime.tryParse(value) != null)
                    onChanged(formatter.parse(value));
                } catch (e) {
                  return;
                }
              }
            : null,
        decoration: uiConfig.inputDecoration(formValue).copyWith(
              hintText: formatter.pattern!.toUpperCase(),
              suffixIcon: isDateTime
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        dateIcon,
                        IconButton(
                          key: JsonFormKeys.selectTime(idKey),
                          icon: const Icon(Icons.access_time_rounded),
                          onPressed: enabled ? _openTime : null,
                        ),
                      ],
                    )
                  : dateIcon,
            ),
      ),
    );
  }

  Future<void> _openCalendar() async {
    DateTime tempDate = parseDate();
    final defaultYearsRange = [1900, 2099];
    List<int> yearsRange = property.uiSchema.yearsRange ?? defaultYearsRange;
    if (yearsRange.isEmpty) yearsRange = defaultYearsRange;
    yearsRange.sort();
    final firstDate = DateTime(yearsRange.first);
    final lastDate = DateTime(
      yearsRange.last == yearsRange.first
          ? yearsRange.last + 1
          : yearsRange.last,
    );
    if (lastDate.isBefore(tempDate) || firstDate.isAfter(tempDate)) {
      tempDate = lastDate;
    }

    DateTime? date = await showDatePicker(
      context: context,
      initialDate: tempDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: property.uiSchema.help,
    );
    if (date == null) return;
    date = date.copyWith(
      hour: tempDate.hour,
      minute: tempDate.minute,
      second: tempDate.second,
    );
    txtDateCtrl.text = formatter.format(date);
    onSaved(date);
  }

  Future<void> _openTime() async {
    late DateTime date = parseDate();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
      helpText: property.uiSchema.help,
    );
    if (time == null) return;
    // TODO: seconds
    date = date.copyWith(
      hour: time.hour,
      minute: time.minute,
      second: date.second,
    );
    txtDateCtrl.text = formatter.format(date);
    onSaved(date);
  }
}
