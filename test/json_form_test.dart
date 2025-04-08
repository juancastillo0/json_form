import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/builder/widget_builder.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

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

  List<Object?> getUiArrayCheckbox(String key, List<Object?> options) {
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
    List<Object?> options,
    List<Object?> newValues,
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

  Future<void> petsDependencies(
    Map<String, Object?> currentData,
    String? prop,
    Object? Function() data,
  ) async {
    final toUpdate =
        prop == null ? currentData : currentData[prop]! as Map<String, Object?>;
    final propKey = prop == null ? '' : '$prop.';

    await tapSubmitButton();
    expect(data(), currentData);
    expect(find.text('How old is your pet?'), findsNothing);

    /// Tap "Yes: One"
    const haveAny = 'Do you have any pets?';
    await tapButton('$propKey$haveAny');
    await tester.tap(
      find.byKey(Key('$propKey${haveAny}_1')),
      warnIfMissed: false,
    );
    await tester.pump();
    toUpdate[haveAny] = 'Yes: One';
    expect(find.text('How old is your pet?'), findsOneWidget);

    await tapSubmitButton();
    expect(find.text('Required'), findsOneWidget);

    await findAndEnterText('${propKey}How old is your pet?', '2');
    toUpdate['How old is your pet?'] = 2;
    await tapSubmitButton();
    expect(find.text('Required'), findsNothing);
    expect(data(), currentData);

    /// Tap "Yes: More than one"
    const getRid = 'Do you want to get rid of any?';
    expect(find.text(getRid), findsNothing);

    await tapButton('$propKey$haveAny');
    await tester.tap(
      find.byKey(Key('$propKey${haveAny}_2')),
      warnIfMissed: false,
    );
    // await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    toUpdate[haveAny] = 'Yes: More than one';
    expect(find.text(getRid), findsOneWidget);
    toUpdate[getRid] = false;
    toUpdate.remove('How old is your pet?');

    await tapSubmitButton();
    expect(data(), currentData);

    await tapButton('$propKey$getRid');
    toUpdate[getRid] = true;
    await tapSubmitButton();
    expect(data(), currentData);
  }
}

