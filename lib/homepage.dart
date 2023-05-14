import 'package:flutter/material.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
    final String title;
    const HomePage({super.key, required this.title});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(title),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) {return const TableauPage(title: 'Tableaux Editor');}));},
                    ),
                    IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: () {},
                    )
                ]
            ),
            body: Center(
                child:Wrap(
                    direction: Axis.horizontal,
                    children: const [Text('Welcome to OT Flutter (Working Name). OT Flutter can help you create and edit Tableaux for use in OTHelp. To get started, press the pencil in the top right corner')],
                )
            ),
        );
    }
}