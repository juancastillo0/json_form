import 'dart:convert';
import 'dart:developer';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:json_form/json_form.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Json Form',
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          toolbarHeight: 36,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const UnderlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.withAlpha((255 * 0.1).round()),
        ),
        colorScheme: const ColorScheme.light(
          primary: Colors.blueAccent,
        ),
      ),
      home: const MyHomePage(title: 'Json Form Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LabelPosition labelPosition = LabelPosition.table;
  Object data = {};
  bool showUISchema = false;
  bool showForm = true;
  bool customUIConfig = false;
  bool customOutsideSubmitButton = true;
  late final textController = TextEditingController(text: json);
  late final uiTextController = TextEditingController(text: uiSchema);
  String json = FormExample.allExamples.first.jsonSchema;
  String uiSchema = FormExample.allExamples.first.uiSchema;
  JsonFormController jsonFormController = JsonFormController(initialData: {});

  Future<List<XFile>?> defaultCustomFileHandler() async {
    await Future.delayed(const Duration(seconds: 3));

    final file1 = XFile(
        'https://cdn.mos.cms.futurecdn.net/LEkEkAKZQjXZkzadbHHsVj-970-80.jpg');
    final file2 = XFile(
        'https://cdn.mos.cms.futurecdn.net/LEkEkAKZQjXZkzadbHHsVj-970-80.jpg');
    final file3 = XFile(
        'https://cdn.mos.cms.futurecdn.net/LEkEkAKZQjXZkzadbHHsVj-970-80.jpg');

    return [file1, file2, file3];
  }

  Widget submitButtonBuilder(void Function() onSubmit) =>
      customOutsideSubmitButton
          ? const SizedBox()
          : TextButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.heart_broken),
              label: const Text('Custom Submit'),
            );

  JsonFormUiConfig customUiConfig() {
    return JsonFormUiConfig(
      labelPosition: labelPosition,
      inputWrapperBuilder: (property, input) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: input,
      ),
      title: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      submitButtonBuilder: submitButtonBuilder,
      addItemBuilder: (onPressed, key) => TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.plus_one),
        label: const Text('Add Item'),
      ),
      addFileButtonBuilder: (onPressed, key) {
        if (['file', 'file3'].contains(key)) {
          return OutlinedButton(
            onPressed: onPressed,
            style: ButtonStyle(
              minimumSize:
                  WidgetStateProperty.all(const Size(double.infinity, 40)),
              backgroundColor: WidgetStateProperty.all(
                const Color(0xffcee5ff),
              ),
              side: WidgetStateProperty.all(
                  const BorderSide(color: Color(0xffafd5ff))),
              textStyle: WidgetStateProperty.all(
                  const TextStyle(color: Color(0xff057afb))),
            ),
            child: Text('+ Agregar archivo $key'),
          );
        }

        return null;
      },
    );
  }

  void onFormDataSaved(Object data) {
    inspect(data);
    setState(() {
      this.data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isSmall = screen.width < 700;

    final formWidget = Column(
      children: <Widget>[
        Expanded(
          child: JsonForm(
            jsonSchema: json,
            uiSchema: uiSchema,
            controller: jsonFormController,
            onFormDataSaved: onFormDataSaved,
            fieldFilePicker: (field) =>
                {
                  'files': defaultCustomFileHandler,
                  'file': () async {
                    return [
                      XFile(
                        'https://cdn.mos.cms.futurecdn.net/LEkEkAKZQjXZkzadbHHsVj-970-80.jpg',
                      )
                    ];
                  },
                }[field.idKey] ??
                defaultCustomFileHandler,
            // customPickerHandler: () => {
            //   '*': (data) async {
            //     return showDialog(
            //       context: context,
            //       builder: (context) {
            //         return Scaffold(
            //           body: Container(
            //             margin: const EdgeInsets.all(20),
            //             child: Column(
            //               children: [
            //                 const Text('My Custom Picker'),
            //                 ListView.builder(
            //                   shrinkWrap: true,
            //                   itemCount: data.keys.length,
            //                   itemBuilder: (context, index) {
            //                     return ListTile(
            //                       title: Text(
            //                           data.values.toList()[index].toString()),
            //                       onTap: () => Navigator.pop(
            //                           context, data.keys.toList()[index]),
            //                     );
            //                   },
            //                 ),
            //               ],
            //             ),
            //           ),
            //         );
            //       },
            //     );
            //   }
            // },
            uiConfig: customUIConfig
                ? customUiConfig()
                : JsonFormUiConfig(
                    labelPosition: labelPosition,
                    submitButtonBuilder:
                        customOutsideSubmitButton ? submitButtonBuilder : null,
                  ),
            fieldValidator: (field) => {
              'files': (value) {
                return null;
              },
              'uri': (uri) =>
                  (uri as String).isEmpty || Uri.parse(uri).isAbsolute
                      ? null
                      : 'Should be absolute URI',
              'numberExclusive': (n) => (n as String).isEmpty || n != '6'
                  ? null
                  : 'Should be different than 6',
              'arrayCheckbox': (a) => (a as List).contains(3) && a.contains(5)
                  ? "Can't have 3 and 5 at the same time"
                  : null,
            }[field.idKey],
          ),
        ),
        if (customOutsideSubmitButton)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: ElevatedButton(
              onPressed: () {
                final data = jsonFormController.submit();
                if (data != null) onFormDataSaved(data);
              },
              child: const Text('Outside Submit'),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );

    final formColumnWidget = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 130,
              child: CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                value: customOutsideSubmitButton,
                onChanged: (value) => setState(() {
                  customOutsideSubmitButton = value == true;
                }),
                title: const Text('Outside Submit'),
              ),
            ),
            SizedBox(
              width: 130,
              child: CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                value: customUIConfig,
                onChanged: (value) => setState(() {
                  customUIConfig = value == true;
                }),
                title: const Text('Custom UI Config'),
              ),
            ),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<LabelPosition>(
                value: labelPosition,
                decoration: const InputDecoration(
                  labelText: 'Label Position',
                ),
                items: LabelPosition.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    labelPosition = v!;
                  });
                },
              ),
            ),
          ],
        ),
        Expanded(child: formWidget),
      ],
    );

    final schemaInputWidget = LayoutBuilder(
      builder: (context, box) {
        final isLarge = box.maxWidth > 500;
        return Column(
          children: [
            Row(
              children: [
                if (!isLarge && (!isSmall || !showForm))
                  ToggleButtons(
                    constraints: const BoxConstraints.tightForFinite(
                      height: 30,
                      width: 100,
                    ),
                    onPressed: (index) => setState(() {
                      showUISchema = !showUISchema;
                    }),
                    isSelected: [!showUISchema, showUISchema],
                    children: const [
                      Text('Json Schema'),
                      Text('UI Schema'),
                    ],
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Text(
                          'Examples: ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ...FormExample.allExamples.map(
                          (e) => TextButton(
                            onPressed: () {
                              setState(() {
                                json = e.jsonSchema;
                                uiSchema = e.uiSchema;
                                textController.text = json;
                                uiTextController.text = uiSchema;
                              });
                            },
                            child: Text(e.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6.0, top: 6.0, right: 6.0),
                child: Row(
                  children: [
                    if (!showUISchema || isLarge)
                      Expanded(
                        child: TextFormField(
                          maxLines: 1000,
                          controller: textController,
                          decoration: const InputDecoration(
                            label: Text('Json Schema'),
                          ),
                          onChanged: (value) {
                            try {
                              jsonDecode(value);
                              setState(() {
                                json = value;
                              });
                            } catch (_) {}
                          },
                        ),
                      ),
                    if (showUISchema || isLarge)
                      Expanded(
                        child: TextFormField(
                          maxLines: 1000,
                          controller: uiTextController,
                          decoration: const InputDecoration(
                            label: Text('UI Schema'),
                          ),
                          onChanged: (value) {
                            try {
                              jsonDecode(value);
                              setState(() {
                                uiSchema = value;
                              });
                            } catch (_) {}
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Form Submit Output',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Container(
              height: 100,
              padding: const EdgeInsets.all(6),
              child: SingleChildScrollView(
                child: SelectableText(data.toString()),
              ),
            )
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isSmall)
            ToggleButtons(
              constraints: const BoxConstraints.tightForFinite(
                height: 30,
                width: 75,
              ),
              onPressed: (index) => setState(() {
                showForm = !showForm;
              }),
              isSelected: [!showForm, showForm],
              children: const [
                Text('Schema'),
                Text('Form'),
              ],
            ),
          TextButton(
            onPressed: () {
              launchUrl(
                Uri.parse('https://github.com/juancastillo0/json_form'),
              );
            },
            child: const Text('Code Repo'),
          ),
        ],
      ),
      body: ResizableContainer(
        direction: Axis.horizontal,
        children: [
          if (!showForm || !isSmall) ResizableChild(child: schemaInputWidget),
          if (showForm || !isSmall) ResizableChild(child: formColumnWidget),
        ],
      ),
    );
  }
}

class FormExample {
  const FormExample(this.name, this.jsonSchema, this.uiSchema);

  final String name;
  final String jsonSchema;
  final String uiSchema;

  static const primitivesExample =
      FormExample('primitives', primitivesJsonSchema, primitivesUiSchema);
  static const arrayExample = FormExample('array', arrayJsonSchema, '{}');
  static const arrayItemsExample =
      FormExample('arrayItems', arrayItemsJsonSchema, arrayItemsUISchema);
  static const nestedObjectExample =
      FormExample('nestedObject', nestedObjectJsonSchema, '{}');
  static const uiSchemaExample =
      FormExample('uiSchema', uiSchemaJsonSchema, uiSchemaUiSchema);
  static const oneOfExample = FormExample('oneOf', oneOfJsonSchema, '{}');
  static const defsExample = FormExample('defs', defsJsonSchema, '{}');
  static const dependenciesExample =
      FormExample('dependencies', dependenciesJsonSchema, '{}');
  static const oneOfDependenciesExample =
      FormExample('oneOfDependencies', oneOfDependenciesJsonSchema, '{}');
  static const oneOfConstExample =
      FormExample('oneOfConst', oneOfConstJsonSchema, '{}');
  static const formatsExample =
      FormExample('formats', formatsJsonSchema, formatsUiSchema);
  static const filesExample = FormExample('files', filesJsonSchema, '{}');

  static const allExamples = [
    primitivesExample,
    arrayExample,
    arrayItemsExample,
    nestedObjectExample,
    uiSchemaExample,
    oneOfExample,
    defsExample,
    dependenciesExample,
    oneOfDependenciesExample,
    oneOfConstExample,
    formatsExample,
    filesExample,
  ];
}

const oneOfJsonSchema = '''
 {
  "title": "Form Title",
  "type": "object",
  "required": ["select"],
  "properties": {
    "files": {
      "title": "Multiple files",
      "type": "array",
      "items": {
        "type": "string",
        "format": "data-url"
      }
    },
    "select": {
      "title" : "Select your Cola",
      "type": "string",
      "description": "This is the select-description",
      "enum": [0,1,2,3,4],
      "enumNames": ["Vale 0","Vale 1","Vale 2","Vale 3","Vale 4"],
      "default": 3
    },
    "num": {
      "title": "Number Title",
      "type": "number",
      "default": 1
    },
    "bool": {
      "type": "boolean",
      "description": "This is a description for the boolean",
      "default": true
    },
    "nestedObjects": {
      "type": "array",
      "items": {
        "title" : "NestedObject",
        "type": "object",
        "required": ["arrayOfString"],
        "properties": {
          "arrayOfString": {
            "title" : "ArrayOfString",
            "type": "array",
            "items": { "type": "string" }
          },
          "nullableInteger": {
            "type": ["integer", "null"]
          }
        }
      }
    },
    "profession" :  {
      "title": "Ocupación o profesión",
      "type": "string",
      "default": "investor",
      "oneOf": [
        {
          "enum": ["trader"],
          "type": "string",
          "title": "Trader"
        },
        {
          "enum": ["investor"],
          "title": "Inversionista"
        },      
        {
          "const": "manager_officier",
          "type": "string",
          "title": "Gerente / Director(a)"
        }
      ]
    }
  }
}
''';

const uiSchemaJsonSchema = '''{
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

const uiSchemaUiSchema = '''{
  "ui:order": [
    "integerRadio",
    "stringTop",
    "integerRange",
    "arrayString",
    "enumValues",
    "arrayCheckbox",
    "object"
  ],
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
    "ui:orderable": true,
    "ui:copyable": true
  },
  "enumValues": {
    "ui:options": {
      "enumNames": ["n1", "n2", "n3"],
      "enumDisabled": ["n2"]
    }
  }
}''';

const arrayItemsJsonSchema = '''{
  "type": "object",
  "properties": {
    "arrayString": {
      "type": "array",
      "items": {
        "type": "string",
        "ui:options": {
          "help": "helper text"
        }
      }
    },
    "arrayNumber": {
      "type": "array",
      "items": {
        "type": "number"
      }
    },
    "arrayInteger": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "arrayBoolean": {
      "type": "array",
      "items": {
        "type": "boolean"
      }
    },
    "arrayEnum": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["a", "b", "c", "d"]
      }
    },
    "arrayEnumRadio": {
      "type": "array",
      "items": {
        "type": "integer",
        "enum": [2, 4, 6]
      }
    },
    "arrayDate": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "date"
      }
    },
    "arrayDateTime": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "date-time"
      }
    }
  }
}''';

const arrayItemsUISchema = '''{
  "arrayEnumRadio": {
    "items": {
      "ui:widget": "radio"
    }
  }
}''';

const nestedObjectJsonSchema = '''{
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
}''';

const arrayJsonSchema = '''{
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
}''';

const primitivesJsonSchema = '''{
  "type": "object",
  "title": "My Form",
  "description": "Form description",
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
}''';

const primitivesUiSchema = '''{
  "enumRadio": {
    "ui:widget": "radio"
  },
  "arrayCheckbox": {
    "ui:widget": "checkboxes"
  }
}''';

const defsJsonSchema = '''{
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
}''';

const dependenciesJsonSchema = '''{
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
}''';

const oneOfDependenciesJsonSchema = '''{
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
}''';

const oneOfConstJsonSchema = '''{
  "title": "One Of Const",
  "description": "Variants configured within oneOfs using const.",
  "type": "object",
  "properties": {
    "Other Property": {
      "type": ["string", null]
    },
    "example": {
      "\$ref": "#/\$defs/oneOfExample"
    }
  },
  "\$defs": {
    "oneOfExample": {
      "type": "object",
      "ui:options": {
        "title": "Pets oneOf example"
      },
      "required": ["Do you have any pets?"],
      "oneOf": [
        {
          "properties": {
            "Do you have any pets?": {
              "const": "No"
            }
          }
        },
        {
          "properties": {
            "Do you have any pets?": {
              "const": "Yes: One"
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
}''';

const formatsJsonSchema = '''{
  "type": "object",
  "required": ["number", "email", "uuid", "dateTime"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "ui:options": {
        "autofocus": true
      }
    },
    "uri": {
      "type": "string",
      "format": "uri"
    },
    "hostname": {
      "type": "string",
      "format": "hostname"
    },
    "uuid": {
      "type": ["string", "null"],
      "format": "uuid"
    },
    "regex": {
      "type": ["string", "null"],
      "format": "regex"
    },
    "ipv4": {
      "type": "string",
      "format": "ipv4"
    },
    "ipv6": {
      "type": "string",
      "format": "ipv6"
    },
    "time": {
      "type": "string",
      "format": "time"
    },
    
    "number": {
      "type": "number",
      "minimum": 2,
      "maximum": 12,
      "multipleOf": 2
    },
    "numberExclusive": {
      "type": ["integer", null],
      "exclusiveMinimum": 2,
      "exclusiveMaximum": 12
    },
    "arrayRoot": {
      "type": "array",
      "items": {
        "\$ref": "#"
      }
    },
    "dateTime": {
      "type": "string",
      "format": "date-time"
    },
    "arrayInts": {
      "ui:options": {
        "removable": true,
        "items": {
          "ui:autofocus": true
        }
      },
      "type": "array",
      "items": {
        "type": "integer",
        "exclusiveMinimum": 2,
        "exclusiveMaximum": 6
      }
    }
  }
}''';

const formatsUiSchema = '''{
  "ui:globalOptions": {
    "copyable": true,
    "removable": false,
    "autofocus": false
  }
}''';

const filesJsonSchema = '''{
  "type": "object",
  "properties": {
    "file": {
      "type": "string",
      "format": "data-url"
    },
    "file2": {
      "type": "string",
      "format": "data-url"
    },
    "file3": {
      "type": "string",
      "format": "data-url"
    },
    "file4": {
      "type": "string",
      "format": "data-url"
    },
    "arrayFile": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "data-url"
      }
    }
  }
}''';
