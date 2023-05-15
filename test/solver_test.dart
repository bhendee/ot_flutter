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
}