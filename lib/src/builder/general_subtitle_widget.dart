import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/builder/logic/widget_builder_logic.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

class GeneralSubtitle extends StatelessWidget {
  const GeneralSubtitle({
    super.key,
    required this.field,
    this.mainSchema,
    this.omitDivider = false,
    this.trailing,
  });

  final Schema field;
  final Schema? mainSchema;
  final bool omitDivider;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final f = field;
    String? description = field.description != null &&
            field.description != mainSchema?.description
        ? field.description
        : null;
    if (f is SchemaArray && f.itemsBaseSchema.description != null) {
      description = description == null
          ? f.itemsBaseSchema.description
          : '\n${f.itemsBaseSchema.description}';
    } else if (f is SchemaObject && f.parent is SchemaArray) {
      description = null;
    }

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
              if (trailing != null) trailing!,
            ],
          ),
          if (!omitDivider) const Divider(),
        ],
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              description,
              style: uiConfig.description,
            ),
          ),
      ],
    );
  }
}
