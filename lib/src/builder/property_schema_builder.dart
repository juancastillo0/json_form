import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/models/models.dart';

class PropertySchemaBuilder extends StatelessWidget {
  const PropertySchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.formValue,
    this.onChangeListen,
  });
  final Schema mainSchema;
  final JsonFormValue formValue;
  SchemaProperty get schemaProperty => formValue.schema as SchemaProperty;
  final ValueChanged<dynamic>? onChangeListen;

  @override
  Widget build(BuildContext context) {
    Widget _field = const SizedBox.shrink();
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);

    final schemaPropertySorted = schemaProperty;

    final enumNames = schemaProperty.uiSchema.enumNames;
    if (schemaProperty.uiSchema.widget == 'radio') {
      _field = RadioButtonJFormField(property: schemaPropertySorted);
    } else if (schemaProperty.uiSchema.widget == 'range') {
      _field = SliderJFormField(property: schemaPropertySorted);
    } else if (schemaProperty.enumm != null &&
        (schemaProperty.enumm!.isNotEmpty ||
            (enumNames != null && enumNames.isNotEmpty))) {
      _field = DropDownJFormField(property: schemaPropertySorted);
    } else if (schemaProperty.oneOf.isNotEmpty) {
      _field = DropdownOneOfJFormField(property: schemaPropertySorted);
    } else {
      switch (schemaProperty.type) {
        case JsonSchemaType.integer:
        case JsonSchemaType.number:
          _field = NumberJFormField(property: schemaPropertySorted);
          break;
        case JsonSchemaType.boolean:
          _field = CheckboxJFormField(property: schemaPropertySorted);
          break;
        case JsonSchemaType.string:
        default:
          if (schemaProperty.format == PropertyFormat.date ||
              schemaProperty.format == PropertyFormat.dateTime) {
            _field = DateJFormField(property: schemaPropertySorted);
            break;
          }

          if (schemaProperty.format == PropertyFormat.dataUrl) {
            _field = FileJFormField(property: schemaPropertySorted);
            break;
          }

          _field = TextJFormField(property: schemaPropertySorted);
          break;
      }
    }

    final width = schemaProperty.uiSchema.width;
    if (width != null) {
      _field = SizedBox(width: width, child: _field);
    }
    if (!widgetBuilderInherited.uiConfig.debugMode) {
      return _field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          'key: ${JsonFormKeyPath.getPath(context)}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        _field,
      ],
    );
  }
}
