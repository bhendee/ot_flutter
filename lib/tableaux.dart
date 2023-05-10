import 'package:csv/csv.dart';

class Tableau {
    final String input ;
    final List<String> constraints ;
    final List<String> candidates;
    Map<String, Map<String, int>> violations = {};
    final String victor;

    Tableau(this.input, this.constraints, this.candidates, List<List<int>> violations, this.victor) {
        this.violations = {for (var i = 0; i < candidates.length; i++) candidates[i]: {for (var j = 0; j < constraints.length; j++) constraints[j]: violations[i][j]}};
    }

    String toString() {
        return [input, violations, victor].toString();
    }
}

void main() {
    Tableau t = Tableau('/ada/', ['*IVS', 'I[V]'], ['ada', 'ata'], [[1, 0], [0, 1]], 'ata');
    print(t);
}