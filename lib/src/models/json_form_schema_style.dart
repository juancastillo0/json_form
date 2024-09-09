import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/models/models.dart';

class JsonFormSchemaUiConfig {
  const JsonFormSchemaUiConfig({
    this.title,
    this.titleAlign,
    this.subtitle,
    this.description,
    this.label,
    this.labelReadOnly,
    this.error,
    this.addItemBuilder,
    this.removeItemBuilder,
    this.copyItemBuilder,
    this.submitButtonBuilder,
    this.addFileButtonBuilder,
    this.formBuilder,
    this.formSectionBuilder,
    this.titleAndDescriptionBuilder,
    this.fieldWrapperBuilder,
    this.inputWrapperBuilder,
    LocalizedTexts? localizedTexts,
    bool? debugMode,
    LabelPosition? labelPosition,
  })  : localizedTexts = localizedTexts ?? const LocalizedTexts(),
        debugMode = debugMode ?? false,
        labelPosition = labelPosition ?? LabelPosition.table;

  /// Form title style
  final TextStyle? title;

  /// Form title alignment
  final TextAlign? titleAlign;

  /// Object and array title style.
  /// The title for each form section constructed with [formSectionBuilder] will use this style.
  final TextStyle? subtitle;

  /// Description style
  final TextStyle? description;

  /// Field label style
  /// TODO: label vs field title
  final TextStyle? label;

  /// Field label style for read-only fields
  final TextStyle? labelReadOnly;

  /// Validation errors text style
  final TextStyle? error;

  /// Localized texts
  final LocalizedTexts localizedTexts;

  /// Enable debug mode
  final bool debugMode;

  /// The position of the field labels
  final LabelPosition labelPosition;

  final Widget? Function(VoidCallback onPressed, String key)? addItemBuilder;
  final Widget? Function(VoidCallback onPressed, String key)? removeItemBuilder;
  final Widget? Function(VoidCallback onPressed, String key)? copyItemBuilder;

  /// Render a custom submit button
  final Widget? Function(VoidCallback onSubmit)? submitButtonBuilder;

  /// Render a custom add file button.
  /// If it returns null or it is null, we will build the default button
  final Widget? Function(VoidCallback? onPressed, String key)?
      addFileButtonBuilder;

  final Form? Function(GlobalKey<FormState> formKey, Widget child)? formBuilder;
  final Widget? Function(Widget child)? formSectionBuilder;
  final Widget? Function(SchemaUiInfo info)? titleAndDescriptionBuilder;
  final Widget? Function(SchemaUiInfo property, Widget input)?
      fieldWrapperBuilder;
  final Widget? Function(SchemaUiInfo property, Widget input)?
      inputWrapperBuilder;

  String labelText(SchemaProperty property) =>
      '${property.titleOrId}${property.requiredNotNull ? "*" : ""}';

  InputDecoration inputDecoration(SchemaProperty property) {
    return InputDecoration(
      errorStyle: error,
      labelText:
          labelPosition == LabelPosition.input ? labelText(property) : null,
      hintText: property.uiSchema.placeholder,
      helperText: property.uiSchema.help ??
          (labelPosition == LabelPosition.table ? null : property.description),
    );
  }

  Widget removeItemWidget(Schema property, void Function() removeItem) {
    return removeItemBuilder?.call(removeItem, property.idKey) ??
        TextButton.icon(
          key: Key('removeItem_${property.idKey}'),
          onPressed: removeItem,
          icon: const Icon(Icons.remove),
          label: Text(localizedTexts.removeItem()),
        );
  }

  Widget addItemWidget(SchemaArray schemaArray, void Function() addItem) {
    String? message;
    final props = schemaArray.arrayProperties;
    if (props.maxItems != null && schemaArray.items.length >= props.maxItems!) {
      message = localizedTexts.maxItemsTooltip(props.maxItems!);
    }
    return addItemBuilder?.call(addItem, schemaArray.idKey) ??
        Tooltip(
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
    return copyItemBuilder?.call(copyItem, itemSchema.idKey) ??
        TextButton.icon(
          key: Key('copyItem_${itemSchema.idKey}'),
          onPressed: copyItem,
          icon: const Icon(Icons.copy),
          label: Text(localizedTexts.copyItem()),
        );
  }

  @override
  bool operator ==(Object other) {
    return other is JsonFormSchemaUiConfig &&
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
        other.copyItemBuilder == copyItemBuilder &&
        other.submitButtonBuilder == submitButtonBuilder &&
        other.addFileButtonBuilder == addFileButtonBuilder &&
        other.formBuilder == formBuilder &&
        other.formSectionBuilder == formSectionBuilder &&
        other.titleAndDescriptionBuilder == titleAndDescriptionBuilder &&
        other.fieldWrapperBuilder == fieldWrapperBuilder &&
        other.inputWrapperBuilder == inputWrapperBuilder;
  }

  @override
  int get hashCode => Object.hash(
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
        copyItemBuilder,
        submitButtonBuilder,
        addFileButtonBuilder,
        formBuilder,
        formSectionBuilder,
        titleAndDescriptionBuilder,
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
