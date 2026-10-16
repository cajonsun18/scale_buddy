import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';

void main() {
  group('WorkspaceState helpers', () {
    test(
      'addOrUpdateEntity and updateEntity manage entity state changes properly',
      () {
        const state = WorkspaceState();

        const newEntity = DrawingEntity.line(
          id: '1',
          p1: Offset(0, 0),
          p2: Offset(1, 1),
          color: Colors.red,
        );

        // 1. Add new entity
        final stateWithEntity = state.addOrUpdateEntity(newEntity);
        expect(stateWithEntity.entities.length, 1);
        expect(stateWithEntity.entities.first, newEntity);

        // 2. Update existing entity with same ID
        final updatedEntity = (newEntity as LineEntity).copyWith(
          color: Colors.blue,
        );
        final stateWithUpdated = stateWithEntity.addOrUpdateEntity(
          updatedEntity,
        );
        expect(stateWithUpdated.entities.length, 1);
        expect(
          (stateWithUpdated.entities.first as LineEntity).color,
          Colors.blue,
        );

        // 3. updateEntity with callback
        final stateWithCallback = stateWithUpdated.updateEntity('1', (entity) {
          if (entity is LineEntity) {
            return entity.copyWith(color: Colors.green);
          }
          return entity;
        });
        expect(stateWithCallback.entities.length, 1);
        expect(
          (stateWithCallback.entities.first as LineEntity).color,
          Colors.green,
        );

        // 4. updateEntity with non-existent ID does nothing
        final unchangedState = stateWithCallback.updateEntity('non_existent', (
          entity,
        ) {
          return (entity as LineEntity).copyWith(color: Colors.purple);
        });
        expect(unchangedState.entities.length, 1);
        expect(
          (unchangedState.entities.first as LineEntity).color,
          Colors.green,
        );
        expect(unchangedState, same(stateWithCallback));
      },
    );

    test('removeEntity handles entity removal and selectedEntityId state correctly', () {
      const entity1 = DrawingEntity.line(
        id: '1',
        p1: Offset(0, 0),
        p2: Offset(1, 1),
        color: Colors.red,
      );
      const entity2 = DrawingEntity.line(
        id: '2',
        p1: Offset(2, 2),
        p2: Offset(3, 3),
        color: Colors.blue,
      );

      // 1. Remove entity from list
      final state = const WorkspaceState(entities: [entity1, entity2]);
      final stateAfterRemoval = state.removeEntity('1');
      expect(stateAfterRemoval.entities.length, 1);
      expect(stateAfterRemoval.entities.first.id, '2');

      // 2. Clears selectedEntityId if removed entity was selected
      final selectedState = const WorkspaceState(
        entities: [entity1],
        selectedEntityId: '1',
      );
      final clearedSelectionState = selectedState.removeEntity('1');
      expect(clearedSelectionState.entities, isEmpty);
      expect(clearedSelectionState.selectedEntityId, isNull);

      // 3. Preserves selectedEntityId if another entity was selected
      final preserveState = const WorkspaceState(
        entities: [entity1, entity2],
        selectedEntityId: '2',
      );
      final preservedState = preserveState.removeEntity('1');
      expect(preservedState.entities.length, 1);
      expect(preservedState.entities.first.id, '2');
      expect(preservedState.selectedEntityId, '2');
    });
  });
}
