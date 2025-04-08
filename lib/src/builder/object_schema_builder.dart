import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/general_subtitle_widget.dart';
import 'package:json_form/src/builder/logic/object_schema_logic.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class ObjectSchemaBuilder extends StatefulWidget {
  ObjectSchemaBuilder({
    Key? key,
    required this.mainSchema,
    required this.schemaObject,
    // TODO: validate array key
  }) : super(key: key ?? ValueKey(schemaObject));

  final Schema mainSchema;
  final SchemaObject schemaObject;

  @override
  State<ObjectSchemaBuilder> createState() => _ObjectSchemaBuilderState();
}

class _ObjectSchemaBuilderState extends State<ObjectSchemaBuilder>
    implements JsonFormField<Map<String, Object?>> {
  late SchemaObject _schemaObject;
  late final JsonFormValue formValue;

  @override
  void initState() {
    super.initState();
    _schemaObject = widget.schemaObject;
    formValue =
        PrivateJsonFormController.setField(context, _schemaObject, this);
    syncValues();
  }

  @override
  void didUpdateWidget(covariant ObjectSchemaBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schemaObject != widget.schemaObject) {
      _schemaObject = widget.schemaObject;
      syncValues();
    }
  }

  void syncValues() {
    formValue.children.removeWhere(
      (c) =>
          _schemaObject.properties.every((p) => p.id != c.id) &&
              c.dependentsAddedBy.isEmpty ||
          c.parent?.schema != _schemaObject,
    );
    final added = Set.of(formValue.children.map((c) => c.id));
    formValue.children.addAll(
      _schemaObject.properties.where((p) => !added.contains(p.id)).map((e) {
        return JsonFormValue(
          id: e.id,
          parent: formValue,
          schema: e,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties =
        _schemaObject.properties.where((p) => !p.uiSchema.hidden);
    final directionality = Directionality.of(context);
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final uiConfig = widgetBuilderInherited.uiConfig;
    final isTableLabel = uiConfig.labelPosition == LabelPosition.table;
    final objectKey = formValue.idKey;

    final Set<Schema> dependentSchemas = {};
    for (final property in properties) {
      if (property is SchemaProperty && property.dependents?.schema != null) {
        dependentSchemas.add(property.dependents!.schema!);
      }
    }
    final widths = _schemaObject.properties
        .where((p) => !p.uiSchema.hidden)
        .map((e) => e.uiSchema.width)
        .toSet();

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isTableLabel || widget.schemaObject.parent is! SchemaArray)
          GeneralSubtitle(
            field: widget.schemaObject,
            mainSchema: widget.mainSchema,
          ),
        if (isTableLabel)
          Table(
            columnWidths: widths.length == 1 && widths.first != null
                ? {1: FixedColumnWidth(widths.first!)}
                : null,
            children: [
              ...formValue.children
                  .where((c) => c.schema is SchemaProperty)
                  .expand(
                (e) {
                  final r = (e.schema as SchemaProperty).dependents?.schema;
                  return r != null && e.isDependentsActive
                      ? [
                          e,
                          ...((r is SchemaObject) ? r.properties : [r]).map(
                            (s) => JsonFormValue(
                              id: s.id,
                              parent: formValue,
                              schema: s,
                            ),
                          ),
                        ]
                      : [e];
                },
              ).map(
                (e) {
                  final s = e.schema;
                  final title = uiConfig.titleAndDescriptionBuilder?.call(s) ??
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          Text(
                            uiConfig.schemaTitleOrId(s),
                            style: uiConfig.fieldLabel,
                          ),
                          if (s.description != null)
                            Text(
                              s.description!,
                              style: uiConfig.description,
                            ),
                        ],
                      );
                  return TableRow(
                    key: JsonFormKeys.objectProperty(
                      JsonFormKeyPath.appendId(objectKey, e.id),
                    ),
                    children: [
                      if (directionality == TextDirection.ltr) title,
                      FormFromSchemaBuilder(
                        schemaObject: widget.schemaObject,
                        mainSchema: widget.mainSchema,
                        formValue: e,
                      ),
                      if (directionality == TextDirection.rtl) title,
                    ],
                  );
                },
              ),
            ],
          ),
        ...formValue.children
            .where(
              (p) =>
                  !isTableLabel ||
                  p.schema is! SchemaProperty &&
                      !dependentSchemas.contains(p.schema),
            )
            .map(
              (e) => FormFromSchemaBuilder(
                key: JsonFormKeys.objectProperty(
                  JsonFormKeyPath.appendId(objectKey, e.id),
                ),
                schemaObject: widget.schemaObject,
                mainSchema: widget.mainSchema,
                formValue: e,
              ),
            ),
      ],
    );

    return ObjectSchemaInherited(
      schemaObject: _schemaObject,
      listen: (value) {
        if (value is ObjectSchemaDependencyEvent) {
          setState(() => _schemaObject = value.schemaObject);
        }
      },
      child: _schemaObject.parent == null ? child : FormSection(child: child),
    );
  }

  @override
  Map<String, Object?> get value => formValue.toJson()! as Map<String, Object?>;
  @override
  final FocusNode focusNode = FocusNode();
  @override
  String get idKey => formValue.idKey;
  @override
  JsonSchemaInfo get property => widget.schemaObject;

  @override
  set value(Map<String, Object?> newValue) {
    WidgetBuilderInherited.get(context).controller.updateData(idKey, newValue);
    formValue.syncChildrenValues(newValue);
    setState(() {});
  }
}
