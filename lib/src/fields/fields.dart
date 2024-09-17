import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/models/property_schema.dart';
import 'package:json_form/src/models/schema.dart';
import 'package:json_form/src/utils/date_text_input_json_formatter.dart';

export 'checkbox_form_field.dart';
export 'date_form_field.dart';
export 'dropdown_form_field.dart';
export 'dropdown_oneof_form_field.dart';
export 'file_form_field.dart';
export 'number_form_field.dart';
export 'radio_button_form_field.dart';
export 'slider_form_field.dart';
export 'text_form_field.dart';

abstract class PropertyFieldWidget<T> extends StatefulWidget {
  const PropertyFieldWidget({
    super.key,
    required this.property,
    required this.onSaved,
    required this.onChanged,
    this.customValidator,
  });

  final SchemaProperty property;
  final ValueSetter<T?> onSaved;
  final ValueChanged<T?>? onChanged;
  final String? Function(Object?)? customValidator;

  @override
  PropertyFieldState<T, PropertyFieldWidget<T>> createState();
}

abstract class PropertyFieldState<T, W extends PropertyFieldWidget<T>>
    extends State<W> implements JsonFormField<T> {
  late JsonFormValue formValue;
  @override
  final focusNode = FocusNode();
  @override
  SchemaProperty get property => widget.property;
  bool get readOnly => property.uiSchema.readOnly;
  bool get enabled => !property.uiSchema.disabled && !readOnly;

  @override
  T get value;
  @override
  set value(T newValue);

  @override
  String get idKey => formValue.idKey;

  @override
  void initState() {
    super.initState();
    triggerDefaultValue();
    formValue = JsonFormController.setField(context, property, this);
  }

  @override
  void dispose() {
    // TODO: remove field
    // if (property.formField == this) {
    //   property.formField = null;
    // }
    super.dispose();
  }

  Future<T?> triggerDefaultValue() async {
    final completer = Completer<T?>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final value = getDefaultValue<T>();
      if (value == null) return completer.complete();

      widget.onChanged?.call(value);
      completer.complete(value);
    });

    return completer.future;
  }

  D? getDefaultValue<D>({bool parse = true}) {
    final widgetBuilderInherited = WidgetBuilderInherited.get(context);
    final objectData =
        widgetBuilderInherited.controller.retrieveObjectData(idKey);
    final isDate = property.format == PropertyFormat.date ||
        property.format == PropertyFormat.dateTime;
    var data = (objectData is D || isDate && parse && objectData is String
            ? objectData
            : null) ??
        property.defaultValue;
    if (data != null && parse) {
      if (isDate && data is String) {
        data = DateFormat(
          property.format == PropertyFormat.date
              ? dateFormatString
              : dateTimeFormatString,
        ).parse(data);
      }
    }
    return data is D ? data : null;
  }
}
