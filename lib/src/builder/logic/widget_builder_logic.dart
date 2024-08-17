import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/widget_builder.dart';
import 'package:flutter_jsonschema_builder/src/models/json_form_schema_style.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

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
    JsonFormSchemaUiConfig? uiConfig,
  ) {
    final textTheme = Theme.of(context).textTheme;

    this.uiConfig = JsonFormSchemaUiConfig(
      title: uiConfig?.title ?? textTheme.titleLarge,
      titleAlign: uiConfig?.titleAlign ?? TextAlign.center,
      subtitle: uiConfig?.subtitle ??
          textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      description: uiConfig?.description ?? textTheme.bodyMedium,
      error: uiConfig?.error ??
          TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: textTheme.bodySmall!.fontSize,
          ),
      fieldTitle: uiConfig?.fieldTitle ?? textTheme.bodyMedium,
      label: uiConfig?.label,
      debugMode: uiConfig?.debugMode,
      fieldWrapperBuilder: uiConfig?.fieldWrapperBuilder,
      formSectionBuilder: uiConfig?.formSectionBuilder,
      localizedTexts: uiConfig?.localizedTexts,
      labelPosition: uiConfig?.labelPosition,
      //builders
      addItemBuilder: uiConfig?.addItemBuilder,
      removeItemBuilder: uiConfig?.removeItemBuilder,
      submitButtonBuilder: uiConfig?.submitButtonBuilder,
      addFileButtonBuilder: uiConfig?.addFileButtonBuilder,
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

// ignore: must_be_immutable
class RemoveItemInherited extends InheritedWidget {
  RemoveItemInherited({
    super.key,
    required super.child,
    required this.removeItem,
    required this.schema,
  });

  final MapEntry<String, void Function()> removeItem;
  final Schema schema;
  BuildContext? _context;

  static MapEntry<String, void Function()>? getRemoveItem(
    BuildContext context,
    Schema schema,
  ) {
    final removeItemInherited = RemoveItemInherited.maybeOf(context);

    if (removeItemInherited == null ||
        removeItemInherited._context != null &&
            removeItemInherited._context!.mounted &&
            removeItemInherited._context != context ||
        removeItemInherited.schema != schema) {
      return null;
    }

    removeItemInherited._context = context;
    return removeItemInherited.removeItem;
  }

  static RemoveItemInherited? maybeOf(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<RemoveItemInherited>();
    return result;
  }

  @override
  bool updateShouldNotify(covariant RemoveItemInherited oldWidget) =>
      removeItem != oldWidget.removeItem || schema != oldWidget.schema;
}

class JsonFormController extends ChangeNotifier {
  Schema? mainSchema;
  final Map data;

  JsonFormController({
    required this.data,
    this.mainSchema,
  });

  /// update [data] with key,values from jsonSchema
  dynamic retrieveObjectData(String path) {
    return _transverseObjectData(path, update: false);
  }

  /// update [data] with key,values from jsonSchema
  dynamic updateObjectData(String path, dynamic value) {
    return _transverseObjectData(path, newValue: value, update: true);
  }

  dynamic updateDataInPlace(
    String path,
    dynamic Function(dynamic previousValue) update,
  ) {
    return _transverseObjectData(path, updateFn: update, update: true);
  }

  /// update [data] with key,values from jsonSchema
  dynamic _transverseObjectData(
    String path, {
    required bool update,
    dynamic Function(dynamic previousValue)? updateFn,
    dynamic newValue,
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
          return null;
        }

        final l = object as List;
        while (l.length != schema.items.length) {
          l.length > schema.items.length ? l.removeLast() : l.add(null);
        }
        schema = schema.items[_keyNumeric];
      } else {
        schema =
            (schema as SchemaObject).properties.firstWhere((p) => p.id == _key);
      }

      if (i == stack.length - 1) {
        final previous = object[_keyNumeric ?? _key];
        if (update) {
          if (updateFn != null) {
            object[_keyNumeric ?? _key] = updateFn(previous);
          } else {
            object[_keyNumeric ?? _key] = newValue;
          }
          notifyListeners();
        }
        return previous;
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
  }
}
