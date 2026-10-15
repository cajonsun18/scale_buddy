import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/models/entities/drawing_entity.dart';
import 'package:scale_buddy/models/workspace_state.dart';

void main() {
  group('WorkspaceState helpers', () {
    test('addOrUpdateEntity adds a new entity if it does not exist', () {
      const state = WorkspaceState();

      const newEntity = DrawingEntity.line(
        id: '1',
        p1: Offset(0, 0),
        p2: Offset(1, 1),
        color: Colors.red,
      );

      final newState = state.addOrUpdateEntity(newEntity);

      expect(newState.entities.length, 1);
      expect(newState.entities.first, newEntity);
    });

    test('addOrUpdateEntity updates an existing entity with the same id', () {
      const initialEntity = DrawingEntity.line(
        id: '1',
        p1: Offset(0, 0),
        p2: Offset(1, 1),
        color: Colors.red,
      );

      final state = const WorkspaceState(entities: [initialEntity]);

      final updatedEntity = (initialEntity as LineEntity).copyWith(
        color: Colors.blue,
      );

      final newState = state.addOrUpdateEntity(updatedEntity);

      expect(newState.entities.length, 1);
      expect((newState.entities.first as LineEntity).color, Colors.blue);
    });

    test('updateEntity modifies an existing entity based on the callback', () {
      const initialEntity = DrawingEntity.line(
        id: '1',
        p1: Offset(0, 0),
        p2: Offset(1, 1),
        color: Colors.red,
      );

      final state = const WorkspaceState(entities: [initialEntity]);

      final newState = state.updateEntity('1', (entity) {
        if (entity is LineEntity) {
          return entity.copyWith(color: Colors.green);
        }
        return entity;
      });

      expect(newState.entities.length, 1);
      expect((newState.entities.first as LineEntity).color, Colors.green);
    });

    test('updateEntity does nothing if the entity id does not exist', () {
      const initialEntity = DrawingEntity.line(
        id: '1',
        p1: Offset(0, 0),
        p2: Offset(1, 1),
        color: Colors.red,
      );

      final state = const WorkspaceState(entities: [initialEntity]);

      final newState = state.updateEntity('non_existent', (entity) {
        return (entity as LineEntity).copyWith(color: Colors.green);
      });

      // The state should be exactly the same, with no changes
      expect(newState.entities.length, 1);
      expect((newState.entities.first as LineEntity).color, Colors.red);
      expect(newState, same(state));
    });

    test('removeEntity removes the entity with the matching id', () {
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

      final state = const WorkspaceState(entities: [entity1, entity2]);
      final newState = state.removeEntity('1');

      expect(newState.entities.length, 1);
      expect(newState.entities.first.id, '2');
    });

    test(
      'removeEntity clears selectedEntityId if the removed entity was selected',
      () {
        const entity1 = DrawingEntity.line(
          id: '1',
          p1: Offset(0, 0),
          p2: Offset(1, 1),
          color: Colors.red,
        );

        final state = const WorkspaceState(
          entities: [entity1],
          selectedEntityId: '1',
        );
        final newState = state.removeEntity('1');

        expect(newState.entities, isEmpty);
        expect(newState.selectedEntityId, isNull);
      },
    );

    test(
      'removeEntity preserves selectedEntityId if another entity was selected',
      () {
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

        final state = const WorkspaceState(
          entities: [entity1, entity2],
          selectedEntityId: '2',
        );
        final newState = state.removeEntity('1');

        expect(newState.entities.length, 1);
        expect(newState.entities.first.id, '2');
        expect(newState.selectedEntityId, '2');
      },
    );
  });
}
