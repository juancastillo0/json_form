// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:json_form/src/builder/array_schema_builder.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/object_schema_builder.dart';
import 'package:json_form/src/builder/property_schema_builder.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';

import '../models/models.dart';

typedef FileHandler = Map<String, Future<List<XFile>?> Function()?> Function();
typedef CustomPickerHandler = Map<String, Future<dynamic> Function(Map data)>
    Function();

typedef CustomValidatorHandler = Map<String, String? Function(dynamic)?>
    Function();

class JsonForm extends StatefulWidget {
  const JsonForm({
    super.key,
    required this.jsonSchema,
    required this.onFormDataSaved,
    this.controller,
    this.uiSchema,
    this.fileHandler,
    this.uiConfig,
    this.customPickerHandler,
    this.customValidatorHandler,
  });

  final String jsonSchema;
  final void Function(dynamic) onFormDataSaved;

  final JsonFormController? controller;
  final String? uiSchema;
  final FileHandler? fileHandler;
  final JsonFormSchemaUiConfig? uiConfig;
  final CustomPickerHandler? customPickerHandler;
  final CustomValidatorHandler? customValidatorHandler;

  @override
  _JsonFormState createState() => _JsonFormState();
}

class _JsonFormState extends State<JsonForm> {
  Schema get mainSchema => controller.mainSchema!;
  late JsonFormController controller;
  final _formKey = GlobalKey<FormState>();

  _JsonFormState();

  @override
  void initState() {
    super.initState();
    initMainSchema(controllerChanged: true);
  }

  void initMainSchema({required bool controllerChanged}) {
    if (controllerChanged) {
      controller = widget.controller ?? JsonFormController(data: {});
      if (controller.mainSchema != null) {
        return;
      }
    }
    final mainSchema = Schema.fromJson(
      json.decode(widget.jsonSchema),
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
    if (oldWidget.jsonSchema != widget.jsonSchema ||
        oldWidget.uiSchema != widget.uiSchema ||
        controllerChanged) {
      initMainSchema(
        controllerChanged: controllerChanged,
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
      child: Builder(
        builder: (context) {
          final widgetBuilderInherited = WidgetBuilderInherited.of(context);
          final uiConfig = widgetBuilderInherited.uiConfig;

          return SingleChildScrollView(
            key: const Key('JsonForm_scrollView'),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(15.0),
                child: Column(
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
                      schema: mainSchema,
                    ),
                    const SizedBox(height: 20),
                    uiConfig.submitButtonBuilder == null
                        ? ElevatedButton(
                            key: const Key('JsonForm_submitButton'),
                            onPressed: () => onSubmit(widgetBuilderInherited),
                            child: Text(
                              uiConfig.localizedTexts.submit(),
                            ),
                          )
                        : uiConfig.submitButtonBuilder!(
                            () => onSubmit(widgetBuilderInherited),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    )..setJsonFormSchemaStyle(context, widget.uiConfig);
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Text(
            mainSchema.title,
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
  void onSubmit(WidgetBuilderInherited widgetBuilderInherited) {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState?.save();

      final data = widgetBuilderInherited.controller.data;
      log(data.toString());
      widget.onFormDataSaved(data);
    }
  }
}

class FormFromSchemaBuilder extends StatelessWidget {
  const FormFromSchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.schema,
    this.schemaObject,
  });
  final Schema mainSchema;
  final Schema schema;
  final SchemaObject? schemaObject;

  @override
  Widget build(BuildContext context) {
    if (schema.uiSchema.hidden) {
      return const SizedBox.shrink();
    }
    if (schema is SchemaProperty) {
      return PropertySchemaBuilder(
        mainSchema: mainSchema,
        schemaProperty: schema as SchemaProperty,
      );
    }
    if (schema is SchemaArray) {
      return ArraySchemaBuilder(
        mainSchema: mainSchema,
        schemaArray: schema as SchemaArray,
      );
    }

    if (schema is SchemaObject) {
      return ObjectSchemaBuilder(
        mainSchema: mainSchema,
        schemaObject: schema as SchemaObject,
      );
    }

    return const SizedBox.shrink();
  }
}
