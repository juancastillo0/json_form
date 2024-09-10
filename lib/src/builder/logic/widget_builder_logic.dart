import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';
import 'package:json_form/src/models/models.dart';

class WidgetBuilderInherited extends InheritedWidget {
  WidgetBuilderInherited({
    super.key,
    required this.controller,
    required super.child,
    this.fileHandler,
    this.customPickerHandler,
    this.customValidatorHandler,
  });

  final JsonFormController controller;
  final FileHandler? fileHandler;
  final CustomPickerHandler? customPickerHandler;
  final CustomValidatorHandler? customValidatorHandler;
  late final JsonFormSchemaUiConfig uiConfig;

  // use description for field help message
  // use id as title for array items

  // implement not-required object
  // validate nullable and required combinations

  void setJsonFormSchemaStyle(
    BuildContext context,
    JsonFormSchemaUiConfig? baseConfig,
  ) {
    uiConfig = JsonFormSchemaUiConfig.fromContext(
      context,
      baseConfig: baseConfig,
    );
  }

  @override
  bool updateShouldNotify(covariant WidgetBuilderInherited oldWidget) =>
      controller.mainSchema != oldWidget.controller.mainSchema ||
      uiConfig != oldWidget.uiConfig;

  static WidgetBuilderInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<WidgetBuilderInherited>();

    assert(result != null, 'No WidgetBuilderInherited found in context');
    return result!;
  }

  static WidgetBuilderInherited get(BuildContext context) {
    final result = context
        .getElementForInheritedWidgetOfExactType<WidgetBuilderInherited>();

    assert(result != null, 'No WidgetBuilderInherited found in context');
    return result!.widget as WidgetBuilderInherited;
  }
}

class FieldUpdated {
  final JsonFormField field;
  final Object? newValue;
  final Object? previousValue;

  const FieldUpdated({
    required this.field,
    required this.newValue,
    required this.previousValue,
  });
}

class JsonFormController extends ChangeNotifier {
  final Map<String, Object?> data;
  Schema? mainSchema;
  GlobalKey<FormState>? formKey;
  FieldUpdated? _lastEvent;
  FieldUpdated? get lastEvent => _lastEvent;

  JsonFormController({
    required this.data,
    this.mainSchema,
    this.formKey,
  });

  /// Retrieves the field controller for [path]
  JsonFormField<Object?>? retrieveField(String path) {
    return _transverseObjectData(path, update: false).key;
  }

  /// Retrieves [data]'s [path]
  Object? retrieveObjectData(String path) {
    return _transverseObjectData(path, update: false).value;
  }

  /// Update [data]'s [path] with [value]
  Object? updateObjectData(String path, Object? value) {
    return _transverseObjectData(path, newValue: value, update: true).value;
  }

  /// Update [data]'s [path] with the value returned in [update]
  Object? updateDataInPlace(
    String path,
    Object? Function(Object? previousValue) update,
  ) {
    return _transverseObjectData(path, updateFn: update, update: true).value;
  }

  /// Transverses [data] until [path] and conditionally applies an [update]
  MapEntry<JsonFormField<Object?>?, Object?> _transverseObjectData(
    String path, {
    required bool update,
    Object? Function(Object? previousValue)? updateFn,
    Object? newValue,
  }) {
    dynamic object = data;
    log('updateObjectData $object path $path newValue $newValue');

    final stack = path.split('.');
    Schema schema = mainSchema!;

    for (int i = 0; i < stack.length; i++) {
      final _key = stack[i];
      int? _keyNumeric;
      if (schema is SchemaArray) {
        _keyNumeric = schema.items.indexWhere((test) => test.id == _key);
        if (_keyNumeric == -1) {
          return const MapEntry(null, null);
        }

        final l = object as List;
        while (l.length != schema.items.length) {
          l.length > schema.items.length ? l.removeLast() : l.add(null);
        }
        schema = schema.items[_keyNumeric];
      } else {
        final s = schema as SchemaObject;
        schema = s.properties.firstWhere(
          (p) => p.id == _key,
          orElse: () => s.dependentSchemas.values.firstWhere(
            (p) => p.id == _key,
            orElse: () => s.dependentSchemas.values
                .expand(
                  (p) => p is SchemaObject ? p.properties : const <Schema>[],
                )
                .firstWhere((p) => p.id == _key),
          ),
        );
      }

      if (i == stack.length - 1) {
        final previous = object[_keyNumeric ?? _key];
        if (update) {
          if (updateFn != null) {
            newValue = updateFn(previous);
          }
          object[_keyNumeric ?? _key] = newValue;

          _lastEvent = FieldUpdated(
            field: schema.formField!,
            previousValue: previous,
            newValue: newValue,
          );
          notifyListeners();
        }
        return MapEntry(schema.formField, previous);
      } else {
        final newContent = schema is SchemaArray ? [] : {};
        final tempObject = object[_keyNumeric ?? _key];
        if (tempObject != null) {
          object = tempObject;
        } else {
          object[_keyNumeric ?? _key] = newContent;
          object = newContent;
        }
      }
    }
    return MapEntry(mainSchema!.formField, data);
  }

  Map<String, Object?>? submit() {
    final formKey = this.formKey!;
    if (formKey.currentState != null && formKey.currentState!.validate()) {
      formKey.currentState!.save();

      log(data.toString());
      return data;
    }
    return null;
  }
}
