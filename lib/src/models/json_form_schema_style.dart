import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

/// Global configuration for the UI of the form.
/// Contains styles, texts, builders and other Flutter configurations.
class JsonFormUiConfig {
  /// Global configuration for the UI of the form.
  /// Contains styles, texts, builders and other Flutter configurations.
  const JsonFormUiConfig({
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

  /// Enables debug mode
  final bool debugMode;

  /// The position of the field labels
  final LabelPosition labelPosition;

  /// Autovalidate mode for the form. Determines when the input validation occurs
  final AutovalidateMode autovalidateMode;

  /// Render a custom add item button for arrays
  final Widget? Function(VoidCallback onPressed, String key)? addItemBuilder;

  /// Render a custom remove item button for arrays
  final Widget? Function(VoidCallback onPressed, String key)? removeItemBuilder;

  /// Render a custom copy item button for arrays
  final Widget? Function(VoidCallback onPressed, String key)? copyItemBuilder;

  /// Render a custom submit button for the form
  final Widget? Function(VoidCallback onSubmit)? submitButtonBuilder;

  /// Render a custom add file button.
  /// If it returns null or it is null, we will build the default button
  final Widget? Function(VoidCallback? onPressed, String key)?
      addFileButtonBuilder;

  /// Render a custom [Form] widget.
  final Form? Function(GlobalKey<FormState> formKey, Widget child)? formBuilder;

  /// Render a custom form section widget. This is used for objects and arrays.
  final Widget? Function(Widget child)? formSectionBuilder;

  /// Render a custom title and description widget.
  /// This is used for objects, arrays and fields (when using labelPosition = [LabelPosition.table]).
  final Widget? Function(JsonSchemaInfo info)? titleAndDescriptionBuilder;

  /// Render a custom field wrapper widget. Already contains the label
  final Widget? Function(JsonSchemaInfo property, Widget input)?
      fieldWrapperBuilder;

  /// Render a custom field wrapper widget. Does not contain the label
  final Widget? Function(JsonSchemaInfo property, Widget input)?
      inputWrapperBuilder;

  factory JsonFormUiConfig.fromContext(
    BuildContext context, {
    JsonFormUiConfig? baseConfig,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return JsonFormUiConfig(
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

      /// Builders
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
    return other is JsonFormUiConfig &&
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

/// The position of the field labels
enum LabelPosition {
  /// Labels are on top of the input
  top,

  /// Labels are on the left or right of the input,
  /// depending on the [Directionality]
  side,

  /// Labels are all in one column and inputs are in another column
  table,

  /// Label is in the [InputDecoration]
  input,
}

extension JsonFormUiConfigExtension on JsonFormUiConfig {
  String labelText(JsonFormValue fromValue) =>
      '${fromValue.schema.titleOrId}${fromValue.isRequiredNotNull ? "*" : ""}';

  InputDecoration inputDecoration(JsonFormValue fromValue) {
    final property = fromValue.schema;
    return InputDecoration(
      errorStyle: error,
      labelStyle: fieldLabel,
      labelText:
          labelPosition == LabelPosition.input ? labelText(fromValue) : null,
      hintText: property.uiSchema.placeholder,
      helperText: property.uiSchema.help ??
          (labelPosition == LabelPosition.table ? null : property.description),
    );
  }

  Widget removeItemWidget(String idKey, void Function() removeItem) {
    return removeItemBuilder?.call(removeItem, idKey) ??
        TextButton.icon(
          key: JsonFormKeys.removeItem(idKey),
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
            key: JsonFormKeys.addItem(idKey),
            onPressed: message == null ? addItem : null,
            icon: const Icon(Icons.add),
            label: Text(localizedTexts.addItem()),
          ),
        );
  }

  Widget copyItemWidget(String idKey, void Function() copyItem) {
    return copyItemBuilder?.call(copyItem, idKey) ??
        TextButton.icon(
          key: JsonFormKeys.copyItem(idKey),
          onPressed: copyItem,
          icon: const Icon(Icons.copy),
          label: Text(localizedTexts.copyItem()),
        );
  }
}
