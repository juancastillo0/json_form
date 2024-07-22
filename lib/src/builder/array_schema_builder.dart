import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/flutter_jsonschema_builder.dart';
import 'package:flutter_jsonschema_builder/src/builder/general_subtitle_widget.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

class ArraySchemaBuilder extends StatefulWidget {
  ArraySchemaBuilder({
    required this.mainSchema,
    required this.schemaArray,
  }) : super(key: Key(schemaArray.idKey));
  final Schema mainSchema;
  final SchemaArray schemaArray;

  @override
  State<ArraySchemaBuilder> createState() => _ArraySchemaBuilderState();
}

class _ArraySchemaBuilderState extends State<ArraySchemaBuilder> {
  SchemaArray get schemaArray => widget.schemaArray;
  int lastItemId = 0;

  String generateItemId() => (lastItemId++).toString();

  @override
  Widget build(BuildContext context) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);

    final widgetBuilder = FormField(
      validator: (_) {
        if (schemaArray.requiredNotNull && schemaArray.items.isEmpty)
          return widgetBuilderInherited.uiConfig.localizedTexts.required();
        return null;
      },
      onSaved: (_) {
        if (schemaArray.items.isEmpty) {
          widgetBuilderInherited.updateObjectData(
            widgetBuilderInherited.data,
            schemaArray.idKey,
            [],
          );
        }
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.infinity),
            GeneralSubtitle(
              field: schemaArray,
              mainSchema: widget.mainSchema,
            ),
            ...schemaArray.items.map((schemaLoop) {
              final index = schemaArray.items.indexOf(schemaLoop);
              return Column(
                key: Key(schemaLoop.idKey),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RemoveItemInherited(
                    removeItem: MapEntry(
                      schemaArray.idKey,
                      () => _removeItem(index),
                    ),
                    schema: schemaLoop,
                    child: FormFromSchemaBuilder(
                      mainSchema: widget.mainSchema,
                      schema: schemaLoop,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
            if (field.hasError) CustomErrorText(text: field.errorText!),
          ],
        );
      },
    );

    return FormSection(
      child: Column(
        children: [
          widgetBuilder,
          if (!schemaArray.isArrayMultipleFile())
            Align(
              alignment: Alignment.centerRight,
              child: widgetBuilderInherited.uiConfig.addItemWidget(
                _addItem,
                schemaArray,
              ),
            ),
        ],
      ),
    );
  }

  void _addItem() {
    setState(() {
      if (schemaArray.items.isEmpty) {
        _addFirstItem();
      } else {
        _addItemFromFirstSchema();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      schemaArray.items.removeAt(index);
    });
  }

  void _addFirstItem() {
    final itemsBaseSchema = schemaArray.itemsBaseSchema;
    if (itemsBaseSchema is Map<String, dynamic>) {
      final newSchema = Schema.fromJson(
        itemsBaseSchema,
        id: generateItemId(),
        parent: schemaArray,
      );

      schemaArray.items.add(newSchema);
    } else {
      schemaArray.items.addAll(
        (itemsBaseSchema as List).cast<Map<String, dynamic>>().map(
              (e) => Schema.fromJson(
                e,
                id: generateItemId(),
                parent: schemaArray,
              ),
            ),
      );
    }
  }

  void _addItemFromFirstSchema() {
    final itemsBaseSchema = schemaArray.itemsBaseSchema is Map<String, dynamic>
        ? schemaArray.itemsBaseSchema
        : (schemaArray.itemsBaseSchema as List).first;
    final newSchema = Schema.fromJson(
      itemsBaseSchema as Map<String, dynamic>,
      id: generateItemId(),
      parent: schemaArray,
    );
    schemaArray.items.add(newSchema);
  }
}
