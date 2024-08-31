import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/flutter_jsonschema_builder.dart';
import 'package:flutter_jsonschema_builder/src/builder/general_subtitle_widget.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/fields/shared.dart';
import 'package:flutter_jsonschema_builder/src/helpers/helpers.dart';
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
  int lastItemId = 1;
  bool showItems = true;

  String generateItemId() => (lastItemId++).toString();

  @override
  Widget build(BuildContext context) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final uiConfig = widgetBuilderInherited.uiConfig;

    final widgetBuilder = FormField(
      validator: (_) {
        final array = widgetBuilderInherited.controller.retrieveObjectData(
          schemaArray.idKey,
        ) as List?;
        return uiConfig.localizedTexts.arrayPropertiesError(
          schemaArray.arrayProperties,
          array ?? [],
        );
      },
      onSaved: (_) {
        if (schemaArray.items.isEmpty) {
          // TODO:  && schemaArray.requiredNotNull
          widgetBuilderInherited.controller.updateObjectData(
            schemaArray.idKey,
            [],
          );
        }
      },
      builder: (field) {
        if (schemaArray.uiSchema.widget == 'checkboxes') {
          final schema = schemaArray.itemsBaseSchema as SchemaProperty;
          final options = schema.enumm ?? schema.numberProperties.options();
          int _index = 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GeneralSubtitle(
                field: schemaArray,
                mainSchema: widget.mainSchema,
              ),
              Wrap(
                children: options.map((option) {
                  final index = _index++;
                  final title = schema.uiSchema.enumNames != null
                      ? schema.uiSchema.enumNames![index]
                      : option.toString();
                  return CheckboxListTile(
                    key: Key('JsonForm_item_${schemaArray.idKey}_$index'),
                    title: Text(title),
                    value: field.value != null &&
                        (field.value as List).contains(option),
                    onChanged: (_) {
                      selectCheckbox(field, option);
                    },
                  );
                }).toList(growable: false),
              ),
              if (field.hasError) CustomErrorText(text: field.errorText!),
            ],
          );
        }

        int _index = 0;
        final items = schemaArray.items.map((schemaLoop) {
          final index = _index++;
          return Column(
            key: Key('JsonForm_item_${schemaLoop.idKey}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (uiConfig.labelPosition == LabelPosition.table)
                    Text(
                      schemaLoop.titleOrId,
                      style: uiConfig.label,
                    ),
                  const Spacer(),
                  const SizedBox(height: 5),
                  if (schemaArray.uiSchema.copyable)
                    uiConfig.copyItemWidget(
                      schemaLoop,
                      () => _copyItem(index),
                    ),
                  if (schemaArray.uiSchema.removable)
                    uiConfig.removeItemWidget(
                      schemaLoop,
                      () => _removeItem(index),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0, left: 5.0),
                // TODO: improve this, necessary for ReorderableListView
                child: WidgetBuilderInherited(
                  controller: widgetBuilderInherited.controller,
                  customPickerHandler:
                      widgetBuilderInherited.customPickerHandler,
                  customValidatorHandler:
                      widgetBuilderInherited.customValidatorHandler,
                  fileHandler: widgetBuilderInherited.fileHandler,
                  child: FormFromSchemaBuilder(
                    mainSchema: widget.mainSchema,
                    schema: schemaLoop,
                  ),
                )..uiConfig = widgetBuilderInherited.uiConfig,
              ),
            ],
          );
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.infinity),
            GeneralSubtitle(
              field: schemaArray,
              mainSchema: widget.mainSchema,
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    showItems = !showItems;
                  });
                },
                icon: showItems
                    ? const Icon(Icons.arrow_drop_up_outlined)
                    : const Icon(Icons.arrow_drop_down_outlined),
              ),
            ),
            if (!showItems)
              const SizedBox()
            else if (schemaArray.uiSchema.orderable)
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final pItem = schemaArray.items[oldIndex];
                    schemaArray.items[oldIndex] = schemaArray.items[newIndex];
                    schemaArray.items[newIndex] = pItem;

                    WidgetBuilderInherited.of(context)
                        .controller
                        .updateDataInPlace(
                      schemaArray.idKey,
                      (array) {
                        if (array is! List) return;
                        final prev = array[oldIndex];
                        array[oldIndex] = array[newIndex];
                        array[newIndex] = prev;
                      },
                    );
                  });
                },
                children: items.toList(growable: false),
              )
            else
              ...items,
            if (field.hasError) CustomErrorText(text: field.errorText!),
          ],
        );
      },
    );

    return FormSection(
      child: Column(
        children: [
          widgetBuilder,
          if (!schemaArray.isArrayMultipleFile() &&
              schemaArray.uiSchema.addable &&
              schemaArray.uiSchema.widget != 'checkboxes')
            Align(
              alignment: Alignment.centerRight,
              child: uiConfig.addItemWidget(
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
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
            schemaArray.idKey,
            (array) => (array as List? ?? [])..add(null),
          );

      final newItem =
          schemaArray.itemsBaseSchema.copyWith(id: generateItemId());
      schemaArray.items.add(newItem);
    });
  }

  void _removeItem(int index) {
    setState(() {
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
            schemaArray.idKey,
            (array) => (array as List? ?? [])..removeAt(index),
          );
      schemaArray.items.removeAt(index);
    });
  }

  void _copyItem(int index) {
    setState(() {
      final schemaLoop = schemaArray.items[index];
      final widgetBuilderInherited = WidgetBuilderInherited.of(context);
      final item = widgetBuilderInherited.controller
          .retrieveObjectData(schemaArray.idKey) as List?;
      final newItem = copyJson(item![index]);
      widgetBuilderInherited.controller.updateDataInPlace(
        schemaArray.idKey,
        (array) => (array as List? ?? [])..add(newItem),
      );
      schemaArray.items.add(
        schemaLoop.copyWith(id: generateItemId()),
      );
    });
  }

  void selectCheckbox(FormFieldState<Object?> field, Object? option) {
    setState(() {
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
        schemaArray.idKey,
        (a) {
          final valueList = (a as List?)?.toList() ?? [];
          final i = valueList.indexOf(option);
          if (i != -1) {
            valueList.removeAt(i);
            _removeItem(i);
          } else {
            valueList.add(option);
            _addItem();
          }
          field.didChange(valueList);
          return valueList;
        },
      );
    });
  }
}
