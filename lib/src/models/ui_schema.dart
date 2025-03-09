class UiSchemaData {
  final Map<String, Object?> _asJson = {};
  String? title;
  String? description;
  UiSchemaData? globalOptions;
  UiSchemaData? parent;
  final Map<String, UiSchemaData> children = {};

  ///
  /// General Options
  ///
  String? help;
  bool readOnly = false;
  bool disabled = false;
  bool hidden = false;
  bool hideError = false;
  double? width;

  ///
  /// String Options
  ///
  String? placeholder;
  String? emptyValue;
  bool autofocus = false;
  bool autocomplete = false;

  ///
  /// Date Options
  ///
  List<int>? yearsRange; // TODO: negative values

  /// Date format MDY, DMY and YMD (default)
  String format = 'YMD';
  bool hideNowButton = false;
  bool hideClearButton = false;

  /// boolean: radio, select, checkbox (default)
  /// string: textarea, password, color, file
  /// number: updown, range, radio
  /// array: checkboxes
  String? widget;

  /// With "widget=file" or "format=data-url": accept='.pdf'
  String? accept;

  /// Displayed as text if is not empty
  List<String>? enumNames;
  List<String>? enumDisabled;
  List<String>? order;

  ///
  /// Array Options
  ///
  bool inline = false;
  bool addable = true;
  bool removable = true;
  bool orderable = true;
  bool copyable = true;

  Map<String, Object?> toJson() => {
        'ui:options': _asJson,
        for (final e in children.entries) e.key: e.value.toJson(),
      };

  void setGlobalOptions(
    Map<String, Object?> data, {
    required bool fromOptions,
  }) {
    globalOptions ??= UiSchemaData();
    globalOptions!.setUi(data, parent: this, fromOptions: fromOptions);
    setUi(data, parent: null, fromOptions: fromOptions, fromGlobal: true);
  }

  void setUi(
    Map<String, dynamic> uiSchema, {
    required UiSchemaData? parent,
    bool fromOptions = false,
    bool fromGlobal = false,
  }) {
    this.parent = parent ?? this.parent;
    if (parent != null &&
        parent.globalOptions != null &&
        this != parent.globalOptions) {
      setGlobalOptions(parent.globalOptions!.toJson(), fromOptions: false);
    }
    // if (fromOptions) {
    //   final options = asJson['ui:options'] as Map<String, Object?>? ?? {};
    //   asJson['ui:options'] = options;
    //   options.addAll(uiSchema);
    // } else {
    //   asJson.addAll(uiSchema);
    // }
    uiSchema.forEach((key, data) {
      final split = key.split(':');
      final String k;
      if (fromOptions) {
        k = key;
      } else if (split.length == 2 && split.first == 'ui') {
        k = split.last;
        // } else if (data is Map<String, dynamic>) {
        //   final nested = nestedProperties[key] ?? UiSchemaData();
        //   nestedProperties[key] = nested;
        //   nested.setUi(data, fromOptions: false, parent: this);
        //   return;
      } else {
        return;
      }
      if (fromGlobal && _asJson.containsKey(k)) return;
      bool saveInJson = !fromGlobal;
      switch (k) {
        case 'disabled':
          disabled = data as bool;
          break;
        // TODO: filePreview, label=false, type:password
        // rows/width
        case 'autofocus':
          autofocus = data as bool;
          break;
        case 'autocomplete':
          autocomplete = data as bool;
          break;
        case 'hideError':
          hideError = data as bool;
          break;
        case 'width':
          width = (data as num).toDouble();
          break;
        case 'enumDisabled':
          enumDisabled = (data as List).cast();
          break;
        case 'enumNames':
          enumNames = (data as List).cast();
          break;
        case 'emptyValue':
          emptyValue = data as String;
          break;
        case 'title':
          title = data as String;
          break;
        case 'description':
          description = data as String;
          break;
        case 'help':
          help = data as String;
          break;
        case 'placeholder':
          placeholder = data as String;
          break;
        case 'readonly':
          readOnly = data as bool;
          break;
        case 'hidden':
          hidden = data as bool;
          break;
        case 'widget':
          // TODO: password, textarea, inputType:tel,email?
          widget = data as String;
          break;
        case 'yearsRange':
          yearsRange = data as List<int>;
          break;
        case 'format':
          format = data as String;
          break;
        case 'hideNowButton':
          hideNowButton = data as bool;
          break;
        case 'hideClearButton':
          hideClearButton = data as bool;
          break;
        case 'order':
          order = (data as List).cast();
          break;

        ///
        /// Array Properties
        ///
        case 'addable':
          addable = data as bool;
          break;
        case 'removable':
          removable = data as bool;
          break;
        case 'orderable':
          orderable = data as bool;
          break;
        case 'copyable':
          copyable = data as bool;
          break;
        case 'options':
          setUi(
            data as Map<String, Object?>,
            fromOptions: true,
            parent: null,
            fromGlobal: fromGlobal,
          );
          saveInJson = false;
          break;
        case 'globalOptions':
          setGlobalOptions(data as Map<String, Object?>, fromOptions: true);
          break;
        default:
          saveInJson = false;
      }
      if (saveInJson) {
        _asJson[k] = data;
      }
    });
  }
}
