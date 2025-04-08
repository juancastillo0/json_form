import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/general_subtitle_widget.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class ArraySchemaBuilder extends StatefulWidget {
  const ArraySchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.schemaArray,
  });
  final Schema mainSchema;
  final SchemaArray schemaArray;

  @override
  State<ArraySchemaBuilder> createState() => _ArraySchemaBuilderState();
}

class _ArraySchemaBuilderState extends State<ArraySchemaBuilder>
    implements JsonFormField<List<Object?>> {
  late FormFieldState<List<Object?>> field;
  late final JsonFormValue formValue;
  SchemaArray get schemaArray => widget.schemaArray;
  bool showItems = true;

  @override
  String get idKey => formValue.idKey;

  bool get isCheckboxes => schemaArray.uiSchema.widget == 'checkboxes';
  List<Object?>? _initialValue;

  @override
  void initState() {
    super.initState();
    formValue = PrivateJsonFormController.setField(context, schemaArray, this);
    formValue.value ??= [];
    _initialValue = formValue.value! as List;
    if (_initialValue!.isNotEmpty) {
      // update children
      value = _initialValue!;
    }
  }

  @override
  void dispose() {
    // TODO: clean up
    // if (schemaArray.formField == this) {
    //   schemaArray.formField = null;
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final uiConfig = widgetBuilderInherited.uiConfig;

    final widgetBuilder = FormField<List<Object?>>(
      validator: (_) {
        return uiConfig.localizedTexts
            .arrayPropertiesError(schemaArray.arrayProperties, value);
      },
      initialValue: _initialValue,
      builder: (field) {
        this.field = field;
        return Focus(
          focusNode: focusNode,
          autofocus: schemaArray.uiSchema.autofocus,
          child: Builder(
            builder: (context) {
              if (isCheckboxes) {
                final schema = schemaArray.itemsBaseSchema as SchemaProperty;
                final options =
                    schema.enumm ?? schema.numberProperties.options();
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
                          key: JsonFormKeys.arrayCheckboxItem(idKey, index),
                          title: Text(
                            title,
                            style: uiConfig.fieldInput,
                          ),
                          value: field.value != null &&
                              field.value!.contains(option),
                          onChanged: (_) {
                            selectCheckbox(option);
                          },
                        );
                      }).toList(growable: false),
                    ),
                    if (field.hasError) CustomErrorText(text: field.errorText!),
                  ],
                );
              }

              int _index = 0;
              final items = formValue.children.map((item) {
                final index = _index++;
                final idKey = JsonFormKeyPath.appendId(this.idKey, item.id);

                final horizontal = item.schema is SchemaProperty;
                final input = Padding(
                  padding: const EdgeInsets.only(bottom: 5.0, left: 5.0),
                  child: WidgetBuilderInherited(
                    controller: widgetBuilderInherited.controller,
                    jsonForm: widgetBuilderInherited.jsonForm,
                    uiConfig: widgetBuilderInherited.uiConfig,
                    context: context,
                    child: FormFromSchemaBuilder(
                      mainSchema: widget.mainSchema,
                      formValue: item,
                    ),
                  ),
                );
                final row = Row(
                  key: horizontal ? JsonFormKeys.arrayItem(idKey) : null,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (uiConfig.labelPosition == LabelPosition.table)
                      Text(
                        '${index + 1}.',
                        style: uiConfig.fieldLabel,
                      ),
                    if (horizontal) Expanded(child: input) else const Spacer(),
                    const SizedBox(height: 5),
                    if (schemaArray.uiSchema.copyable)
                      uiConfig.copyItemWidget(
                        idKey,
                        () => _copyItem(index),
                        onlyIcon: horizontal,
                      ),
                    if (schemaArray.uiSchema.removable)
                      uiConfig.removeItemWidget(
                        idKey,
                        () => _removeItem(index),
                        onlyIcon: horizontal,
                      ),
                    if (schemaArray.uiSchema.orderable)
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                  ],
                );
                if (horizontal) {
                  return row;
                }
                return Column(
                  key: JsonFormKeys.arrayItem(idKey),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    row,
                    if (!horizontal) input,
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
                      key: JsonFormKeys.showOrHideItems(idKey),
                      tooltip: showItems
                          ? uiConfig.localizedTexts.hideItems()
                          : uiConfig.localizedTexts.showItems(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          showItems = !showItems;
                        });
                      },
                      icon: Row(
                        children: [
                          Text(
                            formValue.children.length.toString(),
                            style: uiConfig.subtitle,
                          ),
                          if (showItems)
                            const Icon(Icons.arrow_drop_up_outlined)
                          else
                            const Icon(Icons.arrow_drop_down_outlined),
                        ],
                      ),
                    ),
                  ),
                  if (!showItems)
                    const SizedBox()
                  else if (schemaArray.uiSchema.orderable)
                    ReorderableListView(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: reorder,
                      children: items.toList(growable: false),
                    )
                  else
                    ...items,
                  if (field.hasError) CustomErrorText(text: field.errorText!),
                ],
              );
            },
          ),
        );
      },
    );

    return FormSection(
      child: Column(
        children: [
          widgetBuilder,
          if (!schemaArray.isArrayMultipleFile() &&
              schemaArray.uiSchema.addable &&
              !isCheckboxes)
            Align(
              alignment: Alignment.centerRight,
              child: uiConfig.addItemWidget(formValue, _addItem),
            ),
        ],
      ),
    );
  }

  void _addItem() {
    setState(() {
      formValue.addArrayChild(null);
    });
  }

  void _removeItem(int index) {
    setState(() {
      formValue.children.removeAt(index);

      /// cleans up the output data in the controller
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
            idKey,
            (a) => a is List && a.length > index ? (a..removeAt(index)) : a,
          );
    });
  }

  void _copyItem(int index) {
    setState(() {
      formValue.addArrayChild(null, baseValue: formValue.children[index]);
    });
  }

  void reorder(int oldIndex, int newIndex) {
    setState(() {
      final toRemove = newIndex > oldIndex ? oldIndex : oldIndex + 1;
      final array = formValue.children;
      array.insert(newIndex, array[oldIndex]);
      array.removeAt(toRemove);
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
        idKey,
        (a) {
          if (a is List) {
            a.insert(newIndex, a[oldIndex]);
            a.removeAt(toRemove);
          }
          return a;
        },
      );
    });
  }

  void selectCheckbox(Object? option) {
    setState(() {
      WidgetBuilderInherited.of(context).controller.updateDataInPlace(
        idKey,
        (a) {
          final valueList = (a as List?)?.toList() ?? [];
          final i = valueList.indexOf(option);
          if (i != -1) {
            valueList.removeAt(i);
          } else {
            valueList.add(option);
          }
          field.didChange(valueList);
          return valueList;
        },
      );
    });
  }

  @override
  List<Object?> get value =>
      isCheckboxes ? field.value! : formValue.toJson()! as List<Object?>;

  @override
  final focusNode = FocusNode();

  @override
  JsonSchemaInfo get property => schemaArray;

  @override
  set value(List<Object?> newValue) {
    WidgetBuilderInherited.get(context).controller.updateData(idKey, newValue);
    if (isCheckboxes) {
      field.didChange(newValue);
      formValue.value = newValue;
    } else {
      formValue.syncChildrenValues(newValue);
    }
    setState(() {});
  }
}
