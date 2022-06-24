import 'package:flutter/material.dart';

class JsonFormSchemaUiConfig {
  JsonFormSchemaUiConfig({
    this.fieldTitle,
    this.error,
    this.title,
    this.titleAlign,
    this.subtitle,
    this.description,
    this.label,
    this.addItemBuilder,
    this.removeItemBuilder,
    this.submitButtonBuilder,
    this.addFileButtonBuilder,
  });

  TextStyle? fieldTitle;
  TextStyle? error;
  TextStyle? title;
  TextAlign? titleAlign;
  TextStyle? subtitle;
  TextStyle? description;
  TextStyle? label;

  Widget Function(VoidCallback onPressed)? addItemBuilder;
  Widget Function(VoidCallback onPressed)? removeItemBuilder;

  /// render a custom submit button
  /// @param [VoidCallback] submit function
  Widget Function(VoidCallback onSubmit)? submitButtonBuilder;

  Widget Function(VoidCallback? onPressed)? addFileButtonBuilder;

  ///
}
