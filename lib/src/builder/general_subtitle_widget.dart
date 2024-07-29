import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

class GeneralSubtitle extends StatelessWidget {
  const GeneralSubtitle({
    super.key,
    required this.field,
    this.mainSchema,
    this.omitDivider = false,
  });

  final Schema field;
  final Schema? mainSchema;
  final bool omitDivider;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final removeItem = uiConfig.removeItemWidget(context, field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        if (mainSchema?.titleOrId != field.titleOrId &&
            // TODO:
            field.titleOrId != kNoTitle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                field.titleOrId,
                style: uiConfig.subtitle,
              ),
              if (removeItem != null) removeItem,
            ],
          ),
          if (!omitDivider) const Divider(),
        ],
        if (field.description != null &&
            field.description != mainSchema?.description)
          Text(
            field.description!,
            style: uiConfig.description,
          ),
      ],
    );
  }
}
