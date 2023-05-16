import 'package:ot_flutter/solvers.dart';
import 'package:ot_flutter/tableaux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
    test('rankOT properly ranks two constraints', () {
        List<Constraint> constraints = Constraint.fromStrings(['A', 'B']);
        Tableaux tableaux = Tableaux(
            constraints,
            [
                Tableau('a', constraints, ['aa', 'bb'], [[1, 0], [0, 1]], 'aa'),
                Tableau('b', constraints, ['aa', 'bb'], [[1, 0], [0, 0]], 'bb'),
            ]
        );
        expect(rankOT(tableaux), equals([{const Constraint('B')}, {const Constraint('A')}]));
    });

    test('rankOT properly ranks three constraints', () {
        List<Constraint> constraints = Constraint.fromStrings(['A', 'B', 'C']);
        Tableaux tableaux = Tableaux(
            constraints,
            [
                Tableau('a', constraints, ['aa', 'bb'], [[1, 0, 0], [0, 1, 0]], 'aa'),
                Tableau('b', constraints, ['aa', 'bb'], [[1, 0, 1], [0, 0, 0]], 'bb'),
            ]
        );
        expect(rankOT(tableaux), equals([{const Constraint('B'), const Constraint('C')}, {const Constraint('A')}]));
    });
    test('rankOT throws when no ranking exits', () {
        List<Constraint> constraints = Constraint.fromStrings(['A', 'B']);
        Tableaux tableaux = Tableaux(
            constraints,
            [
                Tableau('a', constraints, ['aa', 'bb'], [[1, 0], [0, 0]], 'aa'),
                Tableau('b', constraints, ['aa', 'bb'], [[1, 0], [0, 0]], 'bb'),
            ]
        );
        expect(() => rankOT(tableaux), throwsFormatException);
    });
    test('solveHG solves for constraint weights', () {
        List<Constraint> constraints = Constraint.fromStrings(['A', 'B']);
        Tableaux tableaux = Tableaux(
            constraints,
            [
                Tableau('a', constraints, ['aa', 'bb'], [[1, 0], [0, 1]], 'aa'),
                Tableau('b', constraints, ['aa', 'bb'], [[1, 0], [0, 0]], 'bb'),
            ]
        );
        print(solveHG(tableaux));
    });
}