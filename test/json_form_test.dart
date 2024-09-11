import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';
import 'package:json_form/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUtils {
  final WidgetTester tester;

  TestUtils(this.tester);

  static const scrollViewKey = Key('JsonForm_scrollView');

  Future<Finder> findAndEnterText(String key, String text) async {
    final input = find.byKey(Key(key));
    expect(input, findsOneWidget);
    await tester.enterText(input, text);
    await tester.pump();
    return input;
  }

  Future<Finder> tapSubmitButton() async {
    return tapButton('JsonForm_submitButton');
  }

  Future<Finder> tapButton(String key) async {
    final button = find.byKey(Key(key));
    expect(button, findsOneWidget);
    try {
      await tester.dragUntilVisible(
        button.hitTestable(),
        find.byKey(scrollViewKey),
        const Offset(0, 100),
      );
    } catch (_) {
      await tester.dragUntilVisible(
        button.hitTestable(),
        find.byKey(scrollViewKey),
        const Offset(0, -100),
      );
    }
    await tester.tap(button);
    await tester.pump();
    return button;
  }

  List<Object?> getUiArrayCheckbox(String key, List options) {
    int i = 0;
    return options.where((_) {
      final checkbox = tester.firstWidget<CheckboxListTile>(
        find.byKey(Key('JsonForm_item_${key}_${i++}')),
      );
      return checkbox.value == true;
    }).toList();
  }

  Future<void> updateUiArrayCheckbox(
    String key,
    List options,
    List newValues,
  ) async {
    int i = 0;
    for (final value in options) {
      final f = find.byKey(Key('JsonForm_item_${key}_${i++}'));
      final checkbox = tester.firstWidget<CheckboxListTile>(f);
      if (newValues.contains(value) && checkbox.value != true ||
          !newValues.contains(value) && checkbox.value == true) {
        await tester.tap(f);
        await tester.pump();
      }
    }
  }
}

