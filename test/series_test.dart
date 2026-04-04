import 'package:flutter_test/flutter_test.dart';
import 'package:jkd_app/models/series.dart';
import 'package:jkd_app/models/move.dart';

void main() {
  group('JkdSeries Editing Tests', () {
    test('Should correctly edit a series title using copyWith', () {
      final series = JkdSeries(
        id: 1,
        title: 'Original Title',
        notes: 'Original Notes',
      );

      final editedSeries = series.copyWith(title: 'Edited Title');

      expect(editedSeries.id, 1);
      expect(editedSeries.title, 'Edited Title');
      expect(editedSeries.notes, 'Original Notes');
    });

    test(
      'Should handle complex nested move structures (Edit Mode scenarios)',
      () {
        // Create a complex move: (A + B) -> C with Answer (D + E)
        final moveA = Move(name: 'Jab', category: 'punch');
        final moveB = Move(name: 'Cross', category: 'punch');
        final simultaneousAttack = Move(
          name: 'Jab + Cross',
          category: 'simultaneous',
          subMoves: [moveA, moveB],
        );

        final moveC = Move(name: 'Hook', category: 'punch');

        // Answer D + E
        final moveD = Move(name: 'Parry', category: 'defense');
        final moveE = Move(name: 'Counter', category: 'punch');

        final complexMove = Move(
          name: '(Jab + Cross) -> Hook',
          category: 'chain',
          chain: [simultaneousAttack, moveC],
          counterName: 'Parry + Counter',
          counterCategory: 'simultaneous',
          counterSubMoves: [moveD, moveE],
        );

        final series = JkdSeries(
          id: 1,
          title: 'Advanced',
          moves: [complexMove],
        );

        // Verify structure
        expect(series.moves[0].category, 'chain');
        expect(series.moves[0].chain.length, 2);
        expect(series.moves[0].chain[0].category, 'simultaneous');
        expect(series.moves[0].chain[0].subMoves.length, 2);
        expect(series.moves[0].hasCounter, true);
        expect(series.moves[0].counterSubMoves.length, 2);

        // Edit a nested move (Change 'Jab' to 'Lead Jab' inside the simultaneous group inside the chain)
        final editedMoveA = moveA.copyWith(name: 'Lead Jab');
        final editedSimultaneous = simultaneousAttack.copyWith(
          subMoves: [editedMoveA, moveB],
        );
        final editedComplexMove = complexMove.copyWith(
          chain: [editedSimultaneous, moveC],
        );

        final editedSeries = series.copyWith(moves: [editedComplexMove]);

        expect(editedSeries.moves[0].chain[0].subMoves[0].name, 'Lead Jab');
        expect(
          editedSeries.moves[0].chain[1].name,
          'Hook',
        ); // Should preserve others
      },
    );

    test('Should correctly edit series moves', () {
      final move1 = Move(name: 'Punch', category: 'punch');
      final move2 = Move(name: 'Kick', category: 'kick');
      final series = JkdSeries(id: 1, title: 'Training', moves: [move1, move2]);

      // Edit the first move
      final editedMove1 = move1.copyWith(name: 'Lead Punch', side: 'Lead');

      // Create new moves list
      final newMoves = [editedMove1, move2];

      final editedSeries = series.copyWith(moves: newMoves);

      expect(editedSeries.moves.length, 2);
      expect(editedSeries.moves[0].name, 'Lead Punch');
      expect(editedSeries.moves[0].side, 'Lead');
      expect(editedSeries.moves[1].name, 'Kick');
    });

    test('Should correctly change series category and type', () {
      final series = JkdSeries(
        title: 'Basic',
        category: 'Jun Fan Gung Fu',
        type: 'Attack',
      );

      final editedSeries = series.copyWith(category: 'JKD', type: 'Defense');

      expect(editedSeries.category, 'JKD');
      expect(editedSeries.type, 'Defense');
    });

    test('Should correctly toggle isSystem', () {
      final series = JkdSeries(title: 'System Series', isSystem: true);
      final editedSeries = series.copyWith(isSystem: false);

      expect(series.isSystem, true);
      expect(editedSeries.isSystem, false);
    });
  });
}
