import 'dart:convert';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:json_form/src/builder/array_schema_builder.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/object_schema_builder.dart';
import 'package:json_form/src/builder/property_schema_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

/// For each field, gives a function that returns the files selected by the user.
/// The inner function is called when adding a file for input fields with format "data-url".
typedef JsonFormFilePickerHandler = Future<List<XFile>?> Function() Function(
  JsonFormField<Object?> field,
);

/// For each field, gives a function that receives a map of values (items) to strings (labels)
/// and returns the selected value, or null if none was selected.
typedef JsonFormSelectPickerHandler
    = Future<Object?> Function(Map<Object?, String> options)? Function(
  JsonFormField<Object?> field,
);

/// For each field, gives a function that receives the new value and returns an error,
/// or null if the validation was successful and no error was found.
/// If the error is an empty String, it will be considered an error in validation,
/// but no error message will be shown.
typedef JsonFormValidatorHandler = String? Function(Object? newValue)? Function(
  JsonFormField<Object?> field,
);

/// Builds a form with [jsonSchema] and configurations from [uiSchema] and [uiConfig].
/// You may use [controller] for added functionalities.
class JsonForm extends StatefulWidget {
  /// Builds a form with [jsonSchema] and configurations from [uiSchema] and [uiConfig].
  /// You may use [controller] for added functionalities.
  const JsonForm({
    super.key,
    required this.jsonSchema,
    required this.onFormDataSaved,
    this.controller,
    this.uiSchema,
    this.uiConfig,
    this.fieldValidator,
    this.fieldSelectPicker,
    this.fieldFilePicker,
  });

  /// The JSON schema to build the form from
  final String jsonSchema;

  /// Callback function to be called when the form is submitted
  final void Function(Object) onFormDataSaved;

  /// The controller to be used for the form.
  /// It can be used to set the initial data, get/set the form data,
  /// subscribe to changes, etc.
  final JsonFormController? controller;

  /// The UI schema with input configurations for each field
  final String? uiSchema;

  /// The UI configuration with global styles, texts, builders and other Flutter configurations
  final JsonFormUiConfig? uiConfig;

  /// A custom validator for each field.
  ///
  /// For each field, gives a function that receives the new value and returns an error,
  /// or null if the validation was successful and no error was found.
  /// If the error is an empty String, it will be considered an error in validation,
  /// but no error message will be shown.
  final JsonFormValidatorHandler? fieldValidator;

  /// A custom select picker for enums and one-of fields.
  ///
  /// For each field, gives a function that receives a map of values (items) to strings (labels)
  /// and returns the selected value, or null if none was selected.
  final JsonFormSelectPickerHandler? fieldSelectPicker;

  /// A file picker, required when using the "data-url" string format .
  ///
  /// For each field, gives a function that returns the files selected by the user.
  /// The inner function is called when adding a file for input fields with format "data-url".
  final JsonFormFilePickerHandler? fieldFilePicker;

  @override
  State<JsonForm> createState() => _JsonFormState();
}

class _JsonFormState extends State<JsonForm> {
  late JsonFormController controller;
  late Schema mainSchema;
  GlobalKey<FormState> get _formKey => controller.formKey!;

  @override
  void initState() {
    super.initState();
    initMainSchema(controllerChanged: true, schemaChanged: true);
  }

  void initMainSchema({
    required bool controllerChanged,
    required bool schemaChanged,
  }) {
    if (controllerChanged) {
      controller = widget.controller ?? JsonFormController(initialData: {});
      controller.formKey ??= GlobalKey<FormState>();
      if (controller.mainSchema != null &&
          (!schemaChanged || widget.jsonSchema.isEmpty)) {
        return;
      }
    }
    final mainSchema = Schema.fromJson(
      json.decode(widget.jsonSchema) as Map<String, Object?>,
      id: kGenesisIdKey,
    );
    final map = widget.uiSchema != null
        ? json.decode(widget.uiSchema!) as Map<String, Object?>
        : null;
    if (map != null) {
      mainSchema.setUiSchema(map, fromOptions: false);
    }
    this.mainSchema = mainSchema;
  }

