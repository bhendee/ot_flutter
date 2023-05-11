import 'dart:math';

class Tableaux extends Iterable<Tableau>{
    late final List<Constraint> constraints;
    late final List<Tableau> tableaux;

    @override
    Iterator<Tableau> get iterator => tableaux.iterator;
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
            output += '$t\n';
        }
        return output;
    }

    /// generates Tableaux from Editable rows and columns
    Tableaux.fromEditables(List<Map<String, List<dynamic>?>> states) {
        Set<Constraint> workingConstraints = {};
        List<Tableau> workingTableaux = [];
        // the first step is to identify all necessary constraints
        // look through each state
        for (Map<String, List<dynamic>?> state in states) {
            // we should always have a list of column information
            if (state['cols'] is List<Map<String, dynamic>>) {
                List<Map<String, dynamic>> cols = state['cols']! as List<Map<String, dynamic>>;
                for (Map<String, dynamic> col in cols) {
                    if (col['key'] != 'cand') {
                        workingConstraints.add(Constraint(col['title']));
                    }
                }
            }
        }
        constraints = [for (Constraint c in workingConstraints) c];
        // next we need to build the tableaux
        // first we need to replace any rows with their edited counterpart
        for (Map<String, List<dynamic>?> state in states) {
            List<dynamic>? edits = state['edits'];
            if (edits != null) {
                for (Map<dynamic, dynamic> edit in edits) {
                    int rowNum = edit['row'];
                    if (state['rows'] is List<Map<String, dynamic>>) {
                        Map<String, dynamic> row = state['rows']![rowNum];
                        for (String key in edit.keys) {
                            if (key != 'row') {
                                row[key] = edit[key];
                            }
                        }
                    }
                }
            }
        }
        for (Map<String, List<dynamic>?> state in states) {
            if (state['rows'] is List<Map<String, dynamic>>) {
                List<Map<String, dynamic>> rows = state['rows']! as List<Map<String, dynamic>>;
                String? victor;
                List<String> candidates = [];
                List<List<int>> violations = [];
                String? input;
                // input will be in the "candidate" column title
                if (state['cols'] is List<Map<String, dynamic>>) {
                    List<Map<String, dynamic>> cols = state['cols'] as List<Map<String, dynamic>>;
                    for (Map<String, dynamic> col in cols) {
                        if (col['key'] == 'cand') {
                            input = col['title'].substring('Input: '.length);
                        }
                    }
                }
                // everything else is in the rows
                for (Map<String, dynamic> row in rows) {
                    String cand = row['cand'];
                    List<int> rowViolations = [];
                    // a little bit of janky code to demanicule the victor
                    if (cand.startsWith('☞ ')) {
                        cand = cand.substring(2);
                        if (victor != null) {
                            throw const FormatException('Multiple victors in input');
                        }
                        victor = cand;
                    }
                    candidates.add(cand);
                    for (Constraint c in constraints) {
                        rowViolations.add(int.parse(row['$c'].toString()));
                    }
                    violations.add(rowViolations);
                }
                workingTableaux.add(Tableau(input!, constraints, candidates, violations, victor!));
            }
        }
        tableaux = workingTableaux;
    }

    /// creates Tableaux based off an OTHelp-style list
    /// there is currently no format checking and any malformed lists are undefined behavior
    Tableaux.fromOTHelpList(List<List<String>> othelp) {
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
            workingTableaux.add(Tableau(input, [for (Constraint c in constraints) c], candidates, violations, victor));
        }
        tableaux = workingTableaux;
    }

    /// converts the Tableaux into an OTHelp-style list
    List<List<String>> toOTHelpList() {
        List<List<String>> othelp = [];
        // first three columns of first row should be blank
        othelp.add(['', '', '']);
        // then we add the constraint long names (only for backwards-compatibility)
        // ot_flutter has no direct long name support
        othelp[0] += [for (Constraint c in constraints) c.longName];
        // similar process for second row
        othelp.add(['', '', '']);
        othelp[1] += [for (Constraint c in constraints) c.shortName];
        // and then we do each tableau one-by-one
        for (Tableau t in this) {
            // go row-by-row
            for (int i = 0; i < t.candidates.length; i++) {
                List<String> currentRow = [];
                if (i == 0) {
                    currentRow.add(t.input);
                } else {
                    currentRow.add('');
                }
                currentRow.add(t.candidates[i]);
                if(t.candidates[i] == t.victor) {
                    currentRow.add('1');
                } else {
                    currentRow.add('');
                }
                // add violations
                for (Constraint c in constraints) {
                    currentRow.add('${t.violations[t.candidates[i]]?[c]}');
                }
                // add row to full list
                othelp.add(currentRow);
            }
        }
        return othelp;
    }
}

class Constraint {
    /// there is no real support for long names
    final String longName;
    final String shortName;

    Constraint(this.shortName, {this.longName = ''});

    @override
    String toString() {
        return shortName;
    }

    @override
    bool operator==(Object other) {
        if (other is Constraint) {
            return other.shortName == shortName;
        }
        return false;
    }

    @override
    int get hashCode => shortName.hashCode;

    static List<Constraint> fromStrings(Iterable<String> constraints) {
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

    /// formats the Tableaux as lists which can generate an Editable table
    /// key 'rows' and 'cols' for rows and columns respectively
    Map<String, List<Map<String, dynamic>>> toEditableLists() {
        // populate columns with correct data
        List<Map<String, dynamic>> cols = [];
        cols.add({'title':'Input: $input', 'widthFactor':0.1, 'key':'cand'});
        cols += [for (Constraint c in constraints)
            {'title':'$c', 'widthFactor':0.05, 'key':'$c'},
        ];
        List<Map<String, dynamic>> rows = [];
        // populate rows with candidates and violations
        for(String c in candidates) {
            String cFormat = c;
            if(c == victor) {
                cFormat = '☞ $c';
            }
            Map<String, dynamic> row = {'cand': cFormat};
            for (Constraint con in constraints) {
                row['$con'] = violations[c]?[con];
            }
            rows.add(row);
        }
        return {'cols':cols, 'rows':rows};
    }
}