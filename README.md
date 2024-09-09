<h3 align="center">json_form</h3>

A [Flutter](https://flutter.dev/) widget capable of using [JSON Schema](http://json-schema.org/) to declaratively build and customize input forms.

Inspired by [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form).


## Table of Contents

- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Examples](#examples)
- [Usage](#usage)
  - [Using arrays \& Files](#using-arrays--files)
  - [Using UI Schema](#using-ui-schema)
    - [UI Schema Configurations](#ui-schema-configurations)
  - [UI Config](#ui-config)
  - [Custom File Handler](#custom-file-handler)
  - [Using Custom Validator](#using-custom-validator)
  - [TODO](#todo)


## Installation

Add dependency to pubspec.yaml

```
dependencies:
  json_form: ^0.0.1+1
```

See the [File Picker Installation](https://github.com/miguelpruivo/plugins_flutter_file_picker) for file fields.


## Examples

You can interact with multiple form examples in the [deployed web page](https://juancastillo0.github.io/json_form/). The code for the page can be found in the [example folder of this repo](./example/lib/main.dart).

## Usage

```dart
import 'package:json_form/json_form.dart';

final jsonSchema = {
  "title": "A registration form",
  "description": "A simple form example.",
  "type": "object",
  "required": [
    "firstName",
    "lastName"
  ],
  "properties": {
    "firstName": {
      "type": "string",
      "title": "First name",
      "default": "Chuck"
    },
    "lastName": {
      "type": "string",
      "title": "Last name"
    },
    "telephone": {
      "type": "string",
      "title": "Telephone",
      "minLength": 10
    }
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: JsonForm(
      jsonSchema: jsonSchema,
      onFormDataSaved: (data) {
        inspect(data);
      },
    ),
  );
}
```

<img width="364" alt="image" src="https://user-images.githubusercontent.com/58694638/187986742-3b1aa96c-4a85-42a3-aec0-dac62a8515a4.png">

### Using arrays & Files
```dart
final jsonSchema = '''
{
  "title": "Example 2",
  "type": "object",
  "properties": {
   "listOfStrings": {
      "type": "array",
      "title": "A list of strings",
      "items": {
        "type": "string",
        "title" : "Write your item",
        "default": "bazinga"
      }
    },
    "files": {
      "type": "array",
      "title": "Multiple files",
      "items": {
        "type": "string",
        "format": "data-url"
      }
    }
  }
}
''';
```

### Using UI Schema

```dart
final uiSchema = '''
{
  "selectYourCola": {
    "ui:widget": "radio"
  }
}
''';
```
<img width="348" alt="image" src="https://user-images.githubusercontent.com/58694638/187996261-ab3be73d-35e0-40c5-a0de-47900b64f1be.png">


#### UI Schema Configurations

| Configuration   | Type            | Default | Only For | Description                                                         |
| --------------- | --------------- | ------- | -------- | ------------------------------------------------------------------- |
| title           | String?         |         |          | The user facing title of the field                                  |
| description     | String?         |         |          | The user facing description of the field                            |
| globalOptions   | UiSchemaData?   |         |          | Applies the options to all children                                 |
| help            | String?         |         |          | Helper text for the user                                            |
| readOnly        | bool            | false   |          | Can't be updated, but will be sent                                  |
| disabled        | bool            | false   |          | Can't be updated and will not be sent                               |
| hidden          | bool            | false   |          | Does not show or sends the value                                    |
| hideError       | bool            | false   |          |                                                                     |
| placeholder     | String?         |         | text     | The input's hint text                                               |
| emptyValue      | String?         |         | text     | Sent when the value is empty                                        |
| autoFocus       | bool            | false   |          | Focuses the input on rendering                                      |
| autoComplete    | bool            | false   | text     | Enabled auto complete suggestions                                   |
| yearsRange      | List\<int\>?    |         | date     |
| format          | String          | 'YMD'   | date     |                                                                     |
| hideNowButton   | bool            | false   | date     |                                                                     |
| hideClearButton | bool            | false   | date     |                                                                     |
| widget          | String?         |         |          | The kind of input to be used. Options:                              |
| accept          | String?         |         | file     | The mime types accepted in the file input                           |
| enumNames       | List\<String\>? |         | enum     | The named or labels shown to the user for each of the enum variants |
| enumDisabled    | List\<String\>? |         | enum     | List of enum values that are disabled                               |
| order           | List\<String\>? |         | object   | The order of the properties of an object                            |
| inline          | bool            | false   | checkbox | Whether the checkboxes are positioned in a horizontal line          |
| addable         | bool            | true    | array    | Whether the user can add items to an array                          |
| removable       | bool            | true    | array    | Whether the user can remove items from an array                     |
| orderable       | bool            | true    | array    | Whether the user can reorder or move the items in an array          |
| copyable        | bool            | true    | array    | Whether the user can copy or duplicate the items in an array        |


### UI Config

| Configuration              | Type                                                          | Default                                                           | Description                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| title                      | TextStyle?                                                    | titleLarge                                                        |                                                                                                                                                           |
| titleAlign                 | TextAlign?                                                    | center                                                            |                                                                                                                                                           |
| subtitle                   | TextStyle?                                                    | titleMedium (bold)                                                |                                                                                                                                                           |
| description                | TextStyle?                                                    | bodyMedium                                                        |                                                                                                                                                           |
| fieldLabel                 | TextStyle?                                                    |                                                                   |                                                                                                                                                           |
| fieldInput                 | TextStyle?                                                    |                                                                   |                                                                                                                                                           |
| fieldInputReadOnly         | TextStyle?                                                    | TextStyle(color: Colors.grey)                                     |                                                                                                                                                           |
| error                      | TextStyle?                                                    | bodySmall (colorScheme.error)                                     | Text style for validation errors                                                                                                                          |
| localizedTexts             | LocalizedTexts                                                | [English](./lib/src/utils/localized_texts.dart)                   | Translations of the standardized texts used within the form. For example, they are used for validation errors and buttons (add, remove, show, hide, ...)  |
| debugMode                  | bool                                                          | false                                                             | Shows an "inspect" button for debugging                                                                                                                   |
| labelPosition              | LabelPosition                                                 | table                                                             | The location of the input field labels. Options: side, top, table, input (InputDecoration)                                                                |
| autovalidateMode           | AutovalidateMode                                              | onUnfocus                                                         | The `Form`'s validation execution                                                                                                                         |
| addItemBuilder             | Widget? Function(VoidCallback onPressed, String key)?         |                                                                   | Add Item button for arrays                                                                                                                                |
| removeItemBuilder          | Widget? Function(VoidCallback onPressed, String key)?         |                                                                   | Remove Item button for arrays                                                                                                                             |
| copyItemBuilder            | Widget? Function(VoidCallback onPressed, String key)?         |                                                                   | Duplicate or Copy Item button for arrays                                                                                                                  |
| submitButtonBuilder        | Widget? Function(VoidCallback onSubmit)?                      | Centered button inside the main scroll                            | The main Submit form button                                                                                                                               |
| addFileButtonBuilder       | Widget? Function(VoidCallback? onPressed, String key)?        |                                                                   |                                                                                                                                                           |
| formBuilder                | Form? Function(GlobalKey\<FormState\> formKey, Widget child)? | 12 of padding over the form                                       | Builds the Form widget you can use it to wrap the whole form                                                                                              |
| formSectionBuilder         | Widget? Function(Widget child)?                               | Left border over a section                                        | Wraps a form section. Objects and arrays create form sections                                                                                             |
| titleAndDescriptionBuilder | Widget? Function(SchemaUiInfo info)?                          | Adds a divider for form sections and top padding for table titles | Returns the title and description widget for a schema. Used within a form section for objects and arrays, and for fields when using `LabelPosition.table` |
| fieldWrapperBuilder        | Widget? Function(FieldWrapperParams params)?                  | Side and top field labels                                         | Wraps the input field and returns it with the label                                                                                                       |
| inputWrapperBuilder        | Widget? Function(FieldWrapperParams params)?                  |                                                                   | Wraps the input field and returns it without the label                                                                                                    |


### Custom File Handler 

```dart
customFileHandler: () => {
  'profile_photo': () async {
    return [
      File(
          'https://cdn.mos.cms.futurecdn.net/LEkEkAKZQjXZkzadbHHsVj-970-80.jpg')
    ];
  },
  '*': null,
}
```

### Using Custom Validator

```dart
customValidatorHandler: () => {
  'selectYourCola': (value) {
    if (value == 0) {
      return 'Cola 0 is not allowed';
    }
  }
},
```
<img width="659" alt="image" src="https://user-images.githubusercontent.com/58694638/187993619-15adcfaf-2a0c-4ae0-ada4-4617d814f85e.png">


### TODO

- [ ] Add all examples
- [ ] OnChanged
- [ ] pub.dev

