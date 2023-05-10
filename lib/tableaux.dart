import 'package:csv/csv.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class Tableaux {
    final List<Constraint> constraints;
    final List<Tableau> tableaux;

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
        firstRow += [for (Constraint c in constraints) TableCell(child:Text(c.toString()))];
        rows.add(TableRow(children:firstRow));
        // all other rows are a candidate followed by violations
        for(String c in candidates) {
            String cFormat = c;
            if(c == victor) {
                cFormat = '☞ $c';
            }
            List<TableCell> row = [TableCell(child:Text(cFormat))];
            row += [for (Constraint con in constraints)
                TableCell(child:Text(violations[c]![con].toString()))
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