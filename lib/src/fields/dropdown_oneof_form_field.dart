import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/one_of_model.dart';
import 'package:json_form/src/models/schema.dart';

class DropdownOneOfJFormField extends PropertyFieldWidget<dynamic> {
  const DropdownOneOfJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    this.customPickerHandler,
    super.customValidator,
  });

  final Future<dynamic> Function(Map)? customPickerHandler;

  @override
  _SelectedFormFieldState createState() => _SelectedFormFieldState();
}

class _SelectedFormFieldState
    extends PropertyFieldState<dynamic, DropdownOneOfJFormField> {
  final listOfModel = <OneOfModel>[];
  Map<String, dynamic> indexedData = {};
  OneOfModel? valueSelected;
  List<DropdownMenuItem<OneOfModel>> w = <DropdownMenuItem<OneOfModel>>[];

  @override
  void initState() {
    // fill enum property
    if (widget.property.enumm == null) {
      switch (widget.property.type) {
        case SchemaType.boolean:
          widget.property.enumm = [true, false];
          break;
        default:
          widget.property.enumm = widget.property.uiSchema.enumNames
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
      }
    }

    if (widget.property.oneOf is List) {
      for (int i = 0; i < (widget.property.oneOf?.length ?? 0); i++) {
        final oneOfItem = widget.property.oneOf![i] as Map;
        final customObject = OneOfModel(
          oneOfModelEnum: oneOfItem['enum'],
          title: oneOfItem['title'],
          type: oneOfItem['type'],
        );

        listOfModel.add(customObject);
      }
    }

    // fill selected value
    try {
      final defaultValue = widget.property.defaultValue.toLowerCase();
      final exists = listOfModel.firstWhere(
        (e) =>
            e.oneOfModelEnum != null &&
            e.oneOfModelEnum!.any((i) => i.toLowerCase() == defaultValue),
      );

      valueSelected = exists;
    } catch (e) {
      valueSelected = null;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.property.oneOf != null, 'oneOf is required');

    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return WrapFieldWithLabel(
      property: widget.property,
      child: GestureDetector(
        onTap: _onTap,
        child: AbsorbPointer(
          absorbing: widget.customPickerHandler != null,
          child: DropdownButtonFormField<OneOfModel>(
            key: Key(widget.property.idKey),
            value: valueSelected,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hint: Text(uiConfig.localizedTexts.select()),
            isExpanded: false,
            validator: (value) {
              if (widget.property.requiredNotNull && value == null) {
                return uiConfig.localizedTexts.required();
              }
              if (widget.customValidator != null)
                return widget.customValidator!(value);
              return null;
            },
            items: _buildItems(),
            onChanged: _onChanged,
            onSaved: widget.onSaved,
            decoration: uiConfig.inputDecoration(widget.property),
          ),
        ),
      ),
    );
  }

  void _onTap() async {
    log('ontap');
    if (widget.customPickerHandler == null) return;
    final response = await widget.customPickerHandler!(_getItems());

    if (response != null) _onChanged(response as OneOfModel);
  }

  void _onChanged(OneOfModel? value) {
    if (readOnly) return;

    setState(() {
      valueSelected = value;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(value?.oneOfModelEnum?.first);
    }
  }

  List<DropdownMenuItem<OneOfModel>>? _buildItems() {
    if (listOfModel.isEmpty) return [];
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    return listOfModel
        .map(
          (item) => DropdownMenuItem<OneOfModel>(
            value: item,
            child: Text(
              item.title ?? '',
              style: readOnly ? uiConfig.labelReadOnly : uiConfig.label,
            ),
          ),
        )
        .toList();
  }

  Map _getItems() {
    if (listOfModel.isEmpty) return {};

    final Map data = {};
    for (final element in listOfModel) {
      data[element] = element.title;
    }

    return data;
  }
}
