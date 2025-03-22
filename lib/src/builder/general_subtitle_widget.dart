import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/fields/shared.dart';
import 'package:json_form/src/models/models.dart';

class GeneralSubtitle extends StatelessWidget {
  const GeneralSubtitle({
    super.key,
    required this.field,
    this.mainSchema,
    this.trailing,
  });

  final Schema field;
  final Schema? mainSchema;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final uiConfig = WidgetBuilderInherited.of(context).uiConfig;
    final custom = uiConfig.titleAndDescriptionBuilder?.call(field);
    if (custom != null) return custom;

    final f = field;
    String? description = field.description != null &&
            field.description != mainSchema?.description
        ? field.description
        : null;

    /// Show the description of array items beside the array's description
    if (f is SchemaArray && f.itemsBaseSchema.description != null) {
      description = description == null
          ? f.itemsBaseSchema.description
          : '\n${f.itemsBaseSchema.description}';
    } else if (f is SchemaObject && f.parent is SchemaArray) {
      description = null;
    }

    final titleOrId = uiConfig.schemaTitleOrId(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        if (mainSchema == null ||
            uiConfig.schemaTitleOrId(mainSchema!) != titleOrId &&
                titleOrId.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleOrId,
                style: uiConfig.subtitle,
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(),
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
