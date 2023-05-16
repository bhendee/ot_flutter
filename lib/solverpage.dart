import 'package:flutter/material.dart';
import 'tableaux.dart';
import 'solvers.dart';

class SolverPage extends StatefulWidget {
    final Tableaux tableaux;
    final String title;

    const SolverPage({super.key, required this.title, required this.tableaux});

    @override
    State<SolverPage> createState() => _SolverPageState();
}

class _SolverPageState extends State<SolverPage> {
    late Tableaux tableaux = widget.tableaux;

    List<TableRow> generateOTTableRows(List<Set<Constraint>> ranking, Tableau t) {
        // turn ranking into lists of strings, with proper formatting
        List<String> formattedRanks = [];
        for (int i = 0; i < ranking.length; i++) {
            List<Constraint> rank = List<Constraint>.from(ranking[i]);
            if(i == 0) {
                formattedRanks.addAll(rank.map((Constraint c) => '$c'));
            } else {
                for (int j = 0; j < rank.length; j++) {
                    if (j == 0) {
                        formattedRanks.add('>> ${rank[0]}');
                    } else {
                        formattedRanks.add(rank[j].toString());
                    }
                }
            }
        }
        return [
            // input and constraint row
            TableRow(children:[
                TableCell(child:Text(t.input)),
                ...formattedRanks.map((String s) => TableCell(child: Text(s)))
            ]),
            // normal rows
            ...[
                for (String cand in t.candidates)
                TableRow(children:[
                    TableCell(child: Text((cand == t.victor ? '☞ ' : '') + cand)),
                    ...[
                        for (Set<Constraint> rank in ranking)
                            for (Constraint c in rank)
                                TableCell(child: Text('*' * t.violations[cand]![c]!))
                    ]
                ])
            ]
        ];
    }

    @override
    Widget build(BuildContext context) {
        late List<Set<Constraint>> otRanking;
        late bool rankingExists;
        try {
            otRanking = rankOT(tableaux);
            rankingExists = true;
        } on FormatException {
            rankingExists = false;
        }
        return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: ListView(
                padding: const EdgeInsets.all(8.0),
                children: <Widget>[
                    if (rankingExists)
                        ...[
                            for (Tableau t in tableaux)
                            Padding(padding: const EdgeInsets.all(8.0), child:Table(
                                border: TableBorder.all(color: Colors.grey),
                                children: generateOTTableRows(otRanking, t)
                            ))
                        ]
                    else
                        const Text('No OT ranking exists for the provided Tableaux')
                ]
            )
        );
    }
}