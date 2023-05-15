import 'tableaux.dart';

/// ranks constraints for the given tableaux using Recursive Constraint Demotion
/// sets are ranked in decreasing order - the first set is ranked highest
/// FormatException thrown if tableaux are unrankable
List<Set<Constraint>> rankOT(Tableaux tableaux) {
    // the first step in RCD is to identify all constraints that favor no losers
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
    // if all constraints are ranked, this is the base case and we are done
    if (neverLoses.containsAll(tableaux.constraints)) {
        return ranking;
    }
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