  @override
  void didUpdateWidget(covariant JsonForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    final schemaChanged = oldWidget.jsonSchema != widget.jsonSchema ||
        oldWidget.uiSchema != widget.uiSchema;
    if (schemaChanged || controllerChanged) {
      initMainSchema(
        controllerChanged: controllerChanged,
        schemaChanged: schemaChanged,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetBuilderInherited(
      controller: controller,
      jsonForm: widget,
      context: context,
      baseConfig: widget.uiConfig,
      child: Builder(
        builder: (context) {
          final widgetBuilderInherited = WidgetBuilderInherited.of(context);
          final uiConfig = widgetBuilderInherited.uiConfig;

          final formChild = Column(
            children: <Widget>[
              if (uiConfig.debugMode)
                TextButton(
                  onPressed: () {
                    inspect(mainSchema);
                  },
                  child: const Text('INSPECT'),
                ),
              _buildHeaderTitle(context),
              FormFromSchemaBuilder(
                mainSchema: mainSchema,
                formValue: null,
              ),
              uiConfig.submitButtonBuilder?.call(onSubmit) ??
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      key: JsonFormKeys.submitButton,
                      onPressed: onSubmit,
                      child: Text(
                        uiConfig.localizedTexts.submit(),
                      ),
                    ),
                  ),
            ],
          );

          return SingleChildScrollView(
            key: JsonFormKeys.scrollView,
            child: uiConfig.formBuilder?.call(_formKey, formChild) ??
                Form(
                  key: _formKey,
                  autovalidateMode: uiConfig.autovalidateMode,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: formChild,
                  ),
                ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final custom = uiConfig.titleAndDescriptionBuilder?.call(mainSchema);
    if (custom != null) return custom;
    if (mainSchema.title == null && mainSchema.description == null) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (mainSchema.title != null)
          SizedBox(
            width: double.infinity,
            child: Text(
              mainSchema.title!,
              style: uiConfig.title,
              textAlign: uiConfig.titleAlign,
            ),
          ),
        const Divider(),
        if (mainSchema.description != null)
          SizedBox(
            width: double.infinity,
            child: Text(
              mainSchema.description!,
              style: uiConfig.description,
              textAlign: uiConfig.titleAlign,
            ),
          ),
      ],
    );
  }

  //  Form methods
  void onSubmit() {
    final data = controller.submit();
    if (data != null) {
      widget.onFormDataSaved(data);
    }
  }
}

class FormFromSchemaBuilder extends StatelessWidget {
  const FormFromSchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.formValue,
    this.schemaObject,
  });
  final Schema mainSchema;
  final JsonFormValue? formValue;
  final SchemaObject? schemaObject;

  @override
  Widget build(BuildContext context) {
    final schema = formValue?.schema ?? mainSchema;
    return JsonFormKeyPath(
      context: context,
      id: formValue?.id ?? schema.id,
      child: Builder(
        builder: (context) {
          if (schema.uiSchema.hidden) {
            return const SizedBox.shrink();
          }
          if (schema is SchemaProperty) {
            return PropertySchemaBuilder(
              mainSchema: mainSchema,
              formValue: formValue!,
            );
          }
          if (schema is SchemaArray) {
            return ArraySchemaBuilder(
              mainSchema: mainSchema,
              schemaArray: schema,
            );
          }

          if (schema is SchemaObject) {
            return ObjectSchemaBuilder(
              mainSchema: mainSchema,
              schemaObject: schema,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class JsonFormKeyPath extends InheritedWidget {
  JsonFormKeyPath({
    super.key,
    required BuildContext context,
    required this.id,
    required super.child,
  }) : parent = maybeGet(context);

  final String id;
  final JsonFormKeyPath? parent;

  String get path => appendId(parent?.path, id);

  static String getPath(BuildContext context, {String id = ''}) {
    return JsonFormKeyPath(
      id: id,
      context: context,
      child: const SizedBox(),
    ).path;
  }

  static String appendId(String? path, String id) {
    return path == null || path.isEmpty || path == kGenesisIdKey
        ? id
        : id.isEmpty
            ? path
            : '$path.$id';
  }

  @override
  bool updateShouldNotify(JsonFormKeyPath oldWidget) {
    return id != oldWidget.id;
  }

  static JsonFormKeyPath? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<JsonFormKeyPath>();

  static JsonFormKeyPath of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No JsonFormKeyPath found in context');
    return result!;
  }

  static JsonFormKeyPath? maybeGet(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<JsonFormKeyPath>()?.widget
          as JsonFormKeyPath?;

  static JsonFormKeyPath get(BuildContext context) {
    final result =
        context.getElementForInheritedWidgetOfExactType<JsonFormKeyPath>();
    assert(result != null, 'No JsonFormKeyPath found in context');
    return result!.widget as JsonFormKeyPath;
  }
}
