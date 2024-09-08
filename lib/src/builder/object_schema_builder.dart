import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/general_subtitle_widget.dart';
import 'package:json_form/src/builder/logic/object_schema_logic.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class ObjectSchemaBuilder extends StatefulWidget {
  const ObjectSchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.schemaObject,
  });

  final Schema mainSchema;
  final SchemaObject schemaObject;

  @override
  State<ObjectSchemaBuilder> createState() => _ObjectSchemaBuilderState();
}

class _ObjectSchemaBuilderState extends State<ObjectSchemaBuilder> {
  late SchemaObject _schemaObject;

  @override
  void initState() {
    super.initState();
    _schemaObject = widget.schemaObject;
  }

  @override
  void didUpdateWidget(covariant ObjectSchemaBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schemaObject != widget.schemaObject) {
      _schemaObject = widget.schemaObject;
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = _schemaObject.properties;
    final directionality = Directionality.of(context);
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final isTableLabel =
        widgetBuilderInherited.uiConfig.labelPosition == LabelPosition.table;

    final Set<Schema> dependentSchemas = {};
    for (final property in properties) {
      if (property is SchemaProperty && property.dependents?.right != null) {
        dependentSchemas.add(property.dependents!.right!);
      }
    }

    return ObjectSchemaInherited(
      schemaObject: _schemaObject,
      listen: (value) {
        if (value is ObjectSchemaDependencyEvent) {
          setState(() => _schemaObject = value.schemaObject);
        }
      },
      child: FormSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isTableLabel || widget.schemaObject.parent is! SchemaArray)
              GeneralSubtitle(
                field: widget.schemaObject,
                mainSchema: widget.mainSchema,
              ),
            if (isTableLabel)
              Table(
                children: [
                  ...properties.whereType<SchemaProperty>().expand(
                    (e) {
                      final r = e.dependents?.right;
                      return r != null && e.isDependentsActive
                          ? [
                              e,
                              if (r is SchemaObject) ...r.properties else r,
                            ]
                          : [e];
                    },
                  ).map(
                    (e) {
                      final title = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          Text(
                            e.titleOrId,
                            style: widgetBuilderInherited.uiConfig.label,
                          ),
                          if (e.description != null)
                            Text(
                              e.description!,
                              style:
                                  widgetBuilderInherited.uiConfig.description,
                            ),
                        ],
                      );
                      return TableRow(
                        children: [
                          if (directionality == TextDirection.ltr) title,
                          FormFromSchemaBuilder(
                            schemaObject: widget.schemaObject,
                            mainSchema: widget.mainSchema,
                            schema: e,
                          ),
                          if (directionality == TextDirection.rtl) title,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ...properties
                .where(
                  (p) =>
                      !isTableLabel ||
                      p is! SchemaProperty && !dependentSchemas.contains(p),
                )
                .map(
                  (e) => FormFromSchemaBuilder(
                    schemaObject: widget.schemaObject,
                    mainSchema: widget.mainSchema,
                    schema: e,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
