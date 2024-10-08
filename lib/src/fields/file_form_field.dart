import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/fields.dart';
import 'package:json_form/src/models/json_form_schema_style.dart';

import './shared.dart';

class FileJFormField extends PropertyFieldWidget<dynamic> {
  const FileJFormField({
    super.key,
    required super.property,
    required super.onSaved,
    super.onChanged,
    required this.fileHandler,
    super.customValidator,
  });

  final Future<List<XFile>?> Function() fileHandler;

  @override
  _FileJFormFieldState createState() => _FileJFormFieldState();
}

class _FileJFormFieldState extends PropertyFieldState<dynamic, FileJFormField> {
  late FormFieldState<Object?> field;
  @override
  Object? get value => field.value;
  @override
  set value(Object? newValue) {
    field.didChange(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;

    return FormField<List<XFile>>(
      key: Key(property.idKey),
      enabled: enabled,
      validator: (value) {
        if ((value == null || value.isEmpty) && property.requiredNotNull) {
          return uiConfig.localizedTexts.required();
        }

        if (widget.customValidator != null)
          return widget.customValidator!(value);
        return null;
      },
      onSaved: (newValue) {
        if (newValue != null) {
          final response =
              property.isMultipleFile ? newValue : (newValue.first);

          widget.onSaved(response);
        }
      },
      builder: (field) {
        this.field = field;
        return Focus(
          focusNode: focusNode,
          autofocus: property.uiSchema.autofocus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(uiConfig.labelText(property), style: uiConfig.subtitle),
              const SizedBox(height: 10),
              _buildButton(uiConfig, field),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: field.value?.length ?? 0,
                itemBuilder: (context, index) {
                  final file = field.value![index];

                  return ListTile(
                    key: Key('${property.idKey}_$index'),
                    title: Text(
                      file.path.characters
                          .takeLastWhile((p0) => p0 != '/')
                          .string,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: readOnly
                          ? uiConfig.fieldInputReadOnly
                          : uiConfig.fieldInput,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: enabled
                          ? () {
                              change(
                                field,
                                field.value!
                                  ..removeWhere(
                                    (element) => element.path == file.path,
                                  ),
                              );
                            }
                          : null,
                    ),
                  );
                },
              ),
              if (field.hasError) CustomErrorText(text: field.errorText!),
            ],
          ),
        );
      },
    );
  }

  void change(FormFieldState<List<XFile>> field, List<XFile>? values) {
    field.didChange(values);

    if (widget.onChanged != null) {
      final response = property.isMultipleFile
          ? values
          : (values != null && values.isNotEmpty ? values.first : null);
      widget.onChanged!(response);
    }
  }

  VoidCallback? _onTap(FormFieldState<List<XFile>> field) {
    if (!enabled) return null;

    return () async {
      final result = await widget.fileHandler();

      if (result != null) {
        change(field, result);
      }
    };
  }

  Widget _buildButton(
    JsonFormSchemaUiConfig uiConfig,
    FormFieldState<List<XFile>> field,
  ) {
    final onTap = _onTap(field);
    final custom = uiConfig.addFileButtonBuilder?.call(onTap, property.idKey);
    if (custom != null) return custom;

    return ElevatedButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 40)),
      ),
      child: Text(uiConfig.localizedTexts.addFile()),
    );
  }
}
