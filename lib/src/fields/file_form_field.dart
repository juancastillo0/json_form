import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:json_form/json_form.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';

class FileJFormField extends PropertyFieldWidget<Object?> {
  const FileJFormField({
    super.key,
    required super.property,
  });

  @override
  PropertyFieldState<Object?, FileJFormField> createState() =>
      _FileJFormFieldState();
}

class _FileJFormFieldState extends PropertyFieldState<Object?, FileJFormField> {
  late FormFieldState<Object?> field;
  @override
  Object? get value => field.value;
  @override
  set value(Object? newValue) {
    field.didChange(newValue);
    super.value = newValue;
  }

  JsonFormFilePickerHandler? _previousPicker;
  late FileInputHandler<Object?> _fileHandler;
  Future<List<XFile>?> Function()? _customPicker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPicker = WidgetBuilderInherited.of(context).fieldFilePicker;
    if (_previousPicker != currentPicker) {
      _customPicker = currentPicker?.call(this);
      _previousPicker = currentPicker;
    }
    if (_customPicker == null) throw Exception('no file handler found');
    _fileHandler = DefaultFileInputHandler(_customPicker!);
  }

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;

    return FormField<List<XFile>>(
      key: JsonFormKeys.inputField(idKey),
      enabled: enabled,
      validator: (value) {
        if ((value == null || value.isEmpty) && formValue.isRequiredNotNull) {
          return uiConfig.localizedTexts.required();
        }

        return customValidator(value);
      },
      onSaved: (newValue) {
        if (newValue != null) {
          final response =
              property.isMultipleFile ? newValue : (newValue.first);

          onSaved(response);
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
              if (uiConfig.labelPosition != LabelPosition.table)
                Text(uiConfig.labelText(formValue), style: uiConfig.fieldLabel),
              const SizedBox(height: 10),
              _buildButton(uiConfig, field),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: field.value?.length ?? 0,
                itemBuilder: (context, index) {
                  final file = field.value![index];

                  void onDelete() {
                    change(
                      field,
                      field.value!
                        ..removeWhere(
                          (element) => element.path == file.path,
                        ),
                    );
                  }

                  return KeyedSubtree(
                    key: JsonFormKeys.inputFieldItem(idKey, index),
                    child: _fileHandler.fileItem(
                      context,
                      this,
                      file,
                      onDelete: onDelete,
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

    final response = property.isMultipleFile
        ? values
        : (values != null && values.isNotEmpty ? values.first : null);
    onChanged(response);
  }

  VoidCallback? _onTap(FormFieldState<List<XFile>> field) {
    if (!enabled) return null;

    return () async {
      final result = await _customPicker!();

      if (result != null) {
        change(field, result);
      }
    };
  }
  // TODO: handle file drop and allow custom file handling or base64 encoding

  Widget _buildButton(
    JsonFormUiConfig uiConfig,
    FormFieldState<List<XFile>> field,
  ) {
    final onTap = _onTap(field);
    final custom = uiConfig.addFileButtonBuilder?.call(onTap, idKey);
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

abstract class FileInputHandler<T> {
  Future<List<T>?> pickFiles();

  Widget fileItem(
    BuildContext context,
    PropertyFieldState<Object?, Object?> field,
    XFile file, {
    required void Function() onDelete,
  });

  /// Map the file to the result that will be used when the form is submitted
  Object mapFileToResult(T file);
}

class DefaultFileInputHandler extends FileInputHandler<XFile> {
  final Future<List<XFile>?> Function() _pickFiles;
  final bool useDataUriResult;

  DefaultFileInputHandler(this._pickFiles, {this.useDataUriResult = false});

  @override
  Future<List<XFile>?> pickFiles() => _pickFiles();

  @override
  Widget fileItem(
    BuildContext context,
    PropertyFieldState<Object?, Object?> field,
    XFile file, {
    required void Function() onDelete,
  }) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    String pathName =
        file.path.characters.takeLastWhile((p0) => p0 != '/').string;
    if (!pathName.startsWith(file.name)) {
      pathName = file.name;
    }
    return ListTile(
      title: Tooltip(
        message: file.path,
        child: Text(
          pathName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: field.readOnly
              ? uiConfig.fieldInputReadOnly
              : uiConfig.fieldInput,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 14),
        onPressed: field.enabled ? onDelete : null,
      ),
    );
  }

  @override
  Object mapFileToResult(XFile file) => useDataUriResult ? file : file;
}
