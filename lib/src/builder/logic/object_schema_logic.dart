import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_jsonschema_builder/src/models/models.dart';

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
    SchemaProperty schemaProperty, {
    dynamic optionalValue,
    Schema? mainSchema,
    String? idOptional,
  }) async {
    try {
      // Eliminamos los nuevos inputs agregados
      await _removeCreatedItemsSafeMode(schemaProperty);
      // Obtenemos el index del actual property para añadir a abajo de él
      final indexProperty = schemaObject.properties.indexOf(schemaProperty);
      final dependents = schemaProperty.dependents;
      if (dependents is List) {
        dev.log('case 1');

        // Cuando es una Lista de String y todos ellos ahoran serán requeridos
        for (var element in schemaObject.properties) {
          if (dependents.contains(element.id)) {
            if (element is SchemaProperty) {
              dev.log('Este element ${element.id} es ahora $active');
              element.requiredProperty = active;
            }
          }
        }

        schemaProperty.isDependentsActive = active;
        listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
      } else if (dependents is Map && dependents.containsKey("oneOf")) {
        dev.log('case OneOf');

        final oneOfs = dependents['oneOf'];

        if (oneOfs is List) {
          for (Map<String, dynamic> oneOf in oneOfs.cast()) {
            final properties = oneOf['properties'] as Map?;
            // Verificamos si es el que requerimos
            if (properties == null ||
                !properties.containsKey(schemaProperty.id)) continue;

            final prop = properties[schemaProperty.id];
            // Verificamos que tenga la estructura enum correcta
            if (prop is! Map || !prop.containsKey('enum')) continue;

            // Guardamos los valores que se van a condicionar para que salgan los nuevos inputs
            final valuesForCondition = prop['enum'] as List;

            // si tiene uno del valor seleccionado en el select, mostramos
            if (valuesForCondition.contains(optionalValue)) {
              schemaProperty.isDependentsActive = true;

              // Add new properties
              final tempSchema = SchemaObject.fromJson(
                kNoIdKey,
                oneOf,
                parent: schemaObject,
              );

              final newProperties = tempSchema.properties
                  // Quitamos el key del mismo para que no se agregue al arbol de widgets
                  .where((e) => e.id != schemaProperty.id)
                  // Agregamos que fue dependiente de este, para que luego pueda ser eliminado.
                  .map((e) {
                e.dependentsAddedBy.addAll([
                  ...schemaProperty.dependentsAddedBy,
                  schemaProperty.id,
                ]);
                if (e is SchemaProperty) e.setDependents(schemaObject);

                return e;
              }).toList();

              schemaObject.properties
                  .insertAll(indexProperty + 1, newProperties);
            }
          }
        }

        // dispatch Event
        listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
      } else if (dependents is Schema) {
        // Cuando es un Schema simple
        dev.log('case 3');
        final _schema = dependents;

        if (active) {
          schemaObject.properties.add(_schema);
        } else {
          schemaObject.properties
              .removeWhere((element) => element.id == _schema.idKey);
        }

        schemaProperty.isDependentsActive = active;

        listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
      }
    } catch (e) {
      dev.log(e.toString());
    }
  }

  Future<void> _removeCreatedItemsSafeMode(
    SchemaProperty schemaProperty,
  ) async {
    bool filter(Schema element) =>
        element.dependentsAddedBy.contains(schemaProperty.id);

    if (schemaObject.properties.any(filter)) {
      schemaObject.properties.removeWhere(filter);

      listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
      await Future<void>.delayed(Duration.zero);
    }
  }
}
