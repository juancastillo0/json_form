import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/models/models.dart';

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
    this.inputWrapperBuilder,
    LocalizedTexts? localizedTexts,
    bool? debugMode,
    LabelPosition? labelPosition,
  })  : localizedTexts = localizedTexts ?? const LocalizedTexts(),
        debugMode = debugMode ?? false,
        labelPosition = labelPosition ?? LabelPosition.input;

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
  final Widget? Function(FieldWrapperParams params)? inputWrapperBuilder;

  String labelText(SchemaProperty property) =>
      '${property.titleOrId}${property.requiredNotNull ? "*" : ""}';

  String? fieldLabelText(SchemaProperty property) =>
      labelPosition == LabelPosition.input ? labelText(property) : null;

  InputDecoration inputDecoration(SchemaProperty property) {
    return InputDecoration(
      errorStyle: error,
      labelText: fieldLabelText(property),
      hintText: property.uiSchema.placeholder,
      helperText: property.uiSchema.help ??
          (labelPosition == LabelPosition.table ? null : property.description),
    );
  }

  Widget removeItemWidget(Schema property, void Function() removeItem) {
    return removeItemBuilder != null
        ? removeItemBuilder!(removeItem, property.idKey)
        : TextButton.icon(
            key: Key('removeItem_${property.idKey}'),
            onPressed: removeItem,
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

  Widget copyItemWidget(Schema itemSchema, void Function() copyItem) {
    // TODO: copyItemBuilder
    return TextButton.icon(
      key: Key('copyItem_${itemSchema.idKey}'),
      onPressed: copyItem,
      icon: const Icon(Icons.copy),
      label: Text(localizedTexts.copyItem()),
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
        other.fieldWrapperBuilder == fieldWrapperBuilder &&
        other.inputWrapperBuilder == inputWrapperBuilder;
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
        inputWrapperBuilder,
      );
}

enum LabelPosition {
  /// Labels are on top of the input
  top,

  /// Labels are on the left or right of the input,
  /// depending on the Directionality
  side,

  /// Labels are all in one column
  table,

  /// Label is in the Field Input Decoration
  input,
}

class FieldWrapperParams {
  const FieldWrapperParams({
    required this.property,
    required this.input,
  });

  final SchemaProperty property;
  final Widget input;
}
