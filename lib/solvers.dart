import 'tableaux.dart';
import 'package:cassowary/cassowary.dart' as cass;

/// ranks constraints for the given tableaux using Recursive Constraint Demotion
/// sets are ranked in decreasing order - the first set is ranked highest
/// FormatException thrown if tableaux are unrankable
List<Set<Constraint>> rankOT(Tableaux tableaux) {
    /*
    RCD Pseudocode, because this is weirdly hard to find:
    if each tableau has only one candidate, you are done
    find all constraints which never prefer a loser over a winner
    if there are none, no ranking exists
    remove those constraints from consideration, and remove any candidates over which they select the winner
    note that this is different from simply not selecting the candidate, which includes ties
    run the algorithm again, on the now reduced set of constraints and candidates
    */
    // first, check if we're done, i.e. the base case
    if (![
        for (Tableau t in tableaux)
            t.candidates.length == 1
    ].contains(false)) {
        // if we already ranked all the constraints then we are done
        if (tableaux.constraints.isEmpty) {
            return [];
        }
        // if there are "leftover" constraints we just rank them at the bottom
        return [Set<Constraint>.from(tableaux.constraints)];
    }
    // the first real step in RCD is to identify all constraints that favor no losers
    Set<Constraint> neverLoses = Set<Constraint>.from(tableaux.constraints.where(
        (Constraint c) {
            for (Tableau t in tableaux) {
                for (String cand in t.candidates) {
                    // if we ever favor a loser, we don't want it
                    // favoring a loser needs STRICT INEQUALITY
                    // ties are ok here - they are resolved later
                    if (t.violations[cand]![c]! < t.violations[t.victor]![c]!) {
                        return false;
                    }
                }
            }
            return true;
        }
    ));
    // no rankable constraints is a bad thing
    if (neverLoses.isEmpty) {
        throw const FormatException('No OT ranking exists for these tableaux');
    }
    // these constraints are top ranked, so they go in our list first
    List<Set<Constraint>> ranking = [neverLoses];
    // and we need (for each tableau) to track which losers are accounted for
    Map<Tableau, Set<String>> losers = {
        for (Tableau t in tableaux)
        t: Set<String>.from(t.candidates.where(
            (String cand) {
                for (Constraint c in neverLoses) {
                    if (t.violations[cand]![c]! > t.violations[t.victor]![c]!) {
                        return true;
                    }
                }
                return false;
            }
        ))
    };
    // next, we simply make a new Tableaux and do recursion
    List<Constraint> newConstraints = [
        for (Constraint c in tableaux.constraints)
            if(!neverLoses.contains(c))
                c
    ];
    Map<Tableau, List<String>> newCandidates = {
        for (Tableau t in tableaux) t: [
            for (String c in t.candidates)
                if (!losers[t]!.contains(c))
                    c
        ]
    };
    List<Tableau> newTableaux = [
        for (Tableau t in tableaux)
            Tableau.fromFields(
                t.input,
                newConstraints,
                newCandidates[t]!,
                {
                    for (String cand in newCandidates[t]!) cand: {
                        for (Constraint c in newConstraints)
                            c: t.violations[cand]![c]!
                    }
                },
                t.victor
            )
    ];
    return ranking + rankOT(Tableaux(newConstraints, newTableaux));
}

/// finds the Constraint weights which solve a Tableaux set
Map<Constraint, num> solveHG(Tableaux tableaux) {
    cass.Solver solver = cass.Solver();
    // initialize parameters for each constraint
    Map<Constraint, cass.Param> params = {
        for (Constraint c in tableaux.constraints)
        c: cass.Param()
    };
    for (Constraint c in tableaux.constraints) {
        params[c]?.variable.name = '$c';
    }
    // Map<cass.Param, Constraint> antiParams = params.map((k, v) => MapEntry(v, k));
    // generate Cassowary Constraints for each non-victor tableau entry
    List<cass.Constraint> constraints = [];
    for (Tableau t in tableaux) {
        // store the victor terms for later
        List<cass.Term> victorTerms =
        [
            for (Constraint c in tableaux.constraints)
               cass.Term(params[c]!.variable, t.violations[t.victor]![c]!.toDouble())
        ];
        for (String cand in t.candidates) {
            if (cand == t.victor) {
                continue;
            }
            cass.EquationMember thisEquation = victorTerms.fold(cass.cm(0.0), (cass.EquationMember eq, cass.Term term) => eq+term);
            for (Constraint c in t.constraints) {
                thisEquation -= cass.cm(t.violations[cand]![c]!.toDouble()) * params[c]!;
            }
            constraints.add(thisEquation <= cass.cm(-1));
        }
    }
    solver.addConstraints(constraints);
    // ensure each weight is positive
    solver.addConstraints([
        for (Constraint c in tableaux.constraints)
            params[c]! >= cass.cm(1)
    ]);
    solver.flushUpdates();
    return {
        for (Constraint c in tableaux.constraints)
        c: params[c]!.value
    };
}