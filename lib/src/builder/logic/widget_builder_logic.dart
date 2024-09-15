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
    required BuildContext context,
    JsonFormSchemaUiConfig? baseConfig,
    JsonFormSchemaUiConfig? uiConfig,
  }) : uiConfig = uiConfig ??
            JsonFormSchemaUiConfig.fromContext(
              context,
              baseConfig: baseConfig,
            );
  final JsonFormController controller;
  final FileHandler? fileHandler;
  final CustomPickerHandler? customPickerHandler;
  final CustomValidatorHandler? customValidatorHandler;
  final JsonFormSchemaUiConfig uiConfig;

  // TODO: implement not-required object
  // TODO: validate nullable and required combinations

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

class FieldUpdated<T> {
  final JsonFormField<T> field;
  final Object? newValue;
  final Object? previousValue;

  const FieldUpdated({
    required this.field,
    required this.newValue,
    required this.previousValue,
  });
}

class JsonFormController extends ChangeNotifier {
  JsonFormValue rootFormValue;
  Object? rootOutputData;
  Schema? mainSchema;
  GlobalKey<FormState>? formKey;
  FieldUpdated<Object?>? _lastEvent;
  FieldUpdated<Object?>? get lastEvent => _lastEvent;

  JsonFormController({
    required Map<String, Object?> data,
    this.mainSchema,
    this.formKey,
  })  : rootOutputData = data,
        rootFormValue = JsonFormValue(
          parent: null,
          schema: mainSchema,
          id: '',
        );

  static JsonFormValue setField(
    BuildContext context,
    Schema schema,
    JsonFormField<Object?> field,
    String id,
  ) {
    final controller = WidgetBuilderInherited.get(context).controller;

    final path = JsonFormKeyPath.ofPath(context);
    if (path == "") {
      return controller.rootFormValue = JsonFormValue(
        parent: null,
        schema: schema,
        id: '',
      )..field = field;
    } else {
      return controller._transverseObjectData(
        path,
        isSchemaUpdate: true,
        updateFn: (v) {
          v ??= JsonFormValue(
            id: id,
            parent: null,
            schema: schema,
          );
          return v..field = field;
        },
      ).key!;
    }
  }

  /// Retrieves the field controller for [path]
  JsonFormField<Object?>? retrieveField(String path) {
    return _transverseObjectData(path).key?.field;
  }

  /// Retrieves [rootFormValue]'s [path]
  Object? retrieveObjectData(String path) {
    return _transverseObjectData(path).value;
  }

  /// Update [rootFormValue]'s [path] with [value]
  Object? updateObjectData(String path, Object? value) {
    return updateDataInPlace(path, (_) => value);
  }

  /// Update [rootFormValue]'s [path] with the value returned in [update]
  Object? updateDataInPlace(
    String path,
    Object? Function(Object? previousValue) update,
  ) {
    return _transverseObjectData(
      path,
      updateFn: (v) => v!..value = update(v.value),
    ).value;
  }

