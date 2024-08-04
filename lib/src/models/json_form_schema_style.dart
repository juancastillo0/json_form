import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/flutter_jsonschema_builder.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

class JsonFormSchemaUiConfig {
  const JsonFormSchemaUiConfig({
    this.fieldTitle,
    this.error,
    this.title,
    this.titleAlign,
    this.subtitle,
    this.description,
    this.label,
    this.addItemBuilder,
    this.removeItemBuilder,
    this.submitButtonBuilder,
    this.addFileButtonBuilder,
    this.formSectionBuilder,
    this.fieldWrapperBuilder,
    LocalizedTexts? localizedTexts,
    bool? debugMode,
    LabelPosition? labelPosition,
  })  : localizedTexts = localizedTexts ?? const LocalizedTexts(),
        debugMode = debugMode ?? false,
        labelPosition = labelPosition ?? LabelPosition.fieldInputDecoration;

  final TextStyle? fieldTitle;
  final TextStyle? error;
  final TextStyle? title;
  final TextAlign? titleAlign;
  final TextStyle? subtitle;
  final TextStyle? description;
  final TextStyle? label;
  final LocalizedTexts localizedTexts;
  final bool debugMode;
  final LabelPosition labelPosition;

  final Widget Function(VoidCallback onPressed, String key)? addItemBuilder;
  final Widget Function(VoidCallback onPressed, String key)? removeItemBuilder;

  /// render a custom submit button
  /// @param [VoidCallback] submit function
  final Widget Function(VoidCallback onSubmit)? submitButtonBuilder;

  /// render a custom button
  /// if it returns null or it is null, it will build default button
  final Widget? Function(VoidCallback? onPressed, String key)?
      addFileButtonBuilder;

  final Widget Function(Widget child)? formSectionBuilder;
  final Widget? Function(FieldWrapperParams params)? fieldWrapperBuilder;

  String labelText(SchemaProperty property) =>
      '${property.titleOrId}${property.requiredNotNull ? "*" : ""}';

  String? fieldLabelText(SchemaProperty property) =>
      labelPosition == LabelPosition.fieldInputDecoration
          ? labelText(property)
          : null;

  InputDecoration inputDecoration(SchemaProperty property) {
    return InputDecoration(
      errorStyle: error,
      labelText: fieldLabelText(property),
      helperText: property.help ??
          (labelPosition == LabelPosition.table ? null : property.description),
    );
  }

  Widget? removeItemWidget(BuildContext context, Schema property) {
    final removeItem = RemoveItemInherited.getRemoveItem(context, property);
    if (removeItem == null) return null;

    return removeItemBuilder != null
        ? removeItemBuilder!(removeItem.value, removeItem.key)
        : TextButton.icon(
            key: Key('removeItem_${removeItem.key}'),
            onPressed: removeItem.value,
            icon: const Icon(Icons.remove),
            label: Text(localizedTexts.removeItem()),
          );
  }

  Widget addItemWidget(void Function() addItem, SchemaArray schemaArray) {
    String? message;
    final props = schemaArray.arrayProperties;
    if (props.maxItems != null && schemaArray.items.length >= props.maxItems!) {
      message = localizedTexts.maxItemsTooltip(props.maxItems!);
    }
    return addItemBuilder != null
        ? addItemBuilder!(addItem, schemaArray.idKey)
        : Tooltip(
            message: message ?? '',
            child: TextButton.icon(
              key: Key('addItem_${schemaArray.idKey}'),
              onPressed: message == null ? addItem : null,
              icon: const Icon(Icons.add),
              label: Text(localizedTexts.addItem()),
            ),
          );
  }

  @override
  bool operator ==(Object other) {
    return other is JsonFormSchemaUiConfig &&
        other.fieldTitle == fieldTitle &&
        other.error == error &&
        other.title == title &&
        other.titleAlign == titleAlign &&
        other.subtitle == subtitle &&
        other.description == description &&
        other.label == label &&
        other.localizedTexts == localizedTexts &&
        other.debugMode == debugMode &&
        other.labelPosition == labelPosition &&
        other.addItemBuilder == addItemBuilder &&
        other.removeItemBuilder == removeItemBuilder &&
        other.submitButtonBuilder == submitButtonBuilder &&
        other.addFileButtonBuilder == addFileButtonBuilder &&
        other.formSectionBuilder == formSectionBuilder &&
        other.fieldWrapperBuilder == fieldWrapperBuilder;
  }

  @override
  int get hashCode => Object.hash(
        fieldTitle,
        error,
        title,
        titleAlign,
        subtitle,
        description,
        label,
        localizedTexts,
        debugMode,
        labelPosition,
        addItemBuilder,
        removeItemBuilder,
        submitButtonBuilder,
        addFileButtonBuilder,
        formSectionBuilder,
        fieldWrapperBuilder,
      );
}

enum LabelPosition {
  top,
  side,
  table,
  fieldInputDecoration,
}

class FieldWrapperParams {
  const FieldWrapperParams({
    required this.property,
    required this.input,
    required this.removeItem,
  });

  final SchemaProperty property;
  final Widget input;
  final Widget? removeItem;
}
