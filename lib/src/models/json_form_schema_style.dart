import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/models/models.dart';

class JsonFormSchemaUiConfig {
  const JsonFormSchemaUiConfig({
    this.title,
    this.titleAlign,
    this.subtitle,
    this.description,
    this.fieldLabel,
    this.fieldInput,
    this.fieldInputReadOnly,
    this.error,
    AutovalidateMode? autovalidateMode,
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
        labelPosition = labelPosition ?? LabelPosition.table,
        autovalidateMode =
            autovalidateMode ?? AutovalidateMode.onUserInteraction;

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
  final TextStyle? fieldLabel;

  /// Field input value style
  final TextStyle? fieldInput;

  /// Field input value style for read-only fields
  final TextStyle? fieldInputReadOnly;

  /// Validation errors text style
  final TextStyle? error;

  /// Localized texts
  final LocalizedTexts localizedTexts;

  /// Enable debug mode
  final bool debugMode;

  /// The position of the field labels
  final LabelPosition labelPosition;

  final AutovalidateMode autovalidateMode;

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
      labelStyle: fieldLabel,
      labelText:
          labelPosition == LabelPosition.input ? labelText(property) : null,
      hintText: property.uiSchema.placeholder,
      helperText: property.uiSchema.help ??
          (labelPosition == LabelPosition.table ? null : property.description),
    );
  }

  Widget removeItemWidget(String idKey, void Function() removeItem) {
    return removeItemBuilder?.call(removeItem, idKey) ??
        TextButton.icon(
          key: Key('removeItem_$idKey'),
          onPressed: removeItem,
          icon: const Icon(Icons.remove),
          label: Text(localizedTexts.removeItem()),
        );
  }

  Widget addItemWidget(
    JsonFormValue arrayValue,
    void Function() addItem,
  ) {
    String? message;
    final props = (arrayValue.schema as SchemaArray).arrayProperties;
    if (props.maxItems != null &&
        arrayValue.children.length >= props.maxItems!) {
      message = localizedTexts.maxItemsTooltip(props.maxItems!);
    }
    final idKey = arrayValue.idKey;
    return addItemBuilder?.call(addItem, idKey) ??
        Tooltip(
          message: message ?? '',
          child: TextButton.icon(
            key: Key('addItem_$idKey'),
            onPressed: message == null ? addItem : null,
            icon: const Icon(Icons.add),
            label: Text(localizedTexts.addItem()),
          ),
        );
  }

  Widget copyItemWidget(String idKey, void Function() copyItem) {
    return copyItemBuilder?.call(copyItem, idKey) ??
        TextButton.icon(
          key: Key('copyItem_$idKey'),
          onPressed: copyItem,
          icon: const Icon(Icons.copy),
          label: Text(localizedTexts.copyItem()),
        );
  }

  factory JsonFormSchemaUiConfig.fromContext(
    BuildContext context, {
    JsonFormSchemaUiConfig? baseConfig,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return JsonFormSchemaUiConfig(
      title: baseConfig?.title ?? textTheme.titleLarge,
      titleAlign: baseConfig?.titleAlign ?? TextAlign.center,
      subtitle: baseConfig?.subtitle ??
          textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      description: baseConfig?.description ?? textTheme.bodyMedium,
      error: baseConfig?.error ??
          TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: textTheme.bodySmall!.fontSize,
          ),
      fieldLabel: baseConfig?.fieldLabel,
      fieldInput: baseConfig?.fieldInput,
      fieldInputReadOnly:
          baseConfig?.fieldInputReadOnly ?? const TextStyle(color: Colors.grey),
      debugMode: baseConfig?.debugMode,
      localizedTexts: baseConfig?.localizedTexts,
      labelPosition: baseConfig?.labelPosition,
      autovalidateMode: baseConfig?.autovalidateMode,

      /// builders
      addItemBuilder: baseConfig?.addItemBuilder,
      removeItemBuilder: baseConfig?.removeItemBuilder,
      copyItemBuilder: baseConfig?.copyItemBuilder,
      submitButtonBuilder: baseConfig?.submitButtonBuilder,
      addFileButtonBuilder: baseConfig?.addFileButtonBuilder,
      fieldWrapperBuilder: baseConfig?.fieldWrapperBuilder,
      inputWrapperBuilder: baseConfig?.inputWrapperBuilder,
      formBuilder: baseConfig?.formBuilder,
      formSectionBuilder: baseConfig?.formSectionBuilder,
      titleAndDescriptionBuilder: baseConfig?.titleAndDescriptionBuilder,
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
        other.fieldLabel == fieldLabel &&
        other.fieldInput == fieldInput &&
        other.fieldInputReadOnly == fieldInputReadOnly &&
        other.localizedTexts == localizedTexts &&
        other.debugMode == debugMode &&
        other.labelPosition == labelPosition &&
        other.autovalidateMode == autovalidateMode &&
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
  int get hashCode => Object.hashAll([
        error,
        title,
        titleAlign,
        subtitle,
        description,
        fieldLabel,
        fieldInput,
        fieldInputReadOnly,
        localizedTexts,
        debugMode,
        labelPosition,
        autovalidateMode,
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
      ]);
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