void main() {
  testWidgets('primitives and labels/titles', (tester) async {
    final utils = TestUtils(tester);
    late void Function(void Function()) setState;
    LabelPosition labelPosition = LabelPosition.top;
    Map<String, Object?> data = {};
    final controller = JsonFormController(data: data);
    // TODO: file, color
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState_) {
              setState = setState_;
              return JsonForm(
                jsonSchema: '''{
          "type": "object",
          "title": "My Form",
          "properties": {
            "string": {
              "type": "string",
              "title": "stringTitle"
            },
            "number": {
              "type": "number",
              "title": "numberTitle"
            },
            "integer": {
              "type": "integer",
              "title": "integerTitle"
            },
            "boolean": {
              "type": "boolean",
              "title": "booleanTitle"
            },
            "enum": {
              "type": "string",
              "title": "enumTitle",
              "enum": ["a", "b", "c", "d"]
            },
            "enumRadio": {
              "type": "integer",
              "title": "enumRadioTitle",
              "enum": [2, 4, 6]
            },
            "date": {
              "type": "string",
              "format": "date",
              "title": "dateTitle"
            },
            "dateTime": {
              "type": "string",
              "format": "date-time",
              "title": "dateTimeTitle"
            },
            "arrayCheckbox": {
              "type": "array",
              "title": "arrayCheckboxTitle",
              "items": {
                "type": "string",
                "enum": ["e", "f"]
              }
            }
          }
        }''',
                onFormDataSaved: (p) => data = p as Map<String, Object?>,
                controller: controller,
                uiConfig: JsonFormSchemaUiConfig(
                  labelPosition: labelPosition,
                ),
                uiSchema: '''{
                  "enumRadio": {
                    "ui:widget": "radio"
                  },
                  "arrayCheckbox": {
                    "ui:widget": "checkboxes"
                  }
                }''',
              );
            },
          ),
        ),
      ),
    );
    expect(data, {'arrayCheckbox': []});

    // TODO: use JsonFormInput_string as Key?
    await utils.findAndEnterText('string', 'hello');
    final numberInput = await utils.findAndEnterText('number', '2');
    expect(
      data,
      {
        'arrayCheckbox': [],
        'string': 'hello',
        'number': 2.0,
      },
    );

    final submitButton = await utils.tapSubmitButton();
    expect(
      data,
      {
        'string': 'hello',
        'number': 2.0,
        'boolean': false,
        'enum': null,
        'enumRadio': null,
        'arrayCheckbox': [],
      },
    );

    final integerInput = find.byKey(const Key('integer'));
    expect(integerInput, findsOneWidget);
    await tester.enterText(integerInput, '-3');
    await tester.enterText(numberInput, '.2');
    await tester.pump();

    await utils.tapButton('boolean');
    await tester.tap(submitButton);
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 0.2,
        'integer': -3,
        'boolean': true,
        'enum': null,
        'enumRadio': null,
        'arrayCheckbox': [],
      },
    );

    final enumDropDown = find.byKey(const Key('enum'));
    expect(enumDropDown, findsOneWidget);
    await tester.tap(enumDropDown);
    await tester.pump();
    await tester.tap(find.byKey(const Key('enum_1')), warnIfMissed: false);
    await tester.pump();
    await utils.tapSubmitButton();
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 0.2,
        'integer': -3,
        'boolean': true,
        'enum': 'b',
        'enumRadio': null,
        'arrayCheckbox': [],
      },
    );

    final radio0 = find.byKey(const Key('enumRadio_0'));
    expect(radio0, findsOneWidget);
    await tester.tap(radio0);
    await tester.tap(submitButton);
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 0.2,
        'integer': -3,
        'boolean': true,
        'enum': 'b',
        'enumRadio': 2,
        'arrayCheckbox': [],
      },
    );

    await utils.findAndEnterText('date', '2023-04-02');
    await utils.findAndEnterText('dateTime', '2021-12-27 13:01:49');
    await tester.tap(submitButton);
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 0.2,
        'integer': -3,
        'boolean': true,
        'enum': 'b',
        'enumRadio': 2,
        'date': '2023-04-02',
        'dateTime': '2021-12-27 13:01:49',
        'arrayCheckbox': [],
      },
    );

    int i = 0;
    for (final position in LabelPosition.values) {
      setState(() {
        labelPosition = position;
      });
      await tester.pump();
      expect(find.text('stringTitle'), findsOneWidget);
      expect(find.text('numberTitle'), findsOneWidget);
      expect(find.text('integerTitle'), findsOneWidget);
      expect(find.text('booleanTitle'), findsOneWidget);
      expect(find.text('enumTitle'), findsOneWidget);
      expect(find.text('enumRadioTitle'), findsOneWidget);
      expect(find.text('dateTitle'), findsOneWidget);
      expect(find.text('dateTimeTitle'), findsOneWidget);

      await utils.findAndEnterText('string', 'hello$i');
      await utils.findAndEnterText('number', '$i');
      await utils.findAndEnterText('integer', '$i');
      await utils.tapButton('boolean');
      // Cancel controller update
      if (i != 0) await utils.tapButton('boolean');

      await utils.tapButton('enum');
      await tester.tap(find.byKey(Key('enum_${i % 4}')), warnIfMissed: false);
      await tester.pump();
      await utils.tapButton('enumRadio_${i % 3}');
      await utils.findAndEnterText('date', '2023-04-0${i + 1}');
      await utils.findAndEnterText('dateTime', '2021-12-2${i + 1} 13:01:49');

      final newArrayCheckbox = const [
        ['e'],
        ['f'],
        [],
        ['e', 'f'],
      ][i % 4];
      await utils.updateUiArrayCheckbox(
        'arrayCheckbox',
        ['e', 'f'],
        newArrayCheckbox,
      );

      await utils.tapSubmitButton();
      final previousValues = {
        'string': 'hello$i',
        'number': i.toDouble(),
        'integer': i,
        // table label position changes key state
        'boolean': i.isOdd, // i >=2  ? i.isEven :
        'enum': const ['a', 'b', 'c', 'd'][i % 4],
        'enumRadio': ((i % 3) + 1) * 2,
        'date': '2023-04-0${i + 1}',
        'dateTime': '2021-12-2${i + 1} 13:01:49',
        'arrayCheckbox': newArrayCheckbox,
      };
      expect(data, previousValues);

      final nextValues = {
        'string': 'hi$i',
        'number': (i + 10).toDouble(),
        'integer': i + 20,
        // table label position changes key state
        'boolean': i.isEven, // i >=2  ? i.isEven :
        'enum': const ['a', 'b', 'c', 'd'][i % 4],
        'enumRadio': ((i % 3) + 1) * 2,
        'date': '2023-05-0${i + 1}',
        'dateTime': '2021-11-2${i + 1} 12:01:48',
        'arrayCheckbox': [
          ['e'],
          ['f'],
          [],
          ['e', 'f'],
        ][(i + 2) % 4],
      };
      for (final key in nextValues.keys) {
        final field = controller.retrieveField(key)!;
        expect(field.property.idKey, key);
        expect(field.property.title, '${key}Title');

        final isDate = key.startsWith('date');
        // Check current value
        expect(
          field.value,
          isDate
              ? DateTime.parse(previousValues[key] as String)
              : previousValues[key],
        );
        final value = nextValues[key];
        // Update value
        field.value = isDate ? DateTime.parse(value as String) : value;
        await tester.pump();
        // Validate updated value in the UI
        if (value is List) {
          expect(
            utils.getUiArrayCheckbox('arrayCheckbox', ['e', 'f']),
            value,
          );
        } else if (value is bool) {
          final checkbox =
              tester.firstState<FormFieldState<bool>>(find.byKey(Key(key)));
          expect(checkbox.value, value);
        } else {
          expect(find.text(value.toString()), findsOne);
        }
      }
      await utils.tapSubmitButton();
      expect(data, nextValues);

      i++;
    }
  });

  testWidgets('array', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
          "type": "object",
          "properties": {
            "array": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "uniqueItems": true,
              "minItems": 2,
              "maxItems": 3
            },
            "arrayWithObjects": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "value": {
                    "type": "boolean"
                  },
                  "value2": {
                    "type": "boolean",
                    "default": true
                  }
                }
              }
            },
            "integer": {
              "type": "integer"
            }
          }
        }''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    await utils.tapSubmitButton();
    expect(find.text('You must add at least 2 items'), findsOneWidget);

    final arrayAdd = find.byKey(const Key('addItem_array'));
    expect(arrayAdd, findsOneWidget);
    await tester.tap(arrayAdd);
    await tester.pump();
    final array0Input = await utils.findAndEnterText('array.1', 'text0');

    await tester.tap(arrayAdd);
    await tester.pump();
    final array1Input = await utils.findAndEnterText('array.2', 'text1');
    expect(data, {});
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text0', 'text1'],
      'arrayWithObjects': [],
    });

    await tester.enterText(array1Input, 'text0');
    await utils.tapSubmitButton();
    expect(find.text('Items must be unique'), findsOneWidget);

    await tester.tap(arrayAdd);
    await tester.pump();
    await utils.findAndEnterText('array.3', 'text2');

    final array1Remove = find.byKey(const Key('removeItem_array.2'));
    expect(array1Remove, findsOneWidget);
    await tester.tap(array1Remove);
    await tester.pump();
    expect(find.byKey(const Key('removeItem_array.2')), findsNothing);

    await tester.tap(arrayAdd);
    await tester.pump();

    await tester.enterText(array0Input, 'text00');
    expect(data, {
      'array': ['text00', 'text2', null],
      'arrayWithObjects': [],
    });

    await utils.tapSubmitButton();
    expect(find.text('Items must be unique'), findsNothing);

    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);
    await tester.tap(arrayAdd);
    await tester.pump();
    // No item added
    expect(data, {
      'array': ['text00', 'text2', null],
      'arrayWithObjects': [],
    });

    await utils.findAndEnterText('array.4', 'text3');
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2', 'text3'],
      'arrayWithObjects': [],
    });
    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);

    final array3Remove = find.byKey(const Key('removeItem_array.4'));
    expect(array3Remove, findsOneWidget);
    await tester.tap(array3Remove);
    await utils.tapSubmitButton();
    await tester.pump();
    expect(data, {
      'array': ['text00', 'text2'],
      'arrayWithObjects': [],
    });

    final arrayWithObjectsAdd =
        find.byKey(const Key('addItem_arrayWithObjects'));
    expect(arrayWithObjectsAdd, findsOneWidget);
    await tester.tap(arrayWithObjectsAdd);
    await tester.pump();

    await utils.findAndEnterText('integer', '2');

    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2'],
      'arrayWithObjects': [
        {'value': false, 'value2': true},
      ],
      'integer': 2,
    });

    final arrayWithObjectsValue =
        find.byKey(const Key('arrayWithObjects.1.value'));
    expect(arrayWithObjectsValue, findsOneWidget);
    await tester.tap(arrayWithObjectsValue);
    final arrayWithObjectsValue2 =
        find.byKey(const Key('arrayWithObjects.1.value2'));
    expect(arrayWithObjectsValue2, findsOneWidget);
    await tester.tap(arrayWithObjectsValue2);
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2'],
      'arrayWithObjects': [
        {'value': true, 'value2': false},
      ],
      'integer': 2,
    });
  });

  testWidgets('nested object', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
          "type": "object",
          "properties": {
            "object1": {
              "type": "object",
              "properties": {
                "objectNested": {
                  "type": "object",
                  "required": ["value"],
                  "properties": {
                    "valueNested": {
                      "type": "boolean"
                    },
                    "value": {
                      "type": "string",
                      "minLength": 1,
                      "maxLength": 2,
                      "pattern": "^[a-b]+\$"
                    }
                  }
                }
              }
            },
            "object2": {
              "type": "object",
              "properties": {
                "value": {
                  "type": "string",
                  "default": "default",
                  "minLength": 2
                }
              }
            }
          }
        }''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    await utils.tapSubmitButton();
    expect(data, {});
    expect(find.text('Required'), findsOneWidget);

    final valueNested =
        find.byKey(const Key('object1.objectNested.valueNested'));
    expect(valueNested, findsOneWidget);
    await tester.tap(valueNested);
    await utils.findAndEnterText('object1.objectNested.value', 'a');

    await utils.tapSubmitButton();
    expect(data, {
      'object1': {
        'objectNested': {'valueNested': true, 'value': 'a'},
      },
      'object2': {'value': 'default'},
    });

    await tester.tap(valueNested);
    await utils.findAndEnterText('object1.objectNested.value', 'abc');
    await utils.findAndEnterText('object2.value', 'd');

    await utils.tapSubmitButton();
    // expect(
    //   find.text('Should be less than 2 characters\nNo match for ^[a-b]+\$'),
    //   findsOneWidget,
    // );
    expect(find.text('Should be at least 2 characters'), findsOneWidget);

    await utils.findAndEnterText('object1.objectNested.value', 'ac');
    await utils.findAndEnterText('object2.value', 'd2');
    await utils.tapSubmitButton();
    // expect(find.text('No match for ^[a-b]+\$'), findsOneWidget);
    expect(find.text('Should be at least 2 characters'), findsNothing);
    expect(data, {
      'object1': {
        'objectNested': {'valueNested': false, 'value': 'a'},
      },
      'object2': {'value': 'd2'},
    });

    await utils.findAndEnterText('object1.objectNested.value', 'ab');
    await utils.tapSubmitButton();
    expect(find.text('No match for ^[a-b]+\$'), findsNothing);
    expect(data, {
      'object1': {
        'objectNested': {'valueNested': false, 'value': 'ab'}
      },
      'object2': {'value': 'd2'},
    });
  });

  testWidgets('metadata: title, description and ui', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    late void Function(void Function()) setState;
    // TODO: imports
    JsonFormController? controller;
    const jsonSchemaString = '''{
          "type": "object",
          "properties": {
            "stringTop": {
              "type": "string"
            },
            "integerRange": {
              "type": "integer",
              "minimum": -3,
              "maximum": 5,
              "multipleOf": 2
            },
            "integerRadio": {
              "type": "integer",
              "minimum": -1,
              "maximum": 3
            },
            "enumValues": {
              "type": "string",
              "enum": ["n1", "n2", "n3"]
            },
            "arrayCheckbox": {
              "type": "array",
              "uniqueItems": true,
              "items": {
                "type": "string",
                "enum": ["n1", "n2", "n3"]
              }
            },
            "arrayString": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "object": {
              "type": "object",
              "properties": {
                "nameEnabled": {
                  "type": "string"
                },
                "nameDisabled": {
                  "type": "string",
                  "default": "disabled default"
                },
                "boolReadOnly": {
                  "type": "boolean",
                  "default": true
                },
                "nameHidden": {
                  "type": "string"
                }
              }
            }
          }
        }''';
    String? uiSchemaString = '''{
          "ui:order": [
                      "integerRadio",
                      "stringTop",
                      "integerRange",
                      "arrayString",
                      "enumValues",
                      "arrayCheckbox",
                      "object"],
          "stringTop": {
            "ui:autoFocus": true,
            "ui:autoComplete": true,
            "ui:placeholder": "My Object Placeholder"
          },
          "integerRange": {
            "ui:widget": "range"
          },
          "integerRadio": {
            "ui:widget": "radio"
          },
          "object": {
            "ui:options": {
              "description": "My Description",
              "order": ["nameDisabled", "nameEnabled", "boolReadOnly"]
            },
            "ui:title": "My Object UI",
            "ui:help": "My Object Help",
            "nameDisabled": {
              "ui:disabled": true
            },
            "boolReadOnly": {
              "ui:readonly": true
            },
            "nameHidden": {
              "ui:emptyValue": "empty",
              "ui:hidden": true
            }
          },
          "arrayCheckbox": {
            "ui:widget": "checkboxes",
            "ui:inline": true
          },
          "arrayString": {
            "ui:orderable": true
          },
          "enumValues": {
            "ui:options": {
              "enumNames": ["n1", "n2", "n3"],
              "enumDisabled": ["n2"]
            }
          }
        }''';
    // TODO: inline
    final uiSchema = UiSchemaData()
      ..setUi(
        jsonDecode(uiSchemaString) as Map<String, Object?>,
        parent: null,
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, _setState) {
              setState = _setState;
              return JsonForm(
                jsonSchema: jsonSchemaString,
                uiSchema: uiSchemaString,
                controller: controller,
                onFormDataSaved: (p) => data = p,
              );
            },
          ),
        ),
      ),
    );
    final currentData = {
      'object': {
        'nameDisabled': 'disabled default',
        'boolReadOnly': true,
        'nameEnabled': null,
      },
      'integerRadio': null,
      'integerRange': -2,
      'arrayString': [],
      'arrayCheckbox': [],
      'stringTop': null,
      'enumValues': null,
    };
    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.tapButton('integerRadio_0');
    currentData['integerRadio'] = -1;
    await utils.tapSubmitButton();
    expect(data, currentData);

    expect(find.text('My Object Placeholder'), findsOneWidget);

    final rangeSlider = await utils.tapButton('integerRange');
    await tester.drag(rangeSlider, const Offset(100, 0));
    currentData['integerRange'] = 2;
    await utils.tapSubmitButton();
    expect(data, currentData);

    /// Array
    await utils.tapButton('addItem_arrayString');
    await tester.pump();

    currentData['arrayString'] = [null];
    await utils.tapSubmitButton();
    expect(data, currentData);

    final arrayCopy = find.byKey(const Key('copyItem_arrayString.1'));
    expect(arrayCopy, findsOneWidget);
    await utils.findAndEnterText('arrayString.1', 'text0');

    currentData['arrayString'] = ['text0'];
    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.tapButton('copyItem_arrayString.1');
    await tester.pump();

    currentData['arrayString'] = ['text0', 'text0'];
    await utils.tapSubmitButton();
    expect(data, currentData);

    expect(find.text('text0'), findsExactly(2));
    await utils.findAndEnterText('arrayString.2', 'text1');
    expect(find.text('text0'), findsOneWidget);

    currentData['arrayString'] = ['text0', 'text1'];
    await utils.tapSubmitButton();
    expect(data, currentData);
    // TODO: test reorder/draggable

    await utils.tapButton('enumValues');
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('enumValues_1')),
      warnIfMissed: false,
    );
    await tester.pump();

    // // no change since enumValues_1 is disabled
    // currentData['enumValues'] = null;
    // await utils.tapSubmitButton();
    // expect(data, currentData);

    await tester.tap(
      find.byKey(const Key('enumValues_0')),
      warnIfMissed: false,
    );
    await tester.pump();

    currentData['enumValues'] = 'n1';
    await utils.tapSubmitButton();
    expect(data, currentData);

    final checkbox0 = find.byKey(const Key('JsonForm_item_arrayCheckbox_0'));
    expect(checkbox0, findsOneWidget);
    await tester.tap(checkbox0);

    currentData['arrayCheckbox'] = ['n1'];
    await utils.tapSubmitButton();
    expect(data, currentData);

    final checkbox1 = find.byKey(const Key('JsonForm_item_arrayCheckbox_1'));
    expect(checkbox1, findsOneWidget);
    await tester.tap(checkbox1);

    currentData['arrayCheckbox'] = ['n1', 'n2'];
    await utils.tapSubmitButton();
    expect(data, currentData);

    await tester.tap(checkbox0);
    currentData['arrayCheckbox'] = ['n2'];
    await utils.tapSubmitButton();
    expect(data, currentData);

    for (int i = 0; i < 2; i++) {
      switch (i) {
        case 0:
          setState(() {
            uiSchemaString = jsonEncode(uiSchema.toJson());
          });
          break;
        case 1:
          setState(() {
            uiSchemaString = null;
            final mainSchema = Schema.fromJson(
              jsonDecode(jsonSchemaString) as Map<String, Object?>,
            );
            mainSchema.setUiSchema(uiSchema.toJson(), fromOptions: false);
            controller = JsonFormController(
              data: data as Map<String, dynamic>,
              mainSchema: mainSchema,
            );
          });
          break;
        default:
      }
      await tester.pump();
    }
  });

  // TODO:
  // format
  // readOnly

  testWidgets('defs and refs', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
  "type": "object",
  "properties": {
    "user": {
      "\$ref": "#/\$defs/user"
    },
    "parent": {
      "\$ref": "#/\$defs/user"
    },
    "address": {
      "\$ref": "#/\$defs/address"
    }
  },
  "\$defs": {
    "user": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        },
        "location": {
          "\$ref": "#/\$defs/address"
        }
      }
    },
    "address": {
      "type": "string"
    }
  }
}''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    final Map<String, Object?> currentData = {
      'user': <String, Object?>{'name': null, 'location': null},
      'parent': <String, Object?>{'name': null, 'location': null},
      'address': null,
    };

    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.findAndEnterText('user.name', 'un');
    (currentData['user'] as Map)['name'] = 'un';
    await utils.findAndEnterText('parent.location', 'pl');
    (currentData['parent'] as Map)['location'] = 'pl';
    await utils.findAndEnterText('address', 'a');
    currentData['address'] = 'a';

    await utils.tapSubmitButton();
    expect(data, currentData);
  });

  testWidgets('dependencies', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
  "type": "object",
  "properties": {
    "user": {
      "\$ref": "#/\$defs/user"
    },
    "parentId": {
      "type": "string",
      "title": "Parent ID",
      "maxLength": 5
    },
    "address": {
      "type": "string"
    }
  },
  "\$defs": {
    "user": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        }
      }
    }
  },
  "dependentRequired": {
    "parentId": ["address"]
  },
  "dependentSchemas": {
    "parentId": {
      "type": "object",
      "properties": {
        "parentName": {
          "type": "string"
        }
      }
    }
  }
}''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    final Map<String, Object?> currentData = {
      'user': <String, Object?>{'name': null},
      'parentId': null,
      'address': null,
    };

    expect(find.text('parentName'), findsNothing);
    await utils.tapSubmitButton();
    expect(data, currentData);
    expect(find.text('parentName'), findsNothing);
    expect(find.text('Required'), findsNothing);

    await utils.findAndEnterText('parentId', '12345');
    currentData['parentId'] = '12345';
    // parentName is shown
    expect(find.text('parentName'), findsOneWidget);
    await utils.tapSubmitButton();
    expect(data, currentData);
    // address is required
    expect(find.text('Required'), findsOneWidget);

    await utils.findAndEnterText('address', 'a');
    currentData['address'] = 'a';
    // TODO: should it be before?
    currentData['parentName'] = null;
    await utils.tapSubmitButton();
    expect(data, currentData);
    expect(find.text('Required'), findsNothing);

    await utils.findAndEnterText('parentName', 'pn');
    currentData['parentName'] = 'pn';
    await utils.tapSubmitButton();
    expect(data, currentData);
  });

  testWidgets('one of dependencies', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
  "title": "One Of Dependencies",
  "description": "Dynamically renders different fields based on the value of an enum. Uses dependencies and one of to configure de variants.",
  "type": "object",
  "properties": {
    "Do you have any pets?": {
      "type": "string",
      "enum": ["No", "Yes: One", "Yes: More than one"],
      "default": "No"
    }
  },
  "required": ["Do you have any pets?"],
  "dependencies": {
    "Do you have any pets?": {
      "oneOf": [
        {
          "properties": {
            "Do you have any pets?": {
              "enum": ["No"]
            }
          }
        },
        {
          "properties": {
            "Do you have any pets?": {
              "enum": ["Yes: One"]
            },
            "How old is your pet?": {
              "type": "number"
            }
          },
          "required": ["How old is your pet?"]
        },
        {
          "properties": {
            "Do you have any pets?": {
              "const": "Yes: More than one"
            },
            "Do you want to get rid of any?": {
              "type": "boolean"
            }
          },
          "required": ["Do you want to get rid of any?"]
        }
      ]
    }
  }
}''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    const haveAny = 'Do you have any pets?';
    final Map<String, Object?> currentData = {
      haveAny: "No",
    };

    await utils.tapSubmitButton();
    expect(data, currentData);
    expect(find.text('How old is your pet?'), findsNothing);

    /// Tap "Yes: One"
    await utils.tapButton(haveAny);
    await tester.tap(
      find.byKey(const Key('${haveAny}_1')),
      warnIfMissed: false,
    );
    await tester.pump();
    currentData[haveAny] = "Yes: One";
    expect(find.text('How old is your pet?'), findsOneWidget);

    await utils.tapSubmitButton();
    expect(find.text('Required'), findsOneWidget);

    await utils.findAndEnterText('How old is your pet?', '2');
    currentData['How old is your pet?'] = 2;
    await utils.tapSubmitButton();
    expect(find.text('Required'), findsNothing);
    expect(data, currentData);

    /// Tap "Yes: More than one"
    const getRid = 'Do you want to get rid of any?';
    expect(find.text(getRid), findsNothing);

    await utils.tapButton(haveAny);
    await tester.tap(
      find.byKey(const Key('${haveAny}_2')),
      warnIfMissed: false,
    );
    // await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    currentData[haveAny] = 'Yes: More than one';
    expect(find.text(getRid), findsOneWidget);
    currentData[getRid] = false;

    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.tapButton(getRid);
    currentData[getRid] = true;
    await utils.tapSubmitButton();
    expect(data, currentData);
  });
}
