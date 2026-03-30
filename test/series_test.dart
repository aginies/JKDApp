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

    test('Should correctly edit series moves', () {
      final move1 = Move(name: 'Punch', category: 'punch');
      final move2 = Move(name: 'Kick', category: 'kick');
      final series = JkdSeries(
        id: 1,
        title: 'Training',
        moves: [move1, move2],
      );

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

      final editedSeries = series.copyWith(
        category: 'JKD',
        type: 'Defense',
      );

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
