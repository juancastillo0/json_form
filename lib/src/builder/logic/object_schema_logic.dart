import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:json_form/src/builder/logic/widget_builder_logic.dart';
import 'package:json_form/src/models/models.dart';

class ObjectSchemaEvent {
  const ObjectSchemaEvent({required this.schemaObject});
  final SchemaObject schemaObject;
}

class ObjectSchemaDependencyEvent extends ObjectSchemaEvent {
  const ObjectSchemaDependencyEvent({required super.schemaObject});
}

class ObjectSchemaInherited extends InheritedWidget {
  const ObjectSchemaInherited({
    super.key,
    required this.schemaObject,
    required super.child,
    required this.listen,
  });

  final SchemaObject schemaObject;
  final ValueSetter<ObjectSchemaEvent?> listen;

  static ObjectSchemaInherited of(BuildContext context) {
    final ObjectSchemaInherited? result =
        context.dependOnInheritedWidgetOfExactType<ObjectSchemaInherited>();
    assert(result != null, 'No WidgetBuilderInherited found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ObjectSchemaInherited oldWidget) {
    final needsRepaint = schemaObject != oldWidget.schemaObject;
    return needsRepaint;
  }

  void listenChangeProperty(
    bool active,
    JsonFormValue schemaProperty, {
    Object? optionalValue,
  }) {
    try {
      // Eliminamos los nuevos inputs agregados
      _removeCreatedItemsSafeMode(schemaProperty);
      final objProps = schemaProperty.parent!.children;
      // Obtenemos el index del actual property para añadir a abajo de él
      final indexProperty = objProps.indexOf(schemaProperty);
      final dependents = (schemaProperty.schema as SchemaProperty).dependents!;
      if (dependents.requiredProps != null) {
        final dependentsList = dependents.requiredProps!;
        dev.log('case 1');

        // Cuando es una Lista de String y todos ellos ahoran serán requeridos
        for (final element in objProps) {
          if (dependentsList.contains(element.id)) {
            if (element.schema is SchemaProperty) {
              dev.log('Este element ${element.id} es ahora $active');
              element.requiredFromDependent = active;
            }
          }
        }

        schemaProperty.isDependentsActive = active;
      }

      if (dependents.schema?.oneOf.isNotEmpty ?? false) {
        dev.log('case OneOf');

        final oneOfs = dependents.schema!.oneOf;
        for (final oneOf in oneOfs) {
          final properties =
              oneOf is SchemaObject ? oneOf.properties : <Schema>[];
          final propIndex =
              properties.indexWhere((p) => p.id == schemaProperty.id);
          if (propIndex == -1) continue;
          final prop = properties[propIndex];
          // Verificamos que tenga la estructura enum correcta
          if (prop is! SchemaProperty || prop.enumm == null) continue;

          // Guardamos los valores que se van a condicionar para que salgan los nuevos inputs
          final valuesForCondition = prop.enumm!;

          // si tiene uno del valor seleccionado en el select, mostramos
          if (valuesForCondition.contains(optionalValue)) {
            schemaProperty.isDependentsActive = true;

            // Add new properties
            // TODO: final tempSchema = oneOf.copyWith(id: oneOf.id);

            final newProperties = properties
                // Quitamos el key del mismo para que no se agregue al arbol de widgets
                .where((e) => e.id != schemaProperty.id)
                // Agregamos que fue dependiente de este, para que luego pueda ser eliminado.
                .map((e) {
              final newProp = e.copyWith(id: e.id, parent: schemaObject);
              if (newProp is SchemaProperty)
                // TODO: validate
                newProp.setDependents(schemaObject);
              final v = JsonFormValue(
                id: e.id,
                parent: schemaProperty.parent,
                schema: newProp,
              );
              v.dependentsAddedBy.addAll([
                ...schemaProperty.dependentsAddedBy,
                schemaProperty.id,
              ]);
              return v;
            }).toList();

            objProps.insertAll(indexProperty + 1, newProperties);
          }
        }
      } else if (dependents.schema != null) {
        // Cuando es un Schema simple
        dev.log('case 3');
        final _schema = dependents.schema!;
        if (active) {
          objProps.insert(
            indexProperty + 1,
            JsonFormValue(
              id: _schema.id,
              parent: schemaProperty.parent,
              schema: _schema,
            ),
          );
        } else {
          objProps.removeWhere((element) => element.id == _schema.id);
        }
        schemaProperty.isDependentsActive = active;
      }
      listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
    } catch (e) {
      dev.log(e.toString());
    }
  }

  void _removeCreatedItemsSafeMode(JsonFormValue schemaProperty) {
    final initialLength = schemaProperty.parent!.children.length;
    bool filter(JsonFormValue element) =>
        element.dependentsAddedBy.contains(schemaProperty.id);

    schemaProperty.parent!.children.removeWhere(filter);
    if (initialLength != schemaProperty.parent!.children.length) {
      listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
    }
  }
}
