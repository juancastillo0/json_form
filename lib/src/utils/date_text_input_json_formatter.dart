import 'dart:developer';

import 'package:flutter/services.dart';

const String dateFormatString = 'yyyy-MM-dd';
const String dateTimeFormatString = 'yyyy-MM-dd HH:mm:ss';

String formatDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime dateTime) {
  return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}

class DateTextInputJsonFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.length >= newValue.text.length) {
      return newValue;
    }

    if (newValue.text.length > 10) {
      return oldValue;
    }

    final dateText = _addSeparators(newValue.text, '-');

    if (dateText.length == 1) {
      if (!RegExp(r'([0-3])$').hasMatch(dateText)) {
        return oldValue;
      }
    }
    if (dateText.length == 2) {
      log(dateText[1]);
      if (!RegExp(r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])$').hasMatch(dateText)) {
        return oldValue;
      }
    }

    if (dateText.length == 4) {
      if (!RegExp(r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-([0-1])$')
          .hasMatch(dateText)) {
        return oldValue;
      }
    }

    if (dateText.length == 5) {
      if (!RegExp(r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-(0[1-9]|1[0-2])$')
          .hasMatch(dateText)) {
        return oldValue;
      }
    }
    if (dateText.length == 7) {
      if (!RegExp(r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-(0[1-9]|1[0-2])-([1-2])$')
          .hasMatch(dateText)) {
        return oldValue;
      }
    }

    if (dateText.length == 8) {
      if (!RegExp(
        r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-(0[1-9]|1[0-2])-(1[9]|2[0|9])$',
      ).hasMatch(dateText)) {
        return oldValue;
      }
    }

    if (dateText.length == 9) {
      if (!RegExp(
        r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-(0[1-9]|1[0-2])-(19[89]|20[0-3])$',
      ).hasMatch(dateText)) {
        return oldValue;
      }
    }

    if (dateText.length == 10) {
      if (!RegExp(
        r'(0[1-9]|1[0-9]|2[0-9]|3[0-1])-(0[1-9]|1[0-2])-(19[89][0-9]|20[0-3][0-9])$',
      ).hasMatch(dateText)) {
        return oldValue;
      }
    }

    return newValue.copyWith(
      text: dateText,
      selection: updateCursorPosition(dateText),
    );
  }

  String _addSeparators(String value, String separator) {
    final v = value.replaceAll('-', '');
    final newString = StringBuffer();
    for (int i = 0; i < v.length; i++) {
      newString.write(v[i]);
      if (i == 1) {
        newString.write(separator);
      }
      if (i == 3) {
        newString.write(separator);
      }
    }
    return newString.toString();
  }

  TextSelection updateCursorPosition(String text) {
    return TextSelection.fromPosition(TextPosition(offset: text.length));
  }
}
