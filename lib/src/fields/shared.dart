import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/models/json_form_ui_config.dart';

export 'package:json_form/src/fields/fields.dart'
    show PropertyFieldState, PropertyFieldWidget;
export 'package:json_form/src/models/json_form_ui_config.dart';

class CustomErrorText extends StatelessWidget {
  const CustomErrorText({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5),
      child: Text(
        text,
        style: WidgetBuilderInherited.of(context).uiConfig.error,
      ),
    );
  }
}

class WrapFieldWithLabel extends StatelessWidget {
  const WrapFieldWithLabel({
    super.key,
    required this.formValue,
    required this.child,
    this.ignoreFieldLabel = false,
  });

  final JsonFormValue formValue;
  final Widget child;
  final bool ignoreFieldLabel;

  @override
  Widget build(BuildContext context) {
    final property = formValue.schema;
    final directionality = Directionality.of(context);
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;

    Widget child = this.child;
    if (uiConfig.inputWrapperBuilder != null) {
      final wrapped = uiConfig.inputWrapperBuilder!(property, child);
      if (wrapped != null) child = wrapped;
    }

    if (uiConfig.fieldWrapperBuilder != null) {
      final wrapped = uiConfig.fieldWrapperBuilder!(property, child);
      if (wrapped != null) return wrapped;
    }
    // configured in the field itself
    final showLabel = ignoreFieldLabel ||
        uiConfig.labelPosition != LabelPosition.input &&
            uiConfig.labelPosition != LabelPosition.table;
    if (!showLabel) return child;

    final labelText = uiConfig.labelText(formValue);
    final label = Text(
      labelText,
      style: uiConfig.fieldLabel,
    );
    final mappedChild = uiConfig.labelPosition == LabelPosition.top
        ? child
        : Expanded(child: child);
    final space = uiConfig.labelPosition == LabelPosition.top
        ? null
        : const SizedBox(width: 20);

    return Flex(
      direction: uiConfig.labelPosition == LabelPosition.top
          ? Axis.vertical
          : Axis.horizontal,
      children: directionality == TextDirection.rtl
          ? [mappedChild, if (space != null) space, label]
          : [label, if (space != null) space, mappedChild],
    );
  }
}

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final custom = uiConfig.formSectionBuilder?.call(child);
    if (custom != null) return custom;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: (DividerTheme.of(context).color ??
                    Theme.of(context).dividerColor)
                .withAlpha((255 * 0.2).round()),
          ),
        ),
      ),
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.only(left: 7),
      child: child,
    );
  }
}

// ignore: avoid_classes_with_only_static_members
class JsonFormKeys {
  static const Key submitButton = Key('JsonForm_submitButton');
  static const Key scrollView = Key('JsonForm_scrollView');

  static ValueKey<String> selectDate(String idKey) =>
      ValueKey('JsonForm_selectDate_$idKey');
  static ValueKey<String> selectTime(String idKey) =>
      ValueKey('JsonForm_selectTime_$idKey');
  static ValueKey<String> objectProperty(String idKey) =>
      ValueKey('JsonForm_objectProperty_$idKey');

  static Key arrayCheckboxItem(String arrayKey, int index) =>
      Key('JsonForm_item_${arrayKey}_$index');
  static Key arrayItem(String itemKey) => Key('JsonForm_item_$itemKey');
  static Key showOrHideItems(String arrayKey) =>
      Key('JsonForm_showOrHideItems_$arrayKey');

  static Key removeItem(String idKey) => Key('removeItem_$idKey');
  static Key addItem(String idKey) => Key('addItem_$idKey');
  static Key copyItem(String idKey) => Key('copyItem_$idKey');

  static Key inputField(String idKey) => Key(idKey);
  static Key inputFieldItem(String idKey, int index) => Key('${idKey}_$index');
}
