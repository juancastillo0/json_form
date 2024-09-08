import 'dart:developer' as dev;

import 'package:flutter/material.dart';
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
    SchemaProperty schemaProperty, {
    dynamic optionalValue,
  }) async {
    try {
      // Eliminamos los nuevos inputs agregados
      await _removeCreatedItemsSafeMode(schemaProperty);
      // Obtenemos el index del actual property para añadir a abajo de él
      final indexProperty = schemaObject.properties.indexOf(schemaProperty);
      final dependents = schemaProperty.dependents!;
      if (dependents.isLeft) {
        final dependentsList = dependents.left!;
        dev.log('case 1');

        // Cuando es una Lista de String y todos ellos ahoran serán requeridos
        for (var element in schemaObject.properties) {
          if (dependentsList.contains(element.id)) {
            if (element is SchemaProperty) {
              dev.log('Este element ${element.id} es ahora $active');
              element.requiredProperty = active;
            }
          }
        }

        schemaProperty.isDependentsActive = active;
      } else if (dependents.right!.oneOf.isNotEmpty) {
        dev.log('case OneOf');

        final oneOfs = dependents.right!.oneOf;
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
              newProp.dependentsAddedBy.addAll([
                ...schemaProperty.dependentsAddedBy,
                schemaProperty.id,
              ]);
              if (newProp is SchemaProperty)
                newProp.setDependents(schemaObject);
              return newProp;
            }).toList();

            schemaObject.properties.insertAll(indexProperty + 1, newProperties);
          }
        }
      } else {
        // Cuando es un Schema simple
        dev.log('case 3');
        final _schema = dependents.right!;
        if (active) {
          schemaObject.properties.insert(indexProperty + 1, _schema);
        } else {
          schemaObject.properties
              .removeWhere((element) => element.id == _schema.idKey);
        }
        schemaProperty.isDependentsActive = active;
      }
      listen(ObjectSchemaDependencyEvent(schemaObject: schemaObject));
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
