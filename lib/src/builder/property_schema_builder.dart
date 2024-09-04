import 'dart:async';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/object_schema_logic.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/fields/radio_button_form_field.dart';
import 'package:json_form/src/fields/dropdown_oneof_form_field.dart';
import 'package:json_form/src/fields/slider_form_field.dart';
import 'package:json_form/src/models/models.dart';
import 'package:json_form/src/models/one_of_model.dart';
import 'package:json_form/src/utils/date_text_input_json_formatter.dart';
import 'package:intl/intl.dart';

class PropertySchemaBuilder extends StatelessWidget {
  const PropertySchemaBuilder({
    super.key,
    required this.mainSchema,
    required this.schemaProperty,
    this.onChangeListen,
  });
  final Schema mainSchema;
  final SchemaProperty schemaProperty;
  final ValueChanged<dynamic>? onChangeListen;

  @override
  Widget build(BuildContext context) {
    Widget _field = const SizedBox.shrink();
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);

    // sort
    final schemaPropertySorted = schemaProperty;
    final customValidator = _getCustomValidator(context, schemaProperty.idKey);

    final enumNames = schemaProperty.uiSchema.enumNames;
    if (schemaProperty.uiSchema.widget == 'radio') {
      _field = RadioButtonJFormField(
        property: schemaPropertySorted,
        onChanged: (value) {
          dispatchBooleanEventToParent(context, value != null);
          updateData(context, value);
        },
        onSaved: (val) {
          log('onSaved: RadioButtonJFormField ${schemaProperty.idKey}  : $val');
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
          log('onSaved: RangeButtonJFormField ${schemaProperty.idKey}  : $val');
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
          log('onSaved: DropDownJFormField  ${schemaProperty.idKey}  : $val');
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
    } else if (schemaProperty.oneOf != null) {
      _field = DropdownOneOfJFormField(
        property: schemaPropertySorted,
        customPickerHandler: _getCustomPickerHandler(
          context,
          schemaProperty.id,
        ),
        onSaved: (val) {
          if (val is OneOfModel) {
            log('onSaved: SelectedFormField  ${schemaProperty.idKey}  : ${val.oneOfModelEnum?.first}');
            updateData(context, val.oneOfModelEnum?.first);
          }
        },
        onChanged: (value) {
          dispatchSelectedForDropDownEventToParent(
            context,
            value,
            id: schemaProperty.id,
          );

          if (value is OneOfModel) {
            updateData(context, value.oneOfModelEnum?.first);
          }
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
              log('onSaved: NumberJFormField ${schemaProperty.idKey}  : $val');
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
              log('onSaved: CheckboxJFormField ${schemaProperty.idKey}  : $val');
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

                log('onSaved: DateJFormField  ${schemaProperty.idKey}  : $date');
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
                log('onSaved: FileJFormField  ${schemaProperty.idKey}  : $val');
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
              log('onSaved: TextJFormField ${schemaProperty.idKey}  : $val');
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
          'key: ${schemaProperty.idKey}',
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

  void updateData(BuildContext context, dynamic val) {
    final widgetBuilderInherited = WidgetBuilderInherited.of(context);
    widgetBuilderInherited.controller.updateObjectData(
      schemaProperty.idKey,
      val,
    );
  }

  // @temp Functions
  /// Cuando se valida si es string o no
  void dispatchStringEventToParent(BuildContext context, String value) {
    if (value.isEmpty && schemaProperty.isDependentsActive) {
      ObjectSchemaInherited.of(context)
          .listenChangeProperty(false, schemaProperty);
    }

    if (value.isNotEmpty && !schemaProperty.isDependentsActive) {
      ObjectSchemaInherited.of(context)
          .listenChangeProperty(true, schemaProperty);
    }
  }

  void dispatchSelectedForDropDownEventToParent(
    BuildContext context,
    dynamic value, {
    String? id,
  }) {
    log('dispatchSelectedForDropDownEventToParent()  $value ID: $id');
    ObjectSchemaInherited.of(context).listenChangeProperty(
      (value != null && (value is String ? value.isNotEmpty : true)),
      schemaProperty,
      optionalValue: value,
      idOptional: id,
      mainSchema: mainSchema,
    );
    // }
  }

  /// Cuando se valida si es true o false
  void dispatchBooleanEventToParent(BuildContext context, bool value) {
    log('dispatchBooleanEventToParent()  $value');
    if (value != schemaProperty.isDependentsActive) {
      ObjectSchemaInherited.of(context)
          .listenChangeProperty(value, schemaProperty);
    }
  }

  Future<List<XFile>?> Function() getCustomFileHandler(
    FileHandler customFileHandler,
    String key,
  ) {
    final handlers = customFileHandler();
    assert(handlers.isNotEmpty, 'CustomFileHandler must not be empty');

    if (handlers.containsKey(key))
      return handlers[key] as Future<List<XFile>?> Function();

    if (handlers.containsKey('*')) {
      assert(handlers['*'] != null, 'Default file handler must not be null');
      return handlers['*'] as Future<List<XFile>?> Function();
    }

    throw Exception('no file handler found');
  }

  Future<dynamic> Function(Map<dynamic, dynamic>)? _getCustomPickerHandler(
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
