import 'dart:convert';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:json_form/src/builder/array_schema_builder.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/object_schema_builder.dart';
import 'package:json_form/src/builder/property_schema_builder.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';
import 'package:json_form/src/models/models.dart';

typedef FileHandler = Map<String, Future<List<XFile>?> Function()?> Function();
typedef CustomPickerHandler
    = Map<String, Future<Object?> Function(Map<Object?, Object?> data)>
        Function();

typedef CustomValidatorHandler = Map<String, String? Function(Object?)?>
    Function();

class JsonForm extends StatefulWidget {
  const JsonForm({
    super.key,
    required this.jsonSchema,
    required this.onFormDataSaved,
    this.controller,
    this.uiSchema,
    this.uiConfig,
    this.fileHandler,
    this.customPickerHandler,
    this.customValidatorHandler,
  });

  final String jsonSchema;
  final void Function(Object) onFormDataSaved;

  final JsonFormController? controller;
  final String? uiSchema;
  final JsonFormSchemaUiConfig? uiConfig;
  final FileHandler? fileHandler;
  final CustomPickerHandler? customPickerHandler;
  final CustomValidatorHandler? customValidatorHandler;

  @override
  State<JsonForm> createState() => _JsonFormState();
}

class _JsonFormState extends State<JsonForm> {
  late JsonFormController controller;
  Schema get mainSchema => controller.mainSchema!;
  GlobalKey<FormState> get _formKey => controller.formKey!;

  _JsonFormState();

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
      controller = widget.controller ?? JsonFormController(data: {});
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
    controller.mainSchema = mainSchema;
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
      fileHandler: widget.fileHandler,
      customPickerHandler: widget.customPickerHandler,
      customValidatorHandler: widget.customValidatorHandler,
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
                      key: const Key('JsonForm_submitButton'),
                      onPressed: onSubmit,
                      child: Text(
                        uiConfig.localizedTexts.submit(),
                      ),
                    ),
                  ),
            ],
          );

          return SingleChildScrollView(
            key: const Key('JsonForm_scrollView'),
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

  static String ofPath(BuildContext context, {String id = ''}) {
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