void main() {
  testWidgets('primitives and labels/titles', (tester) async {
    final utils = TestUtils(tester);
    late void Function(void Function()) setState;
    LabelPosition labelPosition = LabelPosition.top;
    Map<String, Object?> data = {};
    final controller = JsonFormController(initialData: data);
    // TODO: file, color
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState_) {
              setState = setState_;
              return JsonForm(
                jsonSchema: primitivesJsonSchema,
                onFormDataSaved: (p) => data = p as Map<String, Object?>,
                controller: controller,
                uiConfig: JsonFormUiConfig(
                  labelPosition: labelPosition,
                ),
                uiSchema: primitivesUiSchema,
              );
            },
          ),
        ),
      ),
    );
    final updates = <JsonFormUpdate<Object?>>[];
    void addUpdateEvent() {
      updates.add(controller.lastEvent!);
    }

    controller.addListener(addUpdateEvent);

    var currentValues = <String, Object?>{
      'string': null,
      'number': null,
      'integer': null,
      'boolean': null,
      'enum': null,
      'enumRadio': null,
      'date': null,
      'dateTime': null,
      'arrayCheckbox': null,
    };
    expect(data, currentValues);

    // TODO: use JsonFormInput_string as Key?
    await utils.findAndEnterText('string', 'hello');
    expect(updates, hasLength(1));
    expect(
      updates.last.toString(),
      JsonFormUpdate(
        field: controller.retrieveField('string')!,
        newValue: 'hello',
        previousValue: null,
      ).toString(),
    );
    final numberInput = await utils.findAndEnterText('number', '2');
    currentValues['string'] = 'hello';
    currentValues['number'] = 2.0;
    expect(data, currentValues);

    await utils.tapSubmitButton();
    currentValues['arrayCheckbox'] = <Object?>[];
    currentValues['boolean'] = false;
    expect(data, currentValues);

    final integerInput = find.byKey(const Key('integer'));
    expect(integerInput, findsOneWidget);
    await tester.enterText(integerInput, '-3');
    currentValues['integer'] = -3;
    await tester.enterText(numberInput, '.2');
    currentValues['number'] = 0.2;
    await tester.pump();
    await utils.tapButton('boolean');
    currentValues['boolean'] = true;
    await utils.tapSubmitButton();
    expect(data, currentValues);

    final enumDropDown = find.byKey(const Key('enum'));
    expect(enumDropDown, findsOneWidget);
    await tester.tap(enumDropDown);
    await tester.pump();
    await tester.tap(find.byKey(const Key('enum_1')), warnIfMissed: false);
    await tester.pump();
    currentValues['enum'] = 'b';
    await utils.tapSubmitButton();
    await tester.pump();
    expect(data, currentValues);

    final radio0 = find.byKey(const Key('enumRadio_0'));
    expect(radio0, findsOneWidget);
    await tester.tap(radio0);
    currentValues['enumRadio'] = 2;
    await utils.tapSubmitButton();
    expect(data, currentValues);

    await utils.findAndEnterText('date', currentValues['date'] = '2023-04-02');
    expect(updates, hasLength(9));
    await utils.findAndEnterText(
      'dateTime',
      currentValues['dateTime'] = '2021-12-27 13:01:49',
    );
    expect(updates, hasLength(10));
    expect(
      updates.last.toString(),
      JsonFormUpdate(
        field: controller.retrieveField('dateTime')!,
        newValue: currentValues['dateTime'],
        previousValue: null,
      ).toString(),
    );
    await utils.tapSubmitButton();
    expect(data, currentValues);

    int i = 0;
    for (final position in LabelPosition.values) {
      final previousUpdateIndex = updates.length;
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
        <Object?>[],
        ['e', 'f'],
      ][i % 4];
      await utils.updateUiArrayCheckbox(
        'arrayCheckbox',
        ['e', 'f'],
        newArrayCheckbox,
      );
      expect(
        updates.last.toString(),
        JsonFormUpdate(
          field: controller.retrieveField('arrayCheckbox')!,
          newValue: newArrayCheckbox,
          previousValue: newArrayCheckbox.isEmpty
              ? ['f']
              : ([...newArrayCheckbox]..removeLast()),
        ).toString(),
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

      updates.getRange(previousUpdateIndex, updates.length).forEach((update) {
        if (update.field.idKey == 'boolean' ||
            update.field.idKey == 'arrayCheckbox') {
          return;
        }
        expect(
          update.toString(),
          JsonFormUpdate(
            field: controller.retrieveField(update.field.idKey)!,
            newValue: previousValues[update.field.idKey],
            previousValue: currentValues[update.field.idKey],
          ).toString(),
        );
      });

      currentValues = {
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
          <Object?>[],
          ['e', 'f'],
        ][(i + 2) % 4],
      };
      for (final key in currentValues.keys) {
        final field = controller.retrieveField(key)!;
        expect(field.idKey, key);
        expect(field.property.title, '${key}Title');

        final isDate = key.startsWith('date');
        // Check current value
        expect(
          field.value,
          isDate
              ? DateTime.parse(previousValues[key]! as String)
              : previousValues[key],
        );
        final value = currentValues[key];
        // Update value
        field.value = isDate ? DateTime.parse(value! as String) : value;
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
      expect(data, currentValues);
      i++;
    }
  });

  testWidgets('array', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    final controller = JsonFormController(initialData: data);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            controller: controller,
            jsonSchema: arrayJsonSchema,
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
    expect(
      data,
      {
        'integer': null,
        'array': ['text0', 'text1'],
        'arrayWithObjects': null,
      },
    );
    const arrayWithObjectsV = <Object?>[];
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text0', 'text1'],
      'arrayWithObjects': arrayWithObjectsV,
      'integer': null,
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
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2', null],
      'arrayWithObjects': arrayWithObjectsV,
      'integer': null,
    });
    expect(find.text('Items must be unique'), findsNothing);

    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);
    await tester.tap(arrayAdd);
    await tester.pump();
    // No item added
    expect(data, {
      'array': ['text00', 'text2', null],
      'arrayWithObjects': arrayWithObjectsV,
      'integer': null,
    });

    await utils.findAndEnterText('array.4', 'text3');
    await utils.tapSubmitButton();
    expect(data, {
      'array': ['text00', 'text2', 'text3'],
      'arrayWithObjects': arrayWithObjectsV,
      'integer': null,
    });
    expect(find.byTooltip('You can only add 3 items'), findsOneWidget);

    final array3Remove = find.byKey(const Key('removeItem_array.4'));
    expect(array3Remove, findsOneWidget);
    await tester.tap(array3Remove);
    await utils.tapSubmitButton();
    await tester.pump();
    expect(data, {
      'array': ['text00', 'text2'],
      'arrayWithObjects': arrayWithObjectsV,
      'integer': null,
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
    Map<String, Object?> prev = {
      'array': ['text00', 'text2'],
      'arrayWithObjects': [
        {'value': true, 'value2': false},
      ],
      'integer': 2,
    };
    expect(data, prev);

    final List<JsonFormUpdate<Object?>> updates = [];
    void onChanged() {
      final path = const [
        'array',
        'array',
        'arrayWithObjects',
        // 'arrayWithObjects.1',
        'integer',
        // TODO: should we use 0 as first index?
        'arrayWithObjects.1.value',
        'arrayWithObjects.1',
      ][updates.length];
      final value = const [
        ['other'],
        ['other', 'other2'],
        [
          {'value': false, 'value2': false},
          {'value': false, 'value2': true},
        ],
        // {'value': false, 'value2': false},
        3,
        true,
        {'value': false, 'value2': true},
      ][updates.length];

      Object? val = controller.rootOutputData;
      for (final p in path.split('.')) {
        val = (val as dynamic)[val is List ? int.parse(p) - 1 : p];
      }

      final event = controller.lastEvent!;
      expect(event.newValue, value);
      expect(val, value);
      final d = controller.retrieveData(path);
      final f = controller.retrieveField(path)!;
      if (updates.length == 2) {
        // TODO: f.toJson vs f.value vs rootOutputData
        final nonRenderedValue = [
          {'value': false, 'value2': false},
          <String, Object?>{},
        ];
        expect(f.value, nonRenderedValue);
        expect(d, nonRenderedValue);
      } else {
        expect(f.value, value);
        expect(d, value);
      }
      updates.add(event);
    }

    controller.addListener(onChanged);

    final arrayField = controller.retrieveField('array')!;
    Object? previousValue = arrayField.value;
    arrayField.value = ['other'];

    await utils.tapSubmitButton();
    expect(updates, hasLength(1));
    expect(updates.last.field, arrayField);
    expect(updates.last.previousValue, previousValue);
    expect(updates.last.newValue, arrayField.value);
    expect(data, prev);
    expect(controller.rootOutputData, {
      'array': ['other'],
      'arrayWithObjects': [
        {'value': true, 'value2': false},
      ],
      'integer': 2,
    });

    // must have at least 2 items
    arrayField.value = ['other', 'other2'];
    prev = {
      'array': ['other', 'other2'],
      'arrayWithObjects': [
        {'value': true, 'value2': false},
      ],
      'integer': 2,
    };
    expect(controller.rootOutputData, prev);
    await tester.pump();
    await utils.tapSubmitButton();
    expect(data, prev);

    final arrayWithObjectsField = controller.retrieveField('arrayWithObjects')!;
    previousValue = arrayWithObjectsField.value;
    expect(previousValue, [
      {'value': true, 'value2': false},
    ]);
    arrayWithObjectsField.value = [
      {'value': false, 'value2': false},
      {'value': false, 'value2': true},
    ];
    await tester.pump();
    int numUpdates = 3;
    expect(updates, hasLength(numUpdates));
    expect(updates[2].field, arrayWithObjectsField);
    expect(updates[2].previousValue, previousValue);
    // TODO: .value is not changed right away, it needs to re-render. Don't require pump
    expect(updates[2].newValue, arrayWithObjectsField.value);

    if (numUpdates == 4) {
      final arrayWithObjectsField1 =
          controller.retrieveField('arrayWithObjects.1')!;
      expect(updates.last.field, arrayWithObjectsField1);
      expect(updates.last.newValue, (arrayWithObjectsField.value! as List)[0]);
      expect(updates.last.previousValue, (previousValue! as List)[0]);
    }

    await utils.tapSubmitButton();
    prev = {
      'array': ['other', 'other2'],
      'arrayWithObjects': [
        {'value': false, 'value2': false},
        {'value': false, 'value2': true},
      ],
      'integer': 2,
    };
    expect(data, prev);

    // Integer field
    final integerField = controller.retrieveField('integer')!;
    previousValue = integerField.value;
    expect(previousValue, 2);
    integerField.value = 3;
    expect(updates, hasLength(++numUpdates));
    expect(updates.last.field, integerField);
    expect(updates.last.previousValue, previousValue);
    expect(updates.last.newValue, 3);
    prev['integer'] = 3;

    await utils.tapSubmitButton();
    expect(data, prev);

    // Nested bool field
    final nestedField = controller.retrieveField('arrayWithObjects.1.value')!;
    previousValue = nestedField.value;
    expect(previousValue, false);
    nestedField.value = true;
    expect(updates, hasLength(++numUpdates));
    expect(updates.last.field, nestedField);
    expect(updates.last.previousValue, previousValue);
    expect(updates.last.newValue, true);
    ((prev['arrayWithObjects']! as List)[0] as Map)['value'] = true;

    await utils.tapSubmitButton();
    expect(data, prev);

    // Nested field
    final nestedObjectField = controller.retrieveField('arrayWithObjects.1')!;
    previousValue = nestedObjectField.value;
    expect(previousValue, {'value': true, 'value2': false});
    final newObject = {'value': false, 'value2': true};
    nestedObjectField.value = newObject;
    expect(updates, hasLength(++numUpdates));
    expect(updates.last.field, nestedObjectField);
    expect(updates.last.previousValue, previousValue);
    expect(updates.last.newValue, newObject);
    (prev['arrayWithObjects']! as List)[0] = newObject;

    await utils.tapSubmitButton();
    expect(data, prev);
  });

  testWidgets('nested object', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: nestedObjectJsonSchema,
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    await utils.tapSubmitButton();
    expect(data, <String, Object?>{});
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
    expect(find.text('No match for pattern "^[a-b]+\$"'), findsNothing);
    expect(data, {
      'object1': {
        'objectNested': {'valueNested': false, 'value': 'ab'},
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
    const jsonSchemaString = uiSchemaJsonSchema;
    String? uiSchemaString = uiSchemaUiSchema;
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
      'arrayString': <Object?>[],
      'arrayCheckbox': <Object?>[],
      'stringTop': null,
      'enumValues': null,
    };
    await utils.tapSubmitButton();
    expect(data, currentData);

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is FormField<bool> &&
            !w.enabled &&
            w.key == JsonFormKeys.inputField('object.boolReadOnly'),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is TextFormField &&
            !w.enabled &&
            w.key == JsonFormKeys.inputField('object.nameDisabled') &&
            w.controller!.text == 'disabled default',
      ),
      findsOneWidget,
    );

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
              initialData: data! as Map<String, dynamic>,
            )..mainSchema = mainSchema;
          });
          break;
        default:
      }
      await tester.pump();
    }
  });

  testWidgets('defs and refs', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: defsJsonSchema,
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
    (currentData['user']! as Map)['name'] = 'un';
    await utils.findAndEnterText('parent.location', 'pl');
    (currentData['parent']! as Map)['location'] = 'pl';
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
            jsonSchema: dependenciesJsonSchema,
            onFormDataSaved: (p) => data = p,
            uiConfig: JsonFormUiConfig(
              mapSchemaToTitle: (info) => info.id,
            ),
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

  testWidgets('date and time buttons', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''
{ 
  "type": "object",
  "properties": {
    "dateTime": {
      "type": "string",
      "format": "date-time"
    },
    "date": {
      "type": "string",
      "format": "date"
    }
  }
}''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );

    final Map<String, Object?> currentData = {
      'dateTime': null,
      'date': null,
    };

    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.tapButton(JsonFormKeys.selectDate('dateTime').value);
    expect(
      find.byWidgetPredicate((w) => w is CalendarDatePicker),
      findsOneWidget,
    );

    final now = DateTime.now();
    await tester.tap(
      find.byKey(ValueKey(DateTime(now.year, now.month, 5))),
    );
    await tester.tap(find.text('OK'));
    await tester.pump();

    await utils.tapButton(JsonFormKeys.selectTime('dateTime').value);
    expect(
      find.byWidgetPredicate((w) => w is TimePickerDialog),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pump();

    final isPM = now.hour >= 12;
    final hourMapped = (now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour);
    await tester.enterText(
      find
          .byWidgetPredicate(
            (w) =>
                w is TextFormField &&
                w.restorationId == 'hour_minute_text_form_field' &&
                w.controller!.text == hourMapped.toString(),
          )
          .first,
      '10',
    );
    // TODO: TextPainter await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pump();

    final mon = now.month < 10 ? '0${now.month}' : now.month;
    final min = now.minute < 10 ? '0${now.minute}' : now.minute;

    currentData['dateTime'] =
        '${now.year}-$mon-05 ${isPM ? '22' : '10'}:$min:00';
    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.tapButton(JsonFormKeys.selectDate('date').value);

    expect(
      find.byWidgetPredicate((w) => w is CalendarDatePicker),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pump();
    final day = now.day < 10 ? '0${now.day}' : now.day;
    currentData['date'] = '${now.year}-$mon-$day';

    await utils.tapSubmitButton();
    expect(data, currentData);
  });

  testWidgets('one of dependencies', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonFormUiConfigInherited(
            uiConfig: JsonFormUiConfig(
              mapSchemaToTitle: (info) => info.id,
            ),
            child: JsonForm(
              jsonSchema: oneOfDependenciesJsonSchema,
              onFormDataSaved: (p) => data = p,
            ),
          ),
        ),
      ),
    );

    final Map<String, Object?> currentData = {
      'Do you have any pets?': 'No',
    };
    await utils.petsDependencies(currentData, null, () => data);
  });

  testWidgets('number validation errors', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {
      // TODO: 'stringPattern': '23903',
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: '''
{ 
  "type": "object",
  "properties": {
    "number": {
      "type": "number",
      "minimum": 2,
      "maximum": 12,
      "multipleOf": 2
    },
    "numberExclusive": {
      "type": ["integer", null],
      "exclusiveMinimum": 2,
      "exclusiveMaximum": 10
    }
  }
}''',
            onFormDataSaved: (p) => data = p,
          ),
        ),
      ),
    );
    expect(find.text('pattern'), findsNothing);
    final currentData = <String, Object?>{
      'number': null,
      'numberExclusive': null,
      // TODO:
      // 'stringPattern': '23903',
    };
    await utils.tapSubmitButton();
    expect(data, currentData);

    await utils.findAndEnterText(
      'numberExclusive',
      (currentData['numberExclusive'] = 2).toString(),
    );
    await utils.findAndEnterText(
      'number',
      (currentData['number'] = 3).toString(),
    );
    await utils.tapSubmitButton();
    expect(find.text('The value must be a multiple of 2'), findsOneWidget);
    expect(find.text('The value must be greater than 2'), findsOneWidget);
    // TODO: expect(find.text('No match for pattern "[0-9]{0,5}[a-z]"'), findsOneWidget);

    await utils.findAndEnterText(
      'numberExclusive',
      (currentData['numberExclusive'] = 11).toString(),
    );
    await utils.findAndEnterText(
      'number',
      (currentData['number'] = 0).toString(),
    );
    await utils.tapSubmitButton();
    expect(find.text('11'), findsOneWidget);
    expect(find.text('The value must be less than 10'), findsOneWidget);
    expect(
      find.text('The value must be greater than or equal to 2'),
      findsOneWidget,
    );

    await utils.findAndEnterText(
      'number',
      (currentData['number'] = 4).toString(),
    );
    await utils.findAndEnterText(
      'numberExclusive',
      (currentData['numberExclusive'] = 5).toString(),
    );
    await utils.tapSubmitButton();
    expect(data, currentData);
  });

  testWidgets('one of const', (tester) async {
    final utils = TestUtils(tester);
    Object? data = {};
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: JsonForm(
            jsonSchema: oneOfConstJsonSchema,
            onFormDataSaved: (p) => data = p,
            uiConfig: JsonFormUiConfig(
              mapSchemaToTitle: (info) => info.id,
            ),
          ),
        ),
      ),
    );

    await utils.tapSubmitButton();
    final Map<String, Object?> currentData = {};
    expect(data, currentData);

    const haveAny = 'Do you have any pets?';
    await utils.tapButton('example.$haveAny');
    await tester.tap(
      find.byKey(const Key('example.${haveAny}_0')),
      warnIfMissed: false,
    );
    await tester.pump();
    currentData['example'] = <String, Object?>{
      'Do you have any pets?': 'No',
    };
    currentData['Other Property'] = null;

    await utils.petsDependencies(currentData, 'example', () => data);
  });

  testWidgets('formats, errors and focus', (tester) async {
    final utils = TestUtils(tester);
    Map<String, Object?> data = {};
    final controller = JsonFormController(initialData: data);
    // TODO: file, color
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState_) {
              return JsonForm(
                jsonSchema: formatsJsonSchema,
                onFormDataSaved: (p) {
                  data = p as Map<String, Object?>;
                },
                controller: controller,
                fieldValidator: (field) {
                  switch (field.idKey) {
                    case 'uri':
                      return (uri) => (uri! as String).isEmpty ||
                              Uri.parse(uri as String).isAbsolute
                          ? null
                          : 'Should be absolute URI';
                    case 'numberExclusive':
                      return (n) => (n! as String).isEmpty || n != '6'
                          ? null
                          : 'Should be different than 6';
                    case 'arrayCheckbox':
                      return (a) =>
                          (a! as List).contains(3) && (a as List).contains(5)
                              ? "Can't have 3 and 5 at the same time"
                              : null;
                    default:
                      return null;
                  }
                },
                uiSchema: formatsUiSchema,
              );
            },
          ),
        ),
      ),
    );
    final emailField = controller.retrieveField('email')!;
    expect(emailField.focusNode.hasPrimaryFocus, true);

    final currentData = <String, Object?>{
      'email': null,
      'uri': null,
      'hostname': null,
      'uuid': null,
      'regex': null,
      'ipv4': null,
      'ipv6': null,
      'time': null,
      'number': null,
      'numberExclusive': null,
      'dateTime': null,
      'arrayRoot': null,
      'arrayInts': null,
    };
    expect(data, currentData);

    await utils.tapSubmitButton();
    currentData['arrayRoot'] = [];
    currentData['arrayInts'] = [];

    /// Required
    expect(find.text('Required'), findsExactly(3));

    /// Apply required
    await utils.findAndEnterText(
      'email',
      currentData['email'] = 'hello@mail.com',
    );
    await utils.findAndEnterText(
      'number',
      (currentData['number'] = 4).toString(),
    );
    await utils.findAndEnterText(
      'dateTime',
      currentData['dateTime'] = '2002-03-23 12:34:56',
    );

    await utils.tapSubmitButton();
    expect(find.text('Required'), findsNothing);
    expect(data, currentData);

    /// Formats
    await utils.findAndEnterText(
      'uri',
      currentData['uri'] = 'https://github.com/juancastillo0/json_form',
    );
    await utils.findAndEnterText(
      'uuid',
      currentData['uuid'] = '864f4625-2323-4769-87cf-ec6c20638d0f',
    );
    await utils.findAndEnterText(
      'hostname',
      currentData['hostname'] = 'https://github.com',
    );
    await utils.findAndEnterText(
      'regex',
      currentData['regex'] = '^([a-z]){,2}.\\s\\((0-9)?\\)\$',
    );
    await utils.findAndEnterText(
      'ipv4',
      currentData['ipv4'] = '180.192.242.164',
    );
    await utils.findAndEnterText(
      'ipv6',
      currentData['ipv6'] = 'd3b5:750f:165b:13eb:ac20:ca92:83d3:63cc',
    );
    await utils.findAndEnterText(
      'time',
      currentData['time'] = '06:23:10',
    );
    await utils.findAndEnterText(
      'numberExclusive',
      (currentData['numberExclusive'] = 8).toString(),
    );

    await utils.tapSubmitButton();
    expect(data, currentData);

    /// Array of integers
    await utils.tapButton('addItem_arrayInts');
    // TODO: final arrayIntsField = controller.retrieveField('arrayInts.1')!;
    // TODO: expect(arrayIntsField.focusNode.hasPrimaryFocus, true);
    await utils.findAndEnterText('arrayInts.1', '2');
    await utils.tapSubmitButton();
    expect(find.text('The value must be greater than 2'), findsOneWidget);

    (currentData['arrayInts']! as List).add(3);
    await utils.findAndEnterText('arrayInts.1', '3');
    await utils.tapSubmitButton();
    expect(data, currentData);

    /// Array of root
    await utils.tapButton('addItem_arrayRoot');
    final nestedData = <String, Object?>{
      'email': null,
      'uri': null,
      'hostname': null,
      'uuid': null,
      'regex': null,
      'ipv4': null,
      'ipv6': null,
      'time': null,
      'number': null,
      'numberExclusive': null,
      'arrayRoot': [],
      'dateTime': null,
      'arrayInts': [],
    };
    currentData['arrayRoot'] = [nestedData];

    /// Required
    await utils.tapSubmitButton();
    expect(find.text('Required'), findsExactly(3));

    /// Apply required
    await utils.findAndEnterText(
      'arrayRoot.1.email',
      nestedData['email'] = 'hello@mail.com',
    );
    await utils.findAndEnterText(
      'arrayRoot.1.number',
      (nestedData['number'] = 4).toString(),
    );
    await utils.findAndEnterText(
      'arrayRoot.1.dateTime',
      nestedData['dateTime'] = '2002-03-23 12:34:56',
    );

    await utils.tapSubmitButton();
    expect(find.text('Required'), findsNothing);
    expect(data, currentData);

    await utils.tapButton('copyItem_arrayRoot.1');
    (currentData['arrayRoot']! as List).add(nestedData);
    await utils.tapSubmitButton();
    expect(data, currentData);

    /// Show/hide items
    expect(find.byKey(const Key('copyItem_arrayRoot.1')), findsOneWidget);
    await utils.tapButton('JsonForm_showOrHideItems_arrayRoot');
    expect(find.byKey(const Key('copyItem_arrayRoot.1')), findsNothing);
    await utils.tapButton('JsonForm_showOrHideItems_arrayRoot');
    expect(find.byKey(const Key('copyItem_arrayRoot.1')), findsOneWidget);

    /// Remove items
    expect(find.byKey(const Key('removeItem_arrayRoot.1')), findsNothing);
    expect(find.byKey(const Key('removeItem_arrayInts.1')), findsOneWidget);
    await utils.tapButton('removeItem_arrayInts.1');
    currentData['arrayInts'] = [];
    await utils.tapSubmitButton();
    expect(data, currentData);

    /// Format Errors
    await utils.findAndEnterText(
      'email',
      currentData['email'] = 'not-an-email',
    );
    await utils.findAndEnterText('uri', currentData['uri'] = 'json-form');
    await utils.findAndEnterText('uuid', currentData['uuid'] = '864f4625');
    await utils.findAndEnterText('hostname', currentData['hostname'] = '&^|>');
    await utils.findAndEnterText('regex', currentData['regex'] = '&|)');
    await utils.findAndEnterText('ipv4', currentData['ipv4'] = '180.192');
    await utils.findAndEnterText('ipv6', currentData['ipv6'] = 'd3b5:750f:');
    await utils.findAndEnterText(
      'dateTime',
      currentData['dateTime'] = '2002-03-23 12:34:',
    );
    await utils.findAndEnterText(
      'time',
      currentData['time'] = '06:2',
    );
    await utils.findAndEnterText(
      'numberExclusive',
      (currentData['numberExclusive'] = 6).toString(),
    );

    await utils.tapSubmitButton();
    expect(find.text('Required'), findsNothing);
    expect(find.text('Should be an email'), findsOneWidget);
    expect(find.text('Invalid time'), findsOneWidget);
    expect(find.text('Should be a UUID'), findsOneWidget);
    expect(find.text('Should be a regular expression'), findsOneWidget);
    expect(find.text('Should be an IPv4'), findsOneWidget);
    expect(find.text('Should be an IPv6'), findsOneWidget);
    expect(find.text('Should be a valid URL'), findsOneWidget);
    expect(find.text('Invalid date'), findsOneWidget);
    expect(find.text('Should be different than 6'), findsOneWidget);
    expect(find.text('Should be absolute URI'), findsOneWidget);
  });
}
