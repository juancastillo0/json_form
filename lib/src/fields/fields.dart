import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/object_schema_logic.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/models/property_schema.dart';
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
  });

  final SchemaProperty property;

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

  JsonFormValidatorHandler? _previousValidator;
  String? Function(Object?)? _customValidator;

  @override
  T get value;
  @override
  @mustCallSuper
  set value(T newValue) {
    WidgetBuilderInherited.of(context).controller.updateData(idKey, newValue);
  }

  @override
  String get idKey => formValue.idKey;

  @override
  void initState() {
    super.initState();
    triggerDefaultValue();
    formValue = PrivateJsonFormController.setField(context, property, this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentValidator = WidgetBuilderInherited.of(context).fieldValidator;
    if (_previousValidator != currentValidator) {
      _customValidator = currentValidator?.call(this);
      _previousValidator = currentValidator;
    }
  }

  String? customValidator(Object? newValue) {
    return _customValidator?.call(newValue);
  }

  void onSaved(Object? newValue) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    if (newValue is! DateTime) {
      widgetBuilderInherited.controller.updateData(idKey, newValue);
    } else {
      String date;
      if (property.format == PropertyFormat.date) {
        date = formatDate(newValue);
      } else {
        date = formatDateTime(newValue);
      }
      widgetBuilderInherited.controller.updateData(idKey, date);
    }
  }

  void onChanged(Object? value) {
    _dispatchChangeEventToParentObject(value);
    onSaved(value);
  }

  void _dispatchChangeEventToParentObject(Object? value) {
    bool isActive;
    if (value is bool) {
      isActive = value;
    } else if (value is String) {
      isActive = value.isNotEmpty;
    } else if (value is List) {
      isActive = value.isNotEmpty;
    } else {
      isActive = value != null;
    }

    final isSelect = property.enumm != null && property.enumm!.isNotEmpty ||
        property.oneOf.isNotEmpty;
    if (isActive != formValue.isDependentsActive || isSelect) {
      ObjectSchemaInherited.of(context).listenChangeProperty(
        isActive,
        formValue,
        optionalValue: isSelect ? value : null,
      );
    }
  }

  @override
  void dispose() {
    // TODO: remove field
    // if (property.formField == this) {
    //   property.formField = null;
    // }
    super.dispose();
  }

  Future<T?> triggerDefaultValue() {
    final completer = Completer<T?>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final value = getDefaultValue<T>();
      if (value == null) return completer.complete();

      onChanged(value);
      completer.complete(value);
    });

    return completer.future;
  }

  D? getDefaultValue<D>({bool parse = true}) {
    final widgetBuilderInherited = WidgetBuilderInherited.get(context);
    final objectData = widgetBuilderInherited.controller.retrieveData(idKey);
    final isDate = property.format == PropertyFormat.date ||
        property.format == PropertyFormat.dateTime;
    var data = (objectData is D || isDate && parse && objectData is String
            ? objectData
            : null) ??
        property.defaultValue;
    if (data != null && parse) {
      if (isDate && data is String) {
        data = DateTime.parse(
          property.format == PropertyFormat.date ? data.split(' ').first : data,
        );
      }
    }
    return data is D ? data : null;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return '${super.toString(minLevel: minLevel)}(idKey: $idKey, property: $property)';
  }
}
