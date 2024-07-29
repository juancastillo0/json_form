import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/widget_builder.dart';
import 'package:flutter_jsonschema_builder/src/models/json_form_schema_style.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUtils {
  final WidgetTester tester;

  TestUtils(this.tester);

  Future<Finder> findAndEnterText(String key, String text) async {
    final input = find.byKey(Key(key));
    expect(input, findsOneWidget);
    await tester.enterText(input, text);
    await tester.pump();
    return input;
  }

  Finder findSubmitButton() {
    final submitButton = find.byKey(const Key('JsonForm_submitButton'));
    expect(submitButton, findsOneWidget);
    return submitButton;
  }
}

void main() {
  testWidgets('primitives', (tester) async {
    final utils = TestUtils(tester);
    late void Function(void Function()) setState;
    LabelPosition labelPosition = LabelPosition.top;
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState_) {
              setState = setState_;
              return JsonForm(
                jsonSchema: '''{
          "type": "object",
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
            }
          }
        }''',
                onFormDataSaved: (p) => data = p,
                uiConfig: JsonFormSchemaUiConfig(
                  labelPosition: labelPosition,
                ),
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

    final submitButton = utils.findSubmitButton();
    await tester.tap(submitButton);
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 2.0,
        'boolean': false,
      },
    );

    final integerInput = find.byKey(const Key('integer'));
    expect(integerInput, findsOneWidget);
    await tester.enterText(integerInput, '-3');
    await tester.enterText(numberInput, '.2');
    await tester.pump();

    final booleanInput = find.byKey(const Key('boolean'));
    expect(booleanInput, findsOneWidget);
    await tester.tap(booleanInput);
    await tester.tap(submitButton);
    await tester.pump();
    expect(
      data,
      {
        'string': 'hello',
        'number': 0.2,
        'integer': -3,
        'boolean': true,
      },
    );

    int i = 0;
    for (final position in LabelPosition.values) {
      i++;
      setState(() {
        labelPosition = position;
      });
      await tester.pump();
      expect(find.text('stringTitle'), findsOneWidget);
      expect(find.text('numberTitle'), findsOneWidget);
      expect(find.text('integerTitle'), findsOneWidget);
      expect(find.text('booleanTitle'), findsOneWidget);

      await utils.findAndEnterText('string', 'hello$i');
      await utils.findAndEnterText('number', '$i');
      await utils.findAndEnterText('integer', '$i');
      await tester.tap(booleanInput);
      await tester.tap(submitButton);
      await tester.pump();
      expect(
        data,
        {
          'string': 'hello$i',
          'number': i.toDouble(),
          'integer': i,
          'boolean': i.isEven,
        },
      );
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

    final submitButton = utils.findSubmitButton();
    await tester.tap(submitButton);
    await tester.pump();
    expect(find.text('You must add at least 2 items'), findsOneWidget);

    final arrayAdd = find.byKey(const Key('addItem_array'));
    expect(arrayAdd, findsOneWidget);
    await tester.tap(arrayAdd);
    await tester.pump();

    final array0Input = utils.findAndEnterText('array.0', 'text0');
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
                  "properties": {
                    "valueNested": {
                      "type": "boolean"
                    }
                  }
                }
            },
            "object2": {
              "type": "object",
              "properties": {
                "value2": {
                  type: "string"
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
  });

  testWidgets('metadata: title and description', (tester) async {
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
