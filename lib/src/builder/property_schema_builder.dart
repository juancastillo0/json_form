import 'dart:async';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_form/src/builder/logic/object_schema_logic.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/models/models.dart';
import 'package:json_form/src/utils/date_text_input_json_formatter.dart';

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
    final idKey = JsonFormKeyPath.ofPath(context);
    final customValidator = _getCustomValidator(context, idKey);

    final enumNames = schemaProperty.uiSchema.enumNames;
    if (schemaProperty.uiSchema.widget == 'radio') {
      _field = RadioButtonJFormField(
        property: schemaPropertySorted,
        onChanged: (value) {
          dispatchBooleanEventToParent(context, value != null);
          updateData(context, value);
        },
        onSaved: (val) {
          log('onSaved: RadioButtonJFormField $idKey  : $val');
          updateData(context, val);
        },
        customValidator: customValidator,
      );
    } else if (schemaProperty.uiSchema.widget == 'range') {
      _field = SliderJFormField(
        property: schemaPropertySorted,
        onChanged: (value) {
          dispatchBooleanEventToParent(context, value != null);
          updateData(context, value);
        },
        onSaved: (val) {
          log('onSaved: RangeButtonJFormField $idKey  : $val');
          updateData(context, val);
        },
        customValidator: customValidator,
      );
    } else if (schemaProperty.enumm != null &&
        (schemaProperty.enumm!.isNotEmpty ||
            (enumNames != null && enumNames.isNotEmpty))) {
      _field = DropDownJFormField(
        property: schemaPropertySorted,
        customPickerHandler: _getCustomPickerHandler(
          context,
          schemaProperty.id,
        ),
        onSaved: (val) {
          log('onSaved: DropDownJFormField  $idKey  : $val');
          updateData(context, val);
        },
        onChanged: (value) {
          dispatchSelectedForDropDownEventToParent(
            context,
            value,
            id: schemaProperty.id,
          );
          updateData(context, value);
        },
        customValidator: customValidator,
      );
    } else if (schemaProperty.oneOf.isNotEmpty) {
      _field = DropdownOneOfJFormField(
        property: schemaPropertySorted,
        customPickerHandler: _getCustomPickerHandler(
          context,
          schemaProperty.id,
        ),
        onSaved: (val) {
          log('onSaved: SelectedFormField  $idKey  : $val');
          updateData(context, val);
        },
        onChanged: (value) {
          dispatchSelectedForDropDownEventToParent(
            context,
            value,
            id: schemaProperty.id,
          );
          updateData(context, value);
        },
        customValidator: customValidator,
      );
    } else {
      switch (schemaProperty.type) {
        case SchemaType.integer:
        case SchemaType.number:
          _field = NumberJFormField(
            property: schemaPropertySorted,
            onSaved: (val) {
              log('onSaved: NumberJFormField $idKey  : $val');
              updateData(context, val);
            },
            onChanged: (value) {
              dispatchBooleanEventToParent(
                context,
                value != null,
              );
              updateData(context, value);
            },
            customValidator: customValidator,
          );
          break;
        case SchemaType.boolean:
          _field = CheckboxJFormField(
            property: schemaPropertySorted,
            onChanged: (value) {
              dispatchBooleanEventToParent(context, value!);
              updateData(context, value);
            },
            onSaved: (val) {
              log('onSaved: CheckboxJFormField $idKey  : $val');
              updateData(context, val);
            },
            customValidator: customValidator,
          );
          break;
        case SchemaType.string:
        default:
          if (schemaProperty.format == PropertyFormat.date ||
              schemaProperty.format == PropertyFormat.dateTime) {
            _field = DateJFormField(
              property: schemaPropertySorted,
              onSaved: (val) {
                if (val == null) return;
                String date;
                if (schemaProperty.format == PropertyFormat.date) {
                  date = DateFormat(dateFormatString).format(val);
                } else {
                  date = DateFormat(dateTimeFormatString).format(val);
                }

                log('onSaved: DateJFormField  $idKey  : $date');
                updateData(context, date);
              },
              onChanged: (value) {
                dispatchBooleanEventToParent(context, value != null);
                if (value == null) return;
                String date;
                if (schemaProperty.format == PropertyFormat.date) {
                  date = DateFormat(dateFormatString).format(value);
                } else {
                  date = DateFormat(dateTimeFormatString).format(value);
                }

                updateData(context, date);
              },
              customValidator: customValidator,
            );
            break;
          }

          if (schemaProperty.format == PropertyFormat.dataUrl) {
            assert(
              WidgetBuilderInherited.of(context).fileHandler != null,
              'File handler can not be null when using file inputs',
            );
            _field = FileJFormField(
              property: schemaPropertySorted,
              fileHandler: getCustomFileHandler(
                WidgetBuilderInherited.of(context).fileHandler!,
                schemaProperty.id,
              ),
              onSaved: (val) {
                log('onSaved: FileJFormField  $idKey  : $val');
                updateData(context, val);
              },
              onChanged: (value) {
                log(value.toString());
                dispatchBooleanEventToParent(
                  context,
                  schemaProperty.isMultipleFile
                      ? value is List && value.isNotEmpty
                      : value != null,
                );

                updateData(context, value);
              },
              customValidator: customValidator,
            );
            break;
          }

          _field = TextJFormField(
            property: schemaPropertySorted,
            onSaved: (val) {
              log('onSaved: TextJFormField $idKey  : $val');
              updateData(context, val);
            },
            onChanged: (value) {
              dispatchStringEventToParent(context, value!);
              updateData(context, value);
            },
            customValidator: customValidator,
          );
          break;
      }
    }

    if (!widgetBuilderInherited.uiConfig.debugMode) {
      return _field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Text(
          'key: $idKey',
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

  void updateData(BuildContext context, Object? val) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    final idKey = JsonFormKeyPath.ofPath(context);
    widgetBuilderInherited.controller.updateObjectData(idKey, val);
  }

  void dispatchStringEventToParent(BuildContext context, String value) {
    if (value.isEmpty && formValue.isDependentsActive) {
      ObjectSchemaInherited.of(context).listenChangeProperty(false, formValue);
    }

    if (value.isNotEmpty && !formValue.isDependentsActive) {
      ObjectSchemaInherited.of(context).listenChangeProperty(true, formValue);
    }
  }

  void dispatchSelectedForDropDownEventToParent(
    BuildContext context,
    Object? value, {
    String? id,
  }) {
    log('dispatchSelectedForDropDownEventToParent() $value ID: $id');
    ObjectSchemaInherited.of(context).listenChangeProperty(
      value != null && (value is! String || value.isNotEmpty),
      formValue,
      optionalValue: value,
      // TODO: idOptional: id,
      // mainSchema: mainSchema,
    );
  }

  void dispatchBooleanEventToParent(BuildContext context, bool isActive) {
    log('dispatchBooleanEventToParent()  $isActive');
    if (isActive != formValue.isDependentsActive) {
      ObjectSchemaInherited.of(context)
          .listenChangeProperty(isActive, formValue);
    }
  }

  Future<List<XFile>?> Function() getCustomFileHandler(
    FileHandler customFileHandler,
    String key,
  ) {
    final handlers = customFileHandler();
    assert(handlers.isNotEmpty, 'CustomFileHandler must not be empty');

    var h = handlers[key];
    if (h != null) return h;
    h = handlers['*'];
    if (h != null) return h;

    throw Exception('no file handler found');
  }

  Future<Object?> Function(Map<Object?, Object?>)? _getCustomPickerHandler(
    BuildContext context,
    String key,
  ) {
    final customFileHandler =
        WidgetBuilderInherited.of(context).customPickerHandler;

    if (customFileHandler == null) return null;

    final handlers = customFileHandler();
    if (handlers.containsKey(key)) return handlers[key];
    if (handlers.containsKey('*')) return handlers['*'];
    return null;
  }

  String? Function(dynamic)? _getCustomValidator(
    BuildContext context,
    String key,
  ) {
    final customValidatorHandler =
        WidgetBuilderInherited.of(context).customValidatorHandler;

    if (customValidatorHandler == null) return null;

    final handlers = customValidatorHandler();
    if (handlers.containsKey(key)) return handlers[key];
    if (handlers.containsKey('*')) return handlers['*'];
    return null;
  }
}
