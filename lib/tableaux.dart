import 'dart:math';
import 'package:flutter/material.dart';

class Tableaux {
    late final List<Constraint> constraints;
    late final List<Tableau> tableaux;

    /// generates a set of Tableaux from the list of constraints and tableaux, which must match the given constraints
    Tableaux(this.constraints, this.tableaux) {
        // verify that all constraints are present
        for(var t in tableaux) {
            for(Constraint constraint in t.constraints) {
                if(!constraints.contains(constraint)) {
                    throw const FormatException('One or more constraints are present in tableaux but not given');
                }
            }
            for(Constraint constraint in constraints) {
                if(!t.constraints.contains(constraint)) {
                    throw const FormatException('One or more constraints are not specified for all input tableaux');
                }
            }
        }
    }

    @override
    String toString() {
        String output = '';
        for(Tableau t in tableaux) {
            output += '${t}\n';
        }
        return output;
    }

    /// formats the tableaux as a list of lists of TableRows, which can generate Flutter tables
    List<List<TableRow>> toTablesRows() {
        return [for (Tableau t in tableaux) t.toTableRows()];
    }

    /// creates a Tableaux based off an OTHelp-style list
    /// there is currently no format checking and any malformed lists are undefined behavior
    Tableaux.fromList(List<List<String>> othelp) {
        // initialize constraints
        List<Constraint> workingConstraints = [];
        // the first two rows of our input contain constraints, from the 4th column on
        for (int c = 3; c < othelp[0].length; c++) {
            workingConstraints.add(Constraint(othelp[1][c], longName: othelp[0][c]));
        }
        constraints = workingConstraints;
        // initialize tableaux
        List<Tableau> workingTableaux = [];
        // the rest of the rows contain tableau information
        // the first step is to locate the tableaux
        List<int> tableaucations = [2];
        for (int r = 3; r < othelp.length; r++) {
            if (othelp[r][0] != '') {
                tableaucations.add(r);
            }
        }
        // add the end of the tableaux for eas of use
        tableaucations.add(othelp.length);
        // begin pulling data out of the tableaux
        // iterating tableau by tableau
        for (int i = 0; i < tableaucations.length - 1; i++) {
            // the 0th column of the 0th row of each tableau is input
            String input = othelp[tableaucations[i]][0];
            String victor = '';
            List<String> candidates = [];
            List<List<int>> violations = [];
            // iterating rows within each tableau
            for(int r = tableaucations[i]; r < tableaucations[i+1]; r++) {
                candidates.add(othelp[r][1]);
                if (othelp[r][2] != '') {
                    victor = othelp[r][1];
                }
                // iterate through each constraint to grab violations
                List<int> candidateViolations = [];
                for (int c = 3; c < othelp[0].length; c++) {
                    if (othelp[r][c] != '') {
                        candidateViolations.add(int.parse(othelp[r][c]));
                    } else {
                        candidateViolations.add(0);
                    }
                }
                violations.add(candidateViolations);
            }
            // turn the collected data into a tableau
            workingTableaux.add(Tableau(input, constraints, candidates, violations, victor));
        }
        tableaux = workingTableaux;
    }
}

class Constraint {
    final String longName;
    final String shortName;

    Constraint(this.shortName, {this.longName = ''});

    @override
    String toString() {
        return shortName;
    }

    static List<Constraint> fromStrings(List<String> constraints) {
        return [for (String s in constraints) Constraint(s)];
    }
}

class Tableau {
    final String input ;
    final List<Constraint> constraints ;
    final List<String> candidates;
    Map<String, Map<Constraint, int>> violations = {};
    final String victor;

    /// generates an unsolved Tableau for the given input, setting the victor to the supplied victor.
    Tableau(this.input, this.constraints, this.candidates, List<List<int>> violations, this.victor) {
        this.violations = {for (var i = 0; i < candidates.length; i++) candidates[i]: {for (var j = 0; j < constraints.length; j++) constraints[j]: violations[i][j]}};
        // verify that the victor is a valid candidate
        if(!candidates.contains(victor)) {
            throw const FormatException('Victor not found in candidate list');
        }
    }

    @override
    String toString() {
        // this makes janky ascii art of a tableau for testing
        String output = ' ' * ([for (String c in candidates) c.length].reduce(max) + 2);
        for(Constraint c in constraints) {
            output += '$c, ';
        }
        output += '\n';
        for(String candidate in candidates) {
            if(candidate == victor) {
                output += '☞ ';
            }
            else {
                output += '  ';
            }
            output += candidate;
            for(Constraint constraint in constraints) {
                output += ', ${(violations[candidate]?[constraint]).toString().padLeft(constraint.toString().length - 2, ' ')}';
            }
            output += '\n';
        }
        return output;
    }

    /// formats the Tableaux as a list of Flutter table rows, which can generate a table
    List<TableRow> toTableRows() {
        List<TableRow> rows = [];
        // the first row should be the input followed by a list of constraints
        List<TableCell> firstRow = [TableCell(child:Text('Input: $input'))];
        firstRow += [for (Constraint c in constraints) TableCell(child:Text(c.toString(), textAlign:TextAlign.right))];
        rows.add(TableRow(children:firstRow));
        // all other rows are a candidate followed by violations
        for(String c in candidates) {
            String cFormat = c;
            if(c == victor) {
                cFormat = '☞ $c';
            }
            List<TableCell> row = [TableCell(child:Text(cFormat, textAlign:TextAlign.right))];
            row += [for (Constraint con in constraints)
                TableCell(child:Text('*' * violations[c]![con]!, textAlign:TextAlign.right))
            ];
            rows.add(TableRow(children:row));
        }
        return rows;
    }
}

void main() {
    List<Constraint> constraints = Constraint.fromStrings(['*IVS', 'I[V]']);
    Tableau t = Tableau('/ada/', constraints, ['ada', 'ata'], [[1, 0], [0, 1]], 'ata');
    Tableau s = Tableau('/ata/', constraints, ['ada', 'ata'], [[1, 1], [0, 0]], 'ata');

    Tableaux tableaux = Tableaux(t.constraints, [s, t]);

    print(tableaux);
}