  /// Transverses [rootFormValue] until [path] and conditionally applies an [update]
  MapEntry<JsonFormValue?, Object?> _transverseObjectData(
    String path, {
    JsonFormValue Function(JsonFormValue? previousValue)? updateFn,
    bool isSchemaUpdate = false,
  }) {
    final update = updateFn != null;
    JsonFormValue object = rootFormValue;
    dynamic outputValues = rootOutputData;
    log('updateObjectData $object path $path');

    final stack = path.split('.');
    Schema schema = mainSchema!;

    for (int i = 0; i < stack.length; i++) {
      final _key = stack[i];
      int? _keyNumeric;
      if (schema is SchemaArray) {
        _keyNumeric = object.children.indexWhere((test) => test.id == _key);
        if (_keyNumeric == -1) {
          return const MapEntry(null, null);
        }
        final l = outputValues as List;
        while (l.length != object.children.length) {
          l.length > object.children.length ? l.removeLast() : l.add(null);
        }
        schema = schema.itemsBaseSchema;
      } else {
        final s = schema as SchemaObject;
        schema = s.properties.firstWhere(
          (p) => p.id == _key,
          orElse: () => s.dependentSchemas.values.firstWhere(
            (p) => p.id == _key,
            orElse: () => [
              ...s.dependentSchemas.values,
              // TODO: select the specific oneOf, pass it as parameter
              ...s.dependentSchemas.values.expand((e) => e.oneOf),
            ]
                .expand(
                  (p) => p is SchemaObject ? p.properties : const <Schema>[],
                )
                .firstWhere((p) => p.id == _key),
          ),
        );
      }

      if (i == stack.length - 1) {
        JsonFormValue? item = object[_keyNumeric ?? _key];
        final outputValue = outputValues[_keyNumeric ?? _key];
        final previous = item?.value ?? outputValue;
        if (update) {
          final isNewItem = item == null;
          item = updateFn(item);
          if (isSchemaUpdate) {
            item.parent = object;
            if (isNewItem) object.children.add(item);
            if (outputValue != null) {
              item.value = outputValue;
            }
          } else {
            outputValues[_keyNumeric ?? _key] = item.value;
            _lastEvent = FieldUpdated(
              field: item.field!,
              previousValue: previous,
              newValue: item.value,
            );
            notifyListeners();
          }
        }
        return MapEntry(item, previous);
      } else {
        final tempObject = object[_keyNumeric ?? _key];
        if (tempObject != null) {
          object = tempObject;
        } else {
          final value = JsonFormValue(
            id: _key,
            parent: object,
            schema: schema,
          );
          object.children.add(value);
          object = value;
        }

        Object? outputValue = outputValues[_keyNumeric ?? _key];
        if (outputValue == null) {
          outputValue = schema is SchemaArray ? [] : {};
          outputValues[_keyNumeric ?? _key] = outputValue;
        }
        outputValues = outputValue;
      }
    }
    return MapEntry(rootFormValue, rootFormValue.toJson());
  }

  Map<String, Object?>? submit() {
    final formKey = this.formKey!;
    if (formKey.currentState != null && formKey.currentState!.validate()) {
      formKey.currentState!.save();

      log(rootFormValue.toString());
      return rootFormValue.toJson()! as Map<String, Object?>;
    }
    return null;
  }
}

class JsonFormValue {
  final String id;
  JsonFormValue? parent;
  final List<JsonFormValue> children = [];
  late Schema schema;
  JsonFormField<Object?>? field;
  Object? value;

  /// Whether the dependents have been activated
  bool isDependentsActive = false;

  JsonFormValue({
    required this.id,
    required this.parent,
    required Schema? schema,
    this.value,
  }) {
    if (schema != null) this.schema = schema;
  }

  late final String idKey = JsonFormKeyPath.appendId(parent?.idKey, id);

  List<String> dependentsAddedBy = [];

  JsonFormValue? operator [](Object key) {
    if (key is int) {
      return children[key];
    } else if (key is String) {
      return children.any((e) => e.id == key)
          ? children.firstWhere((e) => e.id == key)
          : null;
    } else {
      throw ArgumentError('key must be either int or String');
    }
  }

  JsonFormValue copyWith({
    required String id,
    required JsonFormValue parent,
  }) {
    final formValue = JsonFormValue(
      id: id,
      parent: parent,
      schema: schema,
      value: value,
    );
    formValue.children.addAll(
      children.map((c) => c.copyWith(id: c.id, parent: formValue)),
    );
    return formValue;
  }

  Object? toJson() {
    if (schema is SchemaArray) {
      if (schema.uiSchema.widget == 'checkboxes') {
        return value;
      }
      return children
          .where((e) => e.field != null)
          .map((e) => e.toJson())
          .toList();
    } else if (schema is SchemaObject) {
      return {
        for (final e in children)
          if (e.field != null) e.id: e.toJson(),
      };
    } else {
      return value;
    }
  }

  void addArrayChildren(Object? value, String id) {
    final schema_ = schema;
    if (schema_ is! SchemaArray)
      throw ArgumentError('schema $schema_ is not an array');
    children.add(
      JsonFormValue(
        id: id,
        parent: this,
        schema: schema_.itemsBaseSchema,
        value: value,
      ),
    );
  }
}
