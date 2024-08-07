import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/widget_builder.dart';
import 'package:flutter_jsonschema_builder/src/models/json_form_schema_style.dart';
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
}

void main() {
  testWidgets('primitives and labels/titles', (tester) async {
    final utils = TestUtils(tester);
    late void Function(void Function()) setState;
    LabelPosition labelPosition = LabelPosition.top;
    Object? data = {};
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
            }
          }
        }''',
                onFormDataSaved: (p) => data = p,
                uiConfig: JsonFormSchemaUiConfig(
                  labelPosition: labelPosition,
                ),
                uiSchema: '''{
                  "enumRadio": {
                    "ui:widget": "radio"
                  }
                }''',
              );
            },
          ),
        ),
      ),
    );
    expect(data, {});

    // TODO: use JsonFormInput_string as Key?
    await utils.findAndEnterText('string', 'hello');
    final numberInput = await utils.findAndEnterText('number', '2');
    expect(data, {});

    final submitButton = await utils.tapSubmitButton();
    expect(
      data,
      {
        'string': 'hello',
        'number': 2.0,
        'boolean': false,
        'enum': null,
        'enumRadio': null,
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

      await utils.tapButton('enum');
      await tester.tap(find.byKey(Key('enum_${i % 4}')), warnIfMissed: false);
      await tester.pump();
      await utils.tapButton('enumRadio_${i % 3}');
      await utils.findAndEnterText('date', '2023-04-0${i + 1}');
      await utils.findAndEnterText('dateTime', '2021-12-2${i + 1} 13:01:49');

      await utils.tapSubmitButton();
      expect(
        data,
        {
          'string': 'hello$i',
          'number': i.toDouble(),
          'integer': i,
          // table label position changes key state
          'boolean': i.isOdd, // i >=2  ? i.isEven :
          'enum': const ['a', 'b', 'c', 'd'][i % 4],
          'enumRadio': ((i % 3) + 1) * 2,
          'date': '2023-04-0${i + 1}',
          'dateTime': '2021-12-2${i + 1} 13:01:49',
        },
      );
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
    final array0Input = await utils.findAndEnterText('array.0', 'text0');

    await tester.tap(arrayAdd);
    await tester.pump();
    final array1Input = await utils.findAndEnterText('array.1', 'text1');
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
    await utils.findAndEnterText('array.2', 'text2');

    final array1Remove = find.byKey(const Key('removeItem_array.1'));
    expect(array1Remove, findsOneWidget);
    await tester.tap(array1Remove);
    await tester.pump();
    expect(find.byKey(const Key('removeItem_array.1')), findsNothing);

    await tester.tap(arrayAdd);
    await tester.pump();

    await tester.enterText(array0Input, 'text00');
    expect(data, {
      'array': ['text00', 'text2', null],
      'arrayWithObjects': [],
    });

    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2', ''],
      'arrayWithObjects': [],
    });
    expect(find.text('Items must be unique'), findsNothing);

    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);
    await tester.tap(arrayAdd);
    await tester.pump();
    // No item added
    expect(data, {
      'array': ['text00', 'text2', ''],
      'arrayWithObjects': [],
    });

    await utils.findAndEnterText('array.3', 'text3');
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2', 'text3'],
      'arrayWithObjects': [],
    });
    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);

    final array3Remove = find.byKey(const Key('removeItem_array.3'));
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
        find.byKey(const Key('arrayWithObjects.0.value'));
    expect(arrayWithObjectsValue, findsOneWidget);
    await tester.tap(arrayWithObjectsValue);
    final arrayWithObjectsValue2 =
        find.byKey(const Key('arrayWithObjects.0.value2'));
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
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''{
          "type": "object",
          "title": "My Form",
          "description": "This is a form",
          "properties": {
            "object": {
              "title": "My Object",
              "description": "This is an object",
              "type": "object",
              "properties": {
                "value": {
                  "title": "My String",
                  "description": "This is a string",
                  type: "string"
                },
                "boolean1": {
                  "title": "My Boolean",
                  "description": "This is a boolean",
                  type: "boolean"
                }
              }
            },
            "array1": {
              "title": "My Array",
              "description": "This is an array",
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "integer1": {
              "title": "My Integer",
              "description": "This is an integer",
              "type": "integer"
            }
          }
        }''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );
  });
}
