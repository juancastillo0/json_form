import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/helpers/helpers.dart';
import 'package:json_form/src/models/json_form_ui_config.dart';
import 'package:json_form/src/models/models.dart';

class WidgetBuilderInherited extends InheritedWidget {
  WidgetBuilderInherited({
    super.key,
    required this.controller,
    required super.child,
    required this.jsonForm,
    required BuildContext context,
    JsonFormUiConfig? baseConfig,
    JsonFormUiConfig? uiConfig,
  }) : uiConfig = uiConfig ??
            JsonFormUiConfig.fromContext(
              context,
              baseConfig: baseConfig,
            );
  final JsonFormController controller;
  final JsonForm jsonForm;
  JsonFormFilePickerHandler? get fieldFilePicker => jsonForm.fieldFilePicker;
  JsonFormSelectPickerHandler? get fieldSelectPicker =>
      jsonForm.fieldSelectPicker;
  JsonFormValidatorHandler? get fieldValidator => jsonForm.fieldValidator;
  final JsonFormUiConfig uiConfig;

  // TODO: implement not-required object
  // TODO: validate nullable and required combinations

  @override
  bool updateShouldNotify(covariant WidgetBuilderInherited oldWidget) =>
      controller.mainSchema != oldWidget.controller.mainSchema ||
      uiConfig != oldWidget.uiConfig ||
      fieldValidator != oldWidget.fieldValidator ||
      fieldSelectPicker != oldWidget.fieldSelectPicker ||
      fieldFilePicker != oldWidget.fieldFilePicker;

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

/// The event that is triggered when a field is updated
class JsonFormUpdate<T> {
  /// The field that was updated
  final JsonFormField<T> field;

  /// The new value of the field
  final Object? newValue;

  /// The previous value of the field
  final Object? previousValue;

  /// The event that is triggered when a field is updated
  const JsonFormUpdate({
    required this.field,
    required this.newValue,
    required this.previousValue,
  });
}

/// The controller for the form.
/// Can be used to validate and [submit] the form, subscribe or [addListener] to the form's updates
/// or the [lastEvent], and [retrieveField]s to access their values or trigger actions
class JsonFormController extends ChangeNotifier {
  /// The main (root) value of the form. Contains all the fields and values
  JsonFormValue _rootFormValue;

  /// The main (root) data of the form.
  /// Contains all current values by the user and maintains the state
  Object rootOutputData;

  /// The main (root) schema of the form
  // TODO: extract private apis
  Schema? _mainSchema;

  /// The main [Form] key used to validate and submit the form
  GlobalKey<FormState>? formKey;

  /// The last field updated event.
  /// Can be used with [addListener] to listen for changes in the form
  JsonFormUpdate<Object?>? get lastEvent => _lastEvent;
  JsonFormUpdate<Object?>? _lastEvent;

  /// The controller for the form
  JsonFormController({
    required Object initialData,
    this.formKey,
  })  : rootOutputData = initialData,
        _rootFormValue = JsonFormValue(
          parent: null,
          schema: null,
          id: '',
        );

  /// Validates the form and returns the output data if valid
  Object? submit() {
    final formKey = this.formKey!;
    if (formKey.currentState != null && formKey.currentState!.validate()) {
      formKey.currentState!.save();

      log(_rootFormValue.toString());
      return _rootFormValue.toJson();
    }
    return null;
  }

  /// Retrieves the field controller for [path].
  /// Can be used to trigger get/update the value, retrieve/request focus
  /// and other functionalities for the field.
  JsonFormField<Object?>? retrieveField(String path) {
    return _transverseObjectData(path).key?.field;
  }

