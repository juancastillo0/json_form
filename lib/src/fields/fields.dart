import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/models/property_schema.dart';
import 'package:flutter_jsonschema_builder/src/utils/date_text_input_json_formatter.dart';
import 'package:intl/intl.dart';

export 'checkbox_form_field.dart';
export 'date_form_field.dart';
export 'dropdown_form_field.dart';
export 'file_form_field.dart';
export 'number_form_field.dart';
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
  final String? Function(dynamic)? customValidator;

  @override
  PropertyFieldState<T, PropertyFieldWidget<T>> createState();
}

abstract class PropertyFieldState<T, W extends PropertyFieldWidget<T>>
    extends State<W> {
  bool get readOnly => widget.property.uiSchema.readOnly;
  bool get enabled => !widget.property.uiSchema.disabled && !readOnly;

  @override
  void initState() {
    super.initState();
    triggerDefaultValue();
  }

  /// It calls onChanged
  Future<dynamic> triggerDefaultValue() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final value = getDefaultValue();
      if (value == null) return completer.complete();

      widget.onChanged?.call(value);
      completer.complete(value);
    });

    return completer.future;
  }

  dynamic getDefaultValue({bool parse = true}) {
    final property = widget.property;
    final widgetBuilderInherited = WidgetBuilderInherited.get(context);
    var data =
        widgetBuilderInherited.controller.retrieveObjectData(property.idKey) ??
            property.defaultValue;
    if (data != null && parse) {
      if (property.format == PropertyFormat.date ||
          property.format == PropertyFormat.dateTime) {
        data = DateFormat(
          property.format == PropertyFormat.date
              ? dateFormatString
              : dateTimeFormatString,
        ).parse(data);
      }
    }
    return data;
  }
}