  /// Transverses [_rootFormValue] until [path] and conditionally applies an [update]
  MapEntry<JsonFormValue?, Object?> _transverseObjectData(
    String path, {
    JsonFormValue Function(JsonFormValue? previousValue)? updateFn,
    bool isSchemaUpdate = false,
  }) {
    final update = updateFn != null;
    JsonFormValue object = _rootFormValue;
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
            _lastEvent = JsonFormUpdate(
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
          if (schema is SchemaArray) {
            outputValue = outputValue is List ? outputValue : [];
          } else {
            assert(schema is SchemaObject);
            outputValue =
                outputValue is Map ? outputValue : <String, Object?>{};
          }
          outputValues[_keyNumeric ?? _key] = outputValue;
        }
        outputValues = outputValue;
      }
    }
    return MapEntry(_rootFormValue, _rootFormValue.toJson());
  }
}

extension PrivateJsonFormController on JsonFormController {
  /// The main (root) schema of the form
  Schema? get mainSchema => _mainSchema;
  @visibleForTesting
  set mainSchema(Schema? newSchema) => _mainSchema = newSchema;

  /// Retrieves [_rootFormValue]'s [path]
  Object? retrieveData(String path) {
    return _transverseObjectData(path).value;
  }

  /// Update [_rootFormValue]'s [path] with [value], returning the previous value
  Object? updateData(String path, Object? value) {
    return updateDataInPlace(path, (_) => value);
  }

  /// Update [_rootFormValue]'s [path] with the value returned in [update]
  Object? updateDataInPlace(
    String path,
    Object? Function(Object? previousValue) update,
  ) {
    return _transverseObjectData(
      path,
      updateFn: (v) => v!..value = update(v.value),
    ).value;
  }

  static JsonFormValue setField(
    BuildContext context,
    Schema schema,
    JsonFormField<Object?> field,
  ) {
    final controller = WidgetBuilderInherited.get(context).controller;
    final path = JsonFormKeyPath.getPath(context);
    if (path == '') {
      controller._mainSchema = schema;
      return controller._rootFormValue = JsonFormValue(
        parent: null,
        schema: schema,
        id: '',
        field: field,
        value: controller.rootOutputData,
      );
    } else {
      return controller._transverseObjectData(
        path,
        isSchemaUpdate: true,
        updateFn: (v) {
          v ??= JsonFormValue(id: schema.id, parent: null, schema: null);
          return v
            ..schema = schema
            ..field = field;
        },
      ).key!;
    }
  }
}

class JsonFormValue {
  final String id;
  JsonFormValue? parent;
  final List<JsonFormValue> children = [];
  int _lastItemId = 1;
  String _generateItemId() => (_lastItemId++).toString();
  late Schema schema;
  JsonFormField<Object?>? field;
  Object? value;

  late final String idKey = JsonFormKeyPath.appendId(parent?.idKey, id);

  /// Whether the dependents have been activated
  bool isDependentsActive = false;
  List<String> dependentsAddedBy = [];

  /// Whether the field is required because another field has a value
  bool requiredFromDependent = false;

  /// Whether the field is required and not nullable
  bool get isRequiredNotNull =>
      (schema.requiredProperty || requiredFromDependent) && !schema.nullable;

  JsonFormValue({
    required this.id,
    required this.parent,
    required Schema? schema,
    this.value,
    this.field,
  }) {
    if (schema != null) this.schema = schema;
  }

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
      value: copyJson(value),
    );
    formValue.children.addAll(
      children.map((c) => c.copyWith(id: c.id, parent: formValue)),
    );
    formValue._lastItemId = _lastItemId;
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

  void addArrayChild(Object? value, {JsonFormValue? baseValue}) {
    final schema_ = schema;
    if (schema_ is! SchemaArray)
      throw ArgumentError('schema $schema_ is not an array');
    final JsonFormValue newValue;
    if (baseValue != null) {
      newValue = baseValue.copyWith(
        id: _generateItemId(),
        parent: this,
      );
    } else {
      newValue = JsonFormValue(
        id: _generateItemId(),
        parent: this,
        schema: schema_.itemsBaseSchema,
        value: value,
      );
    }
    children.add(newValue);
  }
